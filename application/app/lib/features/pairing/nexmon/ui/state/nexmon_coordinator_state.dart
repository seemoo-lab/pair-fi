import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:messagepack/messagepack.dart';
import 'package:pairfi/features/pairing/audio/models/grouppairing_models.dart';
import 'package:pairfi/features/pairing/audio/services/wifi_p2p_service.dart';
import 'package:pairfi/features/pairing/audio/wifip2p_communication.dart';
import 'package:pairfi/features/pairing/nexmon/models/nexmon_models.dart';
import 'package:pairfi/features/pairing/nexmon/models/nexmon_pairing_settings.dart';
import 'package:pairfi/features/pairing/nexmon/services/nexmon_udp_channel_service.dart';
import 'package:pairfi/features/pairing/nexmon/ui/state/nexmon_state_helper.dart';
import 'package:pairfi/features/pairing/success_list_data.dart';
import 'package:pairfi/helper_functions.dart';
import 'package:pairfi/service_locator.dart';

class NexmonCoordinatorState extends ChangeNotifier {
  static const int wifiP2pPort = 15199;
  static const Set<NexmonMessageType> messageTypesToBroadcast = {
    NexmonMessageType.mainCommitment,
    NexmonMessageType.mainReveal,
    NexmonMessageType.matchWrongReveal
  };

  NexmonCoordinatorProtocolStage protocolStage = NexmonCoordinatorProtocolStage.magicEmoji;
  int? numParticipants;
  int? magicVerificationNumber;
  final Set<(Socket, StreamSubscription<Uint8List>)> _connections = {};
  int get numConnectedParticipants => _connections.length;
  final Queue<(Socket, Uint8List)> _wifiMessages = Queue();

  final NexmonPairingSettings _settings;
  final WifiP2pService _wifiService;
  NexmonUDPChannelService _nexmonService;

  ServerSocket? _wifiP2pListenSocket;

  final NexmonStateHelper _helper;
  String get errorMessage => _helper.errorMessage ?? "";

  SuccessListData? successListData;

  Timer? _messageProcessTimer;
  final Stopwatch _timeoutStopwatch = Stopwatch();

  NexmonCoordinatorState({settings = NexmonPairingSettings.standard})
      : _settings = settings,
        _helper = NexmonStateHelper(settings: settings),
        _wifiService = getIt<WifiP2pService>(),
        _nexmonService = NexmonUDPChannelService.createServiceWithSettings(getIt()) {
    this.addListener(_handleStageTransition);
  }

  Future<void> _handleStageTransition() async {
    switch (protocolStage) {
      case NexmonCoordinatorProtocolStage.commitments:
        await _sendCommitment();
        break;
      case NexmonCoordinatorProtocolStage.mainReveals:
        await _sendMainReveal();
        break;
      case NexmonCoordinatorProtocolStage.verification:
        await _sendVerificationCode();
        break;
      case NexmonCoordinatorProtocolStage.userConfirm:
        /* do nothing as we are waiting for user input */
        break;
      case NexmonCoordinatorProtocolStage.matchReveals:
        await _sendMatchReveal();
        break;
      case NexmonCoordinatorProtocolStage.decryption:
        await _checkDHStart();
        break;
      case NexmonCoordinatorProtocolStage.timeout:
      case NexmonCoordinatorProtocolStage.error:
      case NexmonCoordinatorProtocolStage.securityError:
      case NexmonCoordinatorProtocolStage.done:
        _nexmonService.stopTransmission();
        _messageProcessTimer?.cancel();
        _timeoutStopwatch.stop();
        _timeoutStopwatch.reset();
        break;
      default:
        break;
    }
  }

  Future<void> _processWifiMessage(Socket client, Uint8List data) async {
    debugPrint("[Coordinator ($protocolStage)] Start Processing data: ${data.toHexString()}");
    final messages = await _helper.tryParseAndVerifyData(data);
    if (messages.isEmpty) {
      return;
    }
    for (final message in messages) {
      if (messageTypesToBroadcast.contains(message.type)) {
        await _sendToAll(message.serialize(), filter: (connection) => connection.remoteAddress != client.remoteAddress);
      }
    }
  }

