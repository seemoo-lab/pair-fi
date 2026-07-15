/// Library that contains the main protocol implementation
/// for group pairing.
///
/// {@category GroupPairing}
library grouppairing_protocol;

//import 'dart:convert';
//import 'dart:math';
//import 'dart:typed_data';

//import 'package:flutter/foundation.dart';

//import 'grouppairing_helper.dart';
//import 'interfaces/audio_channel_interface.dart';
//import 'interfaces/grouppairing_communication_interface.dart';
import 'interfaces/grouppairing_crypto_service_interface.dart';
//import 'models/grouppairing_errors.dart';
//import 'models/grouppairing_models.dart';
import 'services/grouppairing_crypto_service_aes_gcm_ecdh.dart';
//import 'wifip2p_communication.dart';

part 'grouppairing_settings.dart';

enum GroupPairingState {
  init,
  coordinatorInit,
  deviceInit1,
  deviceInit2,
  establishingConnection,
  sendCommitment,
  collectCommitments,
  sendMainReveal,
  collectMainReveals,
  coordinatorVerification,
  deviceVerification1,
  deviceVerification2,
  userConfirm,
  sendMatchReveal,
  collectMatchReveals,
  secretSharing,
  decrypting,
  done,
  timeout,
  error
}
