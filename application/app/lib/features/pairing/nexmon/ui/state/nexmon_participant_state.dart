import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:messagepack/messagepack.dart';
import 'package:pairfi/features/pairing/audio/services/wifi_p2p_service.dart';
import 'package:pairfi/features/pairing/audio/wifip2p_communication.dart';
import 'package:pairfi/features/pairing/nexmon/models/nexmon_models.dart';
import 'package:pairfi/features/pairing/nexmon/models/nexmon_pairing_settings.dart';
import 'package:pairfi/features/pairing/nexmon/services/nexmon_udp_channel_service.dart';
import 'package:pairfi/features/pairing/nexmon/ui/state/nexmon_coordinator_state.dart';
import 'package:pairfi/features/pairing/nexmon/ui/state/nexmon_state_helper.dart';
import 'package:pairfi/features/pairing/success_list_data.dart';
import 'package:pairfi/helper_functions.dart';
import 'package:pairfi/service_locator.dart';

class NexmonParticipantState extends ChangeNotifier {
  NexmonParticipantProtocolStage protocolStage = NexmonParticipantProtocolStage.magicNumberSelection;

  int? numParticipants;
  int? magicVerificationNumber;

  final NexmonPairingSettings _settings;
  final WifiP2pService _wifiP2pService;
  NexmonUDPChannelService _nexmonService;
  Socket? _wifiP2PSocket;
  StreamSubscription<Uint8List>? _socketStream;

  final NexmonStateHelper _helper;
  SuccessListData? successListData;

  final Queue<Uint8List> _wifiMessages = Queue();
  Timer? _messageProcessTimer;
  final Stopwatch _timeoutStopwatch = Stopwatch();

  String get errorMessage => _helper.errorMessage ?? "";

  NexmonParticipantState({settings = NexmonPairingSettings.standard})
      : _settings = settings,
        _helper = NexmonStateHelper(settings: settings),
        _wifiP2pService = getIt<WifiP2pService>(),
        _nexmonService = NexmonUDPChannelService.createServiceWithSettings(getIt()) {
    this.addListener(_handleStageTransition);
  }

  Future<void> _handleStageTransition() async {
    switch (protocolStage) {
      case NexmonParticipantProtocolStage.waitingForWifiP2PConnection:
        //await _initWifiP2P();
        await _waitForWifiP2PConnection();
      case NexmonParticipantProtocolStage.commitments:
        await _sendCommitment();
      case NexmonParticipantProtocolStage.verification:
        try {
          await _runVerification();
        } on NexmonSecurityException {
          _sendWrongReveal();
          _transitionToStage(NexmonParticipantProtocolStage.securityError);
        }
      case NexmonParticipantProtocolStage.mainReveals:
        await _sendMainReveal();
      case NexmonParticipantProtocolStage.matchReveals:
        await _sendMatchReveal();
      case NexmonParticipantProtocolStage.decryption:
        await _checkDHStart();
      case NexmonParticipantProtocolStage.timeout:
      case NexmonParticipantProtocolStage.error:
      case NexmonParticipantProtocolStage.securityError:
      case NexmonParticipantProtocolStage.done:
        _messageProcessTimer?.cancel();
        _timeoutStopwatch.stop();
        _timeoutStopwatch.reset();
        break;
      default:
        break;
    }
  }

  Future<void> _processWifiMessage(Uint8List data) async {
    debugPrint("[Participant ($protocolStage)] Start Processing data: ${data.toHexString()}");
    final messages = await _helper.tryParseAndVerifyData(data);
    if (messages.isEmpty) {
      debugPrint("Rejecting data ${data.toHexString()}");
      return;
    }

    if (protocolStage == NexmonParticipantProtocolStage.waitingForOthers) {
      if (messages.any((msg) => msg.type == NexmonMessageType.ready)) {
        _transitionToStage(NexmonParticipantProtocolStage.commitments);
      }
    }
  }

  Future<void> _checkStageTransitions() async {
    if (protocolStage == NexmonParticipantProtocolStage.commitments) {
      if (_helper.receivedCommitments.length == (numParticipants ?? 0) - 1) {
        _transitionToStage(NexmonParticipantProtocolStage.mainReveals);
      }
    } else if (protocolStage == NexmonParticipantProtocolStage.mainReveals) {
      if (_helper.receivedMainReveals.length == (numParticipants ?? 0) - 1) {
        _transitionToStage(NexmonParticipantProtocolStage.verification);
      }
    } else if (protocolStage == NexmonParticipantProtocolStage.verification) {
      //
    } else if (protocolStage == NexmonParticipantProtocolStage.userConfirm) {
      if (_helper.userVerification != null) {
        if (_helper.userVerification == true) {
          _transitionToStage(NexmonParticipantProtocolStage.matchReveals);
        } else {
          throw NexmonSecurityException();
        }
      }
    } else if (protocolStage == NexmonParticipantProtocolStage.matchReveals) {
      if (_helper.receivedMatchReveals.length == (numParticipants ?? 0) - 1) {
        _transitionToStage(NexmonParticipantProtocolStage.decryption);
      }
    } else if (protocolStage == NexmonParticipantProtocolStage.decryption) {
      if (_helper.secretSharingPackets.isEmpty) {
        return;
      }
      final receivedPacket = _helper.secretSharingPackets.removeFirst();
      debugPrint("Received secret sharing packet; uid = ${receivedPacket.dhUid}");
      _helper.encryptedSecrets[receivedPacket.secretUid] = receivedPacket.encryptedSecret;
      if (receivedPacket.dhUid == _helper.myUid) {
        final packet = await _helper.performDH(_helper.myUid, receivedPacket.dhPublicKey);
        _wifiP2PSocket?.add(packet.serialize());
      } else if (receivedPacket.dhUid == -1) {
        final users = _helper.decryptAllUserData();
        successListData = SuccessListData(users, _helper.myUid);
        _transitionToStage(NexmonParticipantProtocolStage.done);
      }
    }
  }

  void _checkTimeouts() {
    switch (protocolStage) {
      case NexmonParticipantProtocolStage.waitingForWifiP2PConnection:
        if (_timeoutStopwatch.elapsedMilliseconds > _settings.connectionTimeoutMs) {
          _transitionToStage(NexmonParticipantProtocolStage.waitingForWifiP2PConnection);
        }
      case NexmonParticipantProtocolStage.waitingForOthers:
        if (_timeoutStopwatch.elapsedMilliseconds > _settings.connectionTimeoutMs) {
          _transitionToStage(NexmonParticipantProtocolStage.timeout);
        }
      case NexmonParticipantProtocolStage.decryption:
      case NexmonParticipantProtocolStage.matchReveals:
      case NexmonParticipantProtocolStage.verification:
      case NexmonParticipantProtocolStage.mainReveals:
      case NexmonParticipantProtocolStage.commitments:
        if (_timeoutStopwatch.elapsedMilliseconds > _settings.protocolStageTimeoutMs) {
          _transitionToStage(NexmonParticipantProtocolStage.timeout);
        }
      default:
        break;
    }
  }

  Future<void> _enqueueWifiData(Uint8List data) async {
    debugPrint("[Participant (stage: $protocolStage)] Received ${data.toHexString()}");
    _wifiMessages.addLast(data);
  }