  Future<void> _checkStageTransitions() async {
    if (protocolStage == NexmonCoordinatorProtocolStage.commitments) {
      if (_helper.receivedCommitments.length == _connections.length) {
        _transitionToStage(NexmonCoordinatorProtocolStage.mainReveals);
      }
    } else if (protocolStage == NexmonCoordinatorProtocolStage.mainReveals) {
      if (_helper.receivedMainReveals.length == _connections.length) {
        _transitionToStage(NexmonCoordinatorProtocolStage.verification);
      }
    } else if (protocolStage == NexmonCoordinatorProtocolStage.verification) {
      //
    } else if (protocolStage == NexmonCoordinatorProtocolStage.userConfirm) {
      if (_helper.userVerification != null) {
        if (_helper.userVerification == true) {
          _transitionToStage(NexmonCoordinatorProtocolStage.matchReveals);
        } else {
          throw NexmonSecurityException();
        }
      }
    } else if (protocolStage == NexmonCoordinatorProtocolStage.matchReveals) {
      if (_helper.receivedMatchReveals.length == _connections.length) {
        _transitionToStage(NexmonCoordinatorProtocolStage.decryption);
      }
    } else if (protocolStage == NexmonCoordinatorProtocolStage.decryption) {
      if (_helper.secretSharingPackets.isEmpty) {
        return;
      }
      final receivedPacket = _helper.secretSharingPackets.removeFirst();
      var nextUid = _findNextDHUid(receivedPacket.dhUid);
      debugPrint("Received secret sharing packet; nextUid = $nextUid");
      final newPacket = GPSecretSharingPacket(nextUid, receivedPacket.dhPublicKey, receivedPacket.secretUid, receivedPacket.encryptedSecret);
      _sendToAll(newPacket.serialize());
      _helper.encryptedSecrets[receivedPacket.secretUid] = receivedPacket.encryptedSecret;
      if (nextUid == _helper.myUid) {
        nextUid = _findNextDHUid(nextUid);
        final packet = await _helper.performDH(nextUid, receivedPacket.dhPublicKey);
        _sendToAll(packet.serialize());
      }
      if (nextUid == -1) {
        final users = _helper.decryptAllUserData();
        successListData = SuccessListData(users, _helper.myUid);
        _transitionToStage(NexmonCoordinatorProtocolStage.done);
      }
    }
  }

  void _checkTimeouts() {
    switch (protocolStage) {
      case NexmonCoordinatorProtocolStage.commitments:
      case NexmonCoordinatorProtocolStage.mainReveals:
      case NexmonCoordinatorProtocolStage.verification:
      case NexmonCoordinatorProtocolStage.matchReveals:
      case NexmonCoordinatorProtocolStage.decryption:
        if (_timeoutStopwatch.elapsedMilliseconds > _settings.protocolStageTimeoutMs) {
          _transitionToStage(NexmonCoordinatorProtocolStage.timeout);
        }
      default:
        break;
    }
  }

  Future<void> _enqueueWifiData(Socket client, Uint8List data) async {
    debugPrint("[Coordinator ($protocolStage)] Reveived ${data.length} bytes from ${client.remoteAddress.toString()}: ${data.toHexString()}");

    _wifiMessages.addLast((client, data));
  }

