import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:messagepack/messagepack.dart';
import 'package:pairfi/features/pairing/audio/models/grouppairing_models.dart';
import 'package:pairfi/helper_functions.dart';
import 'package:typed_data/typed_data.dart';

enum NexmonMessageType {
  mainCommitment,
  mainReveal,
  matchWrongReveal,
  secretSharing,
  ready;

  static Uint8List buildReadyMessage() {
    return NexmonMessage(NexmonMessageType.ready, Uint8List(0)).serialize();
  }
}

class NexmonSecurityException implements Exception {
  NexmonSecurityException();
}

class NexmonMessage {
  final NexmonMessageType type;
  final Uint8List payload;

  NexmonMessage(this.type, this.payload);

  Uint8List serialize() {
    final result = [type.index] + intToBytes(payload.length) + payload;
    return Uint8List.fromList(result);
  }

  static NexmonMessage parseMessage(Uint8Buffer data) {
    if (data.length < 5) {
      throw Exception("Data is not a valid message");
    }

    final typeIndex = data.removeAt(0);
    if (typeIndex >= NexmonMessageType.values.length) {
      throw Exception("Data is not a valid message");
    }
    final type = NexmonMessageType.values[typeIndex];
    final length = takeInt(data);
    debugPrint("take $length from ${data.length}");
    final payload = takeN(length, data);

    return NexmonMessage(type, payload);
  }
}


extension NexmonCommitment on GPMainCommitment {
  Uint8List serialize() {
    Packer p = Packer();
    p.packInt(uid);
    p.packBinary(commitment);
    return NexmonMessage(NexmonMessageType.mainCommitment, p.takeBytes()).serialize();
  }

  static GPMainCommitment? tryDeserialize(Uint8List bytes) {
    Unpacker unpacker = Unpacker(bytes);
    final uid = unpacker.unpackInt();
    final commitment = unpacker.unpackBinary();
    if (uid != null && commitment.isNotEmpty) {
      return GPMainCommitment(uid, Uint8List.fromList(commitment));
    }
    return null;
  }
}

extension NexmonMainReveal on GPMainReveal {
  Uint8List serialize() {
    Packer packer = Packer();
    packer.packInt(uid);
    packer.packBinary(hashN);
    packer.packBinary(dhPublicKey);
    packer.packBinary(encryptedUserData);
    return NexmonMessage(NexmonMessageType.mainReveal, packer.takeBytes()).serialize();
  }

  static GPMainReveal? tryDeserialize(Uint8List data) {
    Unpacker unpacker = Unpacker(data);
    final uid = unpacker.unpackInt();
    final hashN = unpacker.unpackBinary();
    final dhPublicKey = unpacker.unpackBinary();
    final encryptedUserData = unpacker.unpackBinary();

    if (uid != null && hashN.isNotEmpty && dhPublicKey.isNotEmpty && encryptedUserData.isNotEmpty) {
      return GPMainReveal(uid, Uint8List.fromList(hashN), Uint8List.fromList(dhPublicKey), Uint8List.fromList(encryptedUserData));
    }
    return null;
  }
}

extension NexmonMatchWrongReveal on GPMatchWrongReveal {
  Uint8List serialize() {
    Packer packer = Packer();
    packer.packInt(uid);
    packer.packBinary(nonce);
    packer.packBinary(hash);
    packer.packBool(isMatch);
    return NexmonMessage(NexmonMessageType.matchWrongReveal, packer.takeBytes()).serialize();
  }

  static GPMatchWrongReveal? tryDeserialize(Uint8List data) {
    Unpacker unpacker = Unpacker(data);
    final uid = unpacker.unpackInt();
    final nonce = unpacker.unpackBinary();
    final hash = unpacker.unpackBinary();
    final isMatch = unpacker.unpackBool();

    if (uid != null && nonce.isNotEmpty && hash.isNotEmpty && isMatch != null) {
      return GPMatchWrongReveal(uid, Uint8List.fromList(nonce), Uint8List.fromList(hash), isMatch);
    }
    return null;
  }
}

extension NexmonSecretSharingPacket on GPSecretSharingPacket {
  Uint8List serialize() {
    Packer packer = Packer();
    packer.packInt(dhUid);
    packer.packBinary(dhPublicKey);
    packer.packInt(secretUid);
    packer.packBinary(encryptedSecret);
    return NexmonMessage(NexmonMessageType.secretSharing, packer.takeBytes()).serialize();
  }

  static GPSecretSharingPacket? tryDeserialize(Uint8List data) {
    Unpacker unpacker = Unpacker(data);
    final dhUid = unpacker.unpackInt();
    final dhPublicKey = unpacker.unpackBinary();
    final secretUid = unpacker.unpackInt();
    final encryptedSecret = unpacker.unpackBinary();

    if (dhUid != null && dhPublicKey.isNotEmpty && secretUid != null && encryptedSecret.isNotEmpty) {
      return GPSecretSharingPacket(dhUid, Uint8List.fromList(dhPublicKey), secretUid, Uint8List.fromList(encryptedSecret));
    }
    return null;
  }
}