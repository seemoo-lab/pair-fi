import 'package:pairfi/features/pairing/audio/grouppairing_protocol.dart';
import 'package:pairfi/features/pairing/audio/services/grouppairing_crypto_service_aes_gcm_ecdh.dart';
import 'package:pairfi/features/pairing/grouppairing_user_parser.dart';
import 'package:pairfi/features/profile/user_model.dart';

/// An immutable data class used to store the settings for
/// the Nexmon group pairing protocol.
class NexmonPairingSettings {
  static const NexmonPairingSettings standard = NexmonPairingSettings(
    nonceLength: 32,
    protocolStageTimeoutMs: 5 * 1000,
    connectionTimeoutMs: 10 * 1000,
    cryptoServiceFactory: GPCryptoServiceAES_GCM_ECDH.new,
    userDataParser: userJsonParserFunction,
    verificationCodeLength: 21,
  );

  /// Length of the nonce in bytes.
  /// Since the nonce is also used as a symmetric key for encryption, it should be at least 16 bytes (= 128 bits) long.
  /// For AES, the only valid lengths are 16, 24 and 32 bytes (= 128, 192, 256 bits resp.)
  final int nonceLength;

  /// The timeout in milliseconds that each of the protocol stages is allowed to take at most
  final int protocolStageTimeoutMs;

  /// The number of milliseconds after which a participant cancels a WiFiP2P connection attempt
  final int connectionTimeoutMs;
  final CryptoServiceFactory cryptoServiceFactory;
  final User? Function(String userData) userDataParser;

  final int verificationCodeLength;

  const NexmonPairingSettings({
    required this.nonceLength,
    required this.protocolStageTimeoutMs,
    required this.connectionTimeoutMs,
    required this.cryptoServiceFactory,
    required this.userDataParser,
    required this.verificationCodeLength,
  });
}
