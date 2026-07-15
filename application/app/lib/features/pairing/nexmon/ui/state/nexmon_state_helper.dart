import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pairfi/features/pairing/audio/grouppairing_helper.dart';
import 'package:pairfi/features/pairing/audio/interfaces/grouppairing_crypto_service_interface.dart';
import 'package:pairfi/features/pairing/audio/models/grouppairing_models.dart';
import 'package:pairfi/features/pairing/audio/wifip2p_communication.dart';
import 'package:pairfi/features/pairing/nexmon/models/nexmon_models.dart';
import 'package:pairfi/features/pairing/nexmon/models/nexmon_pairing_settings.dart';
import 'package:pairfi/features/profile/identity_service.dart';
import 'package:pairfi/features/profile/user_model.dart';
import 'package:pairfi/helper/gui_utility_interface.dart';
import 'package:pairfi/helper_functions.dart';
import 'package:pairfi/service_locator.dart';
import 'package:typed_data/typed_data.dart';

class NexmonStateHelper {
  NexmonStateHelper({settings = NexmonPairingSettings.standard})
      : _settings = settings {
    _generateOwnCommitment();
  }

  late GPCommitment commitment;
  final NexmonPairingSettings _settings;
  late final GroupPairingCryptoServiceInterface _cryptoService = _settings.cryptoServiceFactory();
  Map<int, GPMainCommitment> receivedCommitments = {};
  Map<int, GPMainReveal> receivedMainReveals = {};
  Map<int, GPMatchWrongReveal> receivedMatchReveals = {};
  List<MapEntry<String, GPMainReveal>> sortedReveals = [];
  int myDHIndex = -1;
  Uint8List? sharedGroupKey;
  Queue<GPSecretSharingPacket> secretSharingPackets = Queue();
  Map<int, Uint8List> encryptedSecrets = {};
  String? errorMessage;
  bool? userVerification;

  int get myUid => commitment.uid;

  Uint8List getVerificationCode() {
    final builder = BytesBuilder();
    sortReceivedReveals();
    if (sortedReveals.isNotEmpty) {
      for (final entry in sortedReveals) {
        final reveal = entry.value;
        builder.add(reveal.hashN);
        builder.add(utf8.encode(reveal.uid.toString()));
        builder.add(reveal.dhPublicKey);
        builder.add(reveal.encryptedUserData);
      }
    } else {
      debugPrint("failed to calculate verification code, no reveals available");
      throw NexmonSecurityException();
    }
    return gpDigest(builder.toBytes()).sublist(0, _settings.verificationCodeLength);
  }

  Future<void> _generateOwnCommitment() async {
    final localDatabaseService = getIt<GuiUtilityInterface>();
    final identityService = getIt<IdentityService>();
    final user = await localDatabaseService
        .getUserDetails(await identityService.deviceId);
    final userData = jsonEncode(user.toMap());
    commitment = GPCommitment(_settings.cryptoServiceFactory(), generateUid(),
        _settings.nonceLength, userData);
  }