  Future<void> startPairing() async {
    _messageProcessTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      try {
        if (_wifiMessages.isNotEmpty) {
          final (client, data) = _wifiMessages.removeFirst();
          await _processWifiMessage(client, data);
        }
        await _checkStageTransitions();
        _checkTimeouts();
      } on NexmonSecurityException {
        _sendWrongReveal();
        _transitionToStage(NexmonCoordinatorProtocolStage.securityError);
      } catch (e) {
        _helper.errorMessage = e.toString();
        _transitionToStage(NexmonCoordinatorProtocolStage.error);
      }
    });
    _timeoutStopwatch.start();

    // Re-create Nexmon service since settings might have changed (constructor does only get called once due to caching)
    _nexmonService = NexmonUDPChannelService.createServiceWithSettings(getIt());
    await _initWifiP2P();
  }

  Future<void> _initWifiP2P() async {
    debugPrint("[NexmonCoordinatorState] Init Wifi P2P");
    await _wifiService.init();
    if (!await _wifiService.waitForAvailable()) {
      debugPrint("[NexmonCoordinatorState] No Wifi P2P available");
      throw WifiP2pUnavailableException();
    }
    String ssidRandom = "DIRECT-${bytesToHex(randomBytes(1))}";
    String passphraseRandom = randomString(8);
    await _wifiService.createGroupWithConfig(ssidRandom, passphraseRandom, 2472, null);
    final groupInfo = await _wifiService.waitForGroupInfo();
    if (groupInfo == null) {
      throw WifiP2pUnavailableException();
    }
    debugPrint("[NexmonCoordinatorState] WifiP2P created; Group info: {SSID: ${groupInfo.ssid}, passphrase: ${groupInfo.passphrase}}");
    await _setupWifiP2PListener();
    await _nexmonService.startTransmission(_serializeGroupInfo(groupInfo));
  }

  Future<void> _sendCommitment() async {
    await _sendToAll(_helper.commitment.getMainCommitment().serialize());
  }

  Future<void> _sendMainReveal() async {
    await _sendToAll(_helper.commitment.getMainReveal().serialize());
  }

  Future<void> _sendVerificationCode() async {
    var i = magicVerificationNumber = Random().nextInt(9);
    Uint8List data = concatBytes(Uint8List.fromList([i]), _helper.getVerificationCode());
    await _nexmonService.startTransmission(data);
    _transitionToStage(NexmonCoordinatorProtocolStage.userConfirm);
  }

  Future<void> _sendMatchReveal() async {
    await _sendToAll(_helper.commitment.getMatchReveal().serialize());
  }

  Future<void> _sendWrongReveal() async {
    await _sendToAll(_helper.commitment.getWrongReveal().serialize());
  }

  Future<void> _checkDHStart() async {
    debugPrint("My DH index is ${_helper.myDHIndex}; sharedGroupKey == ${_helper.sharedGroupKey?.toHexString()}");
    if (_helper.myDHIndex == 0 && _helper.sharedGroupKey == null) { // sharedGroupKey is null if DH has not been performed yet
      final secondParticipant = _helper.sortedReveals[1];
      final nextUid = secondParticipant.value.uid;
      final packet = await _helper.performDH(nextUid, secondParticipant.value.dhPublicKey);
      _sendToAll(packet.serialize());
    }
  }

  int _findNextDHUid(int currentUid) {
    int currentIndex = _helper.sortedReveals.indexWhere((element) => element.value.uid == currentUid);
    int nextUid;
    if (currentIndex >= 0) {
      if (currentIndex < _helper.sortedReveals.length - 1) {
        nextUid = _helper.sortedReveals[currentIndex + 1].value.uid;
      } else {
        nextUid = -1;
      }
    } else {
      throw ProtocolException("Unknown UID");
    }

    return nextUid;
  }

  Future<void> handleUserConfirmation(bool confirm) async {
    _nexmonService.stopTransmission();
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
    protocolStage = NexmonCoordinatorProtocolStage.magicEmoji;
    await _nexmonService.dispose();
    await _wifiP2pListenSocket?.close();
    await _wifiService.removeGroup();
    for (final (socket, stream) in _connections) {
      await stream.cancel();
      await socket.flush();
      await socket.close();
    }
    _connections.clear();
    _helper.reset();
    numParticipants = null;
    magicVerificationNumber = null;
    debugPrint("[Coordinator] Reset done");
  }

  Future<void> _setupWifiP2PListener() async {
    _wifiP2pListenSocket = await ServerSocket.bind(InternetAddress.anyIPv4, wifiP2pPort);
    _wifiP2pListenSocket!.listen((client) async {
      debugPrint("[NexmonCoordinatorState] Client ${client.remoteAddress.toString()} connected");

      final stream = client.listen((data) async => await _enqueueWifiData(client, data), onDone: () async {
        debugPrint("[NexmonCoordinatorState] Client disconnected");
        await client.close();
        _connections.removeWhere((e) => e.$1 == client);
        notifyListeners();
      }, onError: (error) async {
        debugPrint("[NexmonCoordinatorState] Client error: $error");
        await client.close();
        _connections.removeWhere((e) => e.$1 == client);
        notifyListeners();
      });
      _connections.add((client, stream));
      notifyListeners();

      if (_connections.length == (numParticipants ?? 0) - 1) {
        debugPrint("[NexmonCoordinatorState] All clients connected, sending ready message...");
        await _nexmonService.stopTransmission();
        _sendToAll(NexmonMessageType.buildReadyMessage());
        _transitionToStage(NexmonCoordinatorProtocolStage.commitments);
      }
    });
  }

  Uint8List _serializeGroupInfo(WifiP2pGroupInfo groupInfo) {
    final p = Packer();
    p.packInt(numParticipants);
    p.packString(groupInfo.ssid);
    p.packString(groupInfo.passphrase);
    return p.takeBytes();
  }

  /// Sends [data] to all connections.
  /// If the [filter] is not null, only those connections are considered, for
  /// which the [filter] function evaluates to `true`.
  Future<void> _sendToAll(Uint8List data, {bool Function(Socket)? filter}) async {
    for (final (connection, _) in _connections) {
      if (filter == null || filter(connection)) {
        debugPrint("[NexmonCoordinatorState] Sending ${data.toHexString()} to ${connection.remoteAddress.address}");
        connection.add(data);
      }
    }
  }

  void _transitionToStage(NexmonCoordinatorProtocolStage stage) {
    debugPrint("[NexmonCoordinatorState] Stage transition: $protocolStage -> $stage");
    _timeoutStopwatch.reset();
    protocolStage = stage;
    notifyListeners();
  }
}

enum NexmonCoordinatorProtocolStage {
  magicEmoji,
  commitments, // enter after tx ready msg via p2p (when N-1 have connected), (generate and) tx main commitment, exit on regular check when N-1 commitments rxd (and forwarded) via p2p
  mainReveals, // enter on all commitments rxd via p2p, tx main reveal, exit on regular check when N-1 reveals rxd (and forwarded) via p2p
  verification, // enter on all reveals rxd via p2p, (calc and) start tx verification code via OOB, goto confirm screen
  userConfirm, // wait for user input, either tx wrong reveal or step
  matchReveals,
  decryption,
  done,
  error,
  securityError,
  timeout
}