  Future<void> startPairing(int digit) async {
    // Re-create Nexmon service since settings might have changed (constructor does only get called once due to caching)
    _nexmonService = NexmonUDPChannelService.createServiceWithSettings(getIt());

    _messageProcessTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      try {
        if (_wifiMessages.isNotEmpty) {
          final data = _wifiMessages.removeFirst();
          await _processWifiMessage(data);
        }
        await _checkStageTransitions();
        _checkTimeouts();
      } on NexmonSecurityException {
        _sendWrongReveal();
        _transitionToStage(NexmonParticipantProtocolStage.securityError);
      } catch (e) {
        _helper.errorMessage = e.toString();
        _transitionToStage(NexmonParticipantProtocolStage.error);
      }
    });

    _timeoutStopwatch.start();
    await _initWifiP2P();
    _transitionToStage(NexmonParticipantProtocolStage.waitingForWifiP2PConnection);
  }

  Future<void> _initWifiP2P() async {
    await _wifiP2pService.init();
    if (!await _wifiP2pService.waitForAvailable()) {
      debugPrint("[NexmonParticipantState] No Wifi P2P available");
      throw WifiP2pUnavailableException();
    }

    /* we need this to create a "local" P2P interface s.t. we can talk via UDP with the chip internal firmware */
    String ssidRandom = "DIRECT-${bytesToHex(randomBytes(3))}";
    String passphraseRandom = bytesToHex(randomBytes(6));
    await _wifiP2pService.createGroupWithConfig(ssidRandom, passphraseRandom, 2467, null);
    final groupInfo = await _wifiP2pService.waitForGroupInfo();
    if (groupInfo == null) {
      debugPrint("[NexmonParticipantState] Wifi P2P no group available");
      throw WifiP2pUnavailableException();
    }
    //debugPrint("[NexmonParticipantState] WifiP2P Group info: {SSID: ${groupInfo.ssid}, passphrase: ${groupInfo.passphrase}}");
  }

  Future<void> _waitForWifiP2PConnection() async {
    await _nexmonService.startReceiving(onData: (data) async {
      final wifiP2pGroupInfo = _tryParseGroupInfo(data);
      if (wifiP2pGroupInfo != null) {

        // remove our own P2P s.t. we can connect to the group P2P
        await _wifiP2pService.removeGroup();

        if (!await _wifiP2pService.waitForAvailable()) {
          debugPrint("[NexmonParticipantState] No Wifi P2P available");
          throw WifiP2pUnavailableException();
        }

        await _wifiP2pService.connect(wifiP2pGroupInfo);
        final connectionInfo = await _wifiP2pService.waitForConnectionInfo();
        if (connectionInfo == null) {
          _helper.errorMessage = "Could not get connection info";
          _transitionToStage(NexmonParticipantProtocolStage.error);
          return;
        }
        //debugPrint("[NexmonParticipantState] connectionInfo $connectionInfo");

        _wifiP2PSocket = await _tryCreateSocket(connectionInfo, attempts: 10);
        if (_wifiP2PSocket == null) {
          _helper.errorMessage = "Could not create socket";
          _transitionToStage(NexmonParticipantProtocolStage.error);
          return;
        }

        _socketStream = _wifiP2PSocket?.listen(_enqueueWifiData, onDone: () {
          _socketStream?.cancel();
          _wifiP2PSocket?.flush();
          _wifiP2PSocket?.close();
          _wifiP2PSocket = null;
        }, onError: (error) {
          _socketStream?.cancel();
          _wifiP2PSocket?.flush();
          // no need to close socket, it's already closed
          _wifiP2PSocket = null;
        });

        _transitionToStage(NexmonParticipantProtocolStage.waitingForOthers);
      }
    });
  }

  Future<void> _runVerification() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _nexmonService.startReceiving(onData: (data) async {
      Uint8List localVerificationCode = _helper.getVerificationCode();
      if (data.isEmpty) {
        debugPrint("[NexmonParticipantState] Empty verification code.");
        throw NexmonSecurityException();
      } else if ((data.length-1) != _settings.verificationCodeLength) {
        debugPrint("[NexmonParticipantState] Verification code length mismatch ${data.length} instead of ${_settings.verificationCodeLength}.");
        debugPrint("[NexmonParticipantState] rx: $data.");
        debugPrint("[NexmonParticipantState] local: $localVerificationCode.");
        throw NexmonSecurityException();
      } else {
        var i = magicVerificationNumber = data[0];
        if (i < 0 || i > 8) {
          debugPrint("[NexmonParticipantState] Verification random number out of bounds.");
          throw NexmonSecurityException();
        }
        Uint8List verificationCode = data.sublist(1);
        if (listEquals(localVerificationCode, verificationCode)) {
          debugPrint("[NexmonParticipantState] Verification code match.");
          _transitionToStage(NexmonParticipantProtocolStage.userConfirm);
        } else {
          debugPrint("[NexmonParticipantState] Verification code mismatch: rx $verificationCode / local $localVerificationCode.");
          throw NexmonSecurityException();
        }
      }
    });
  }

  Future<void> _sendCommitment() async {
    _wifiP2PSocket?.add(_helper.commitment.getMainCommitment().serialize());
  }

  Future<void> _sendMainReveal() async {
    _wifiP2PSocket?.add(_helper.commitment.getMainReveal().serialize());
  }

  Future<void> _sendMatchReveal() async {
    _wifiP2PSocket?.add(_helper.commitment.getMatchReveal().serialize());
  }

  Future<void> _sendWrongReveal() async {
    _wifiP2PSocket?.add(_helper.commitment.getWrongReveal().serialize());
  }

  Future<void> _checkDHStart() async {
    debugPrint("My DH index is ${_helper.myDHIndex}; sharedGroupKey == ${_helper.sharedGroupKey}");
    if (_helper.myDHIndex == 0 && _helper.sharedGroupKey == null) { // sharedGroupKey is null if DH has not been performed yet
      final secondParticipant = _helper.sortedReveals[1];
      final packet = await _helper.performDH(_helper.myUid, secondParticipant.value.dhPublicKey);
      _wifiP2PSocket?.add(packet.serialize());
    }
  }

  Future<void> handleUserConfirmation(bool confirm) async {
    _helper.userVerification = confirm;
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await reset();
  }

  Future<void> reset() async {
    _messageProcessTimer?.cancel();
    _timeoutStopwatch.stop();
    _timeoutStopwatch.reset();
    protocolStage = NexmonParticipantProtocolStage.magicNumberSelection;
    await _nexmonService.dispose();
    await _wifiP2pService.disconnect();
    await _wifiP2pService.removeGroup();
    await _socketStream?.cancel();
    await _wifiP2PSocket?.flush();
    await _wifiP2PSocket?.close();
    _helper.reset();
    numParticipants = null;
    magicVerificationNumber = null;
    debugPrint("[Participant] Reset done");
  }

  WifiP2pGroupInfo? _tryParseGroupInfo(Uint8List data) {
    final unpacker = Unpacker(data);
    final numParticipants = unpacker.unpackInt();
    final ssid = unpacker.unpackString();
    final passphrase = unpacker.unpackString();

    if (ssid != null && passphrase != null) {
      //debugPrint("[Participant] Got P2P data: SSID: $ssid, passphrase: $passphrase, participants: $numParticipants");
      this.numParticipants = numParticipants;
      return WifiP2pGroupInfo(ssid: ssid, passphrase: passphrase);
    }

    return null;
  }

  /// Tries to create a socket connected to the [connectionInfo] address and port.
  /// If the creation fails, it is retried for [attempts] times, each with a delay
  /// of [delayMs] milliseconds.
  ///
  /// This function was necessary, since very slow devices (like LG Nexus 5)
  /// did not connect to the WiFi network in time before the socket was
  /// created, leading to an exception.
  Future<Socket?> _tryCreateSocket(WifiP2pConnectionInfo connectionInfo,
      {required int attempts, int delayMs = 500}) async {
    try {
      return await Socket.connect(
          connectionInfo.ownerAddress, NexmonCoordinatorState.wifiP2pPort);
    } catch (e) {
      await Future.delayed(Duration(milliseconds: delayMs));
      if (attempts > 0) {
        return await _tryCreateSocket(
            connectionInfo, attempts: attempts - 1, delayMs: delayMs);
      } else {
        return null;
      }
    }
  }

  void _transitionToStage(NexmonParticipantProtocolStage stage) {
    debugPrint("[Participant] Stage transition: $protocolStage -> $stage");
    _timeoutStopwatch.reset();
    protocolStage = stage;
    notifyListeners();
  }
}

enum NexmonParticipantProtocolStage {
  magicNumberSelection, // initial, ends via startPairing call from UI
  waitingForWifiP2PConnection, // ends with valid P2P credentials received via OOB channel
  waitingForOthers, // ends with ready message via p2p from coordinator
  commitments, // on enter (generate and) tx main commitment via p2p, rx commitments via p2p, ends by repeating check when N-1 commitments rxd
  mainReveals, // on enter (generate and) tx reveal via p2p, rx reveals via p2p, ends by repeating check when N-1 reveals rxd
  verification, // on enter (generate local verification code), rx verification code via OOB, exit on success
  userConfirm, // wait for user input, either tx wrong reveal or step
  matchReveals,
  decryption,
  done,
  error,
  securityError,
  timeout
}