  Future<List<NexmonMessage>> tryParseAndVerifyData(Uint8List data) async {
    if (data.isEmpty) {
      return [];
    }

    final Uint8Buffer buffer = Uint8Buffer(0);
    buffer.addAll(data);

    final List<NexmonMessage> result = [];
    while (buffer.isNotEmpty) {
      debugPrint("Buffer: $buffer");
      final message = NexmonMessage.parseMessage(buffer);
      debugPrint("Message type == ${message.type}");
      switch (message.type) {
        case NexmonMessageType.mainCommitment:
          final commitment = NexmonCommitment.tryDeserialize(message.payload);
          if (commitment != null) {
            receivedCommitments[commitment.uid] = commitment;
            debugPrint("Added ${commitment.uid} to mainCommitments");
            result.add(message);
          }
          break;
        case NexmonMessageType.mainReveal:
          final reveal = NexmonMainReveal.tryDeserialize(message.payload);
          if (reveal != null) {
            final receivedCommitment = receivedCommitments[reveal.uid];
            if (receivedCommitment != null && reveal.verify(receivedCommitment)) {
              receivedMainReveals[reveal.uid] = reveal;
              result.add(message);
            } else {
              debugPrint("commitment is null (${receivedCommitment == null}) or verify not successful");
              throw NexmonSecurityException();
            }
          }
          break;
        case NexmonMessageType.matchWrongReveal:
          final reveal = NexmonMatchWrongReveal.tryDeserialize(message.payload);
          if (reveal != null) {
            final mainReveal = receivedMainReveals[reveal.uid];
            if (mainReveal != null && reveal.verify(mainReveal)) {
              receivedMatchReveals[reveal.uid] = reveal;
              result.add(message);
            } else {
              debugPrint("mainReveal is null (${mainReveal == null}) or verify not successful");
              throw NexmonSecurityException();
            }
            if (!reveal.isMatch) {
              debugPrint("received wrong nonce, abort");
              throw NexmonSecurityException();
            }
          }
          break;
        case NexmonMessageType.secretSharing:
          final packet = NexmonSecretSharingPacket.tryDeserialize(message.payload);
          debugPrint("[Helper] Got secret sharing packet; deserialize ok: ${packet != null}");
          if (packet != null) {
            secretSharingPackets.addLast(packet);
            result.add(message);
          }
          break;
        case NexmonMessageType.ready:
          result.add(message);
          break;
      }
    }

    return result;
  }

  void sortReceivedReveals() {
    if (sortedReveals.isEmpty) {
      sortedReveals = receivedMainReveals.values
          .map((e) => MapEntry(e.getCommitmentHash(), e))
          .toList();
      sortedReveals.add(MapEntry(commitment.getMainReveal().getCommitmentHash(), commitment.getMainReveal()));
      sortedReveals.sort((e1, e2) => e1.key.compareTo(e2.key));
      myDHIndex = sortedReveals.indexWhere((element) => element.value.uid == myUid);
    }
  }

  Future<GPSecretSharingPacket> performDH(int dhUid, Uint8List publicKeyForDH) async {
    final receivedPublicKey = myDHIndex == 1 // Special case for second participant
        ? _cryptoService.deserializePublicKey(sortedReveals[0].value.dhPublicKey)
        : _cryptoService.deserializePublicKey(publicKeyForDH);
    final dhResult = _cryptoService.singleDHAgreement(commitment.dhKeyPair.privateKey, receivedPublicKey);
    final otherDHPublicKeys = sortedReveals.sublist(max(2, myDHIndex + 1)) // start with at least index 2
        .map((e) => e.value.dhPublicKey)
        .map(_cryptoService.deserializePublicKey);
    sharedGroupKey = _cryptoService.deriveGroupKey(dhResult, otherDHPublicKeys);
    final encryptedSecret = _cryptoService.encryptUserData(sharedGroupKey!, commitment.nonceMatch);

    return GPSecretSharingPacket(dhUid, _cryptoService.serializePublicKey(dhResult.publicKey), myUid, encryptedSecret);
  }

  Map<int, User> decryptAllUserData() {
    final sharedGroupKey = this.sharedGroupKey;
    if (sharedGroupKey == null) {
      throw ProtocolException("Group key couldn't be derived");
    }
    final plainSecrets = encryptedSecrets.map((uid, secret) =>
        MapEntry(uid, _cryptoService.decryptUserData(sharedGroupKey, secret)));

    final userData = receivedMainReveals.map((uid, reveal) {
      final secret = plainSecrets[uid];
      if (secret != null) {
        return MapEntry(uid, _cryptoService.decryptUserData(secret, reveal.encryptedUserData));
      } else {
        return MapEntry(uid, null);
      }
    });

    Map<int, User> users = {};
    for (final entry in userData.entries) {
      if (entry.value != null) {
        final user = _settings.userDataParser(utf8.decode(entry.value!));
        if (user != null) {
          users[entry.key] = user;
        }
      }
    }
    return users;
  }

  void reset() {
    myDHIndex = -1;
    sharedGroupKey = null;
    receivedMainReveals.clear();
    receivedMatchReveals.clear();
    receivedCommitments.clear();
    sortedReveals.clear();
    errorMessage = null;
    userVerification = null;
  }
}
