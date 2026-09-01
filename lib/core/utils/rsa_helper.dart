/// # RsaHelper
///
/// RSA encryption utility that replicates the behaviour of `RSA.java` and the
/// inline encryption block in `LoginActvity.LoginInfoAsyncCall.doInBackground`.
///
/// **Algorithm**: RSA / None / PKCS1Padding  (same as the original Android code
/// which uses `Cipher.getInstance("RSA/None/PKCS1Padding")` implicitly through
/// `RSA.encrypt()`).
///
/// **Key format**: X.509 SubjectPublicKeyInfo, Base64-encoded
/// (stored in [AppConstants.rsaPublicKey]).
///
/// ## Encryption flow (mirrors `LoginActvity.java` lines 280-291)
/// 1. Base64-decode the public key string.
/// 2. Parse as `RSAPublicKey` using `pointycastle`.
/// 3. Encrypt the UTF-8 payload with PKCS#1 v1.5 padding.
/// 4. Base64-encode the cipher bytes.
/// 5. Send the resulting string as the `data` SOAP property.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/pkcs1.dart';
import 'package:pointycastle/asymmetric/rsa.dart';

import '../constants/app_constants.dart';

class RsaHelper {
  RsaHelper._();

  /// ## encrypt
  ///
  /// **Description**: RSA-encrypts [plainText] using the embedded IDECO
  /// public key and returns a Base64-encoded cipher string ready to be
  /// sent as the SOAP `data` property.
  ///
  /// **Algorithm**: RSA / PKCS1 v1.5 padding (`PKCS1Encoding` over `RSAEngine`).
  ///
  /// **Returns**: Base64-encoded encrypted string.
  ///
  /// **Throws**: [Exception] if the key cannot be parsed or encryption fails —
  /// callers should map this to [EncryptionFailure].
  static String encrypt(String plainText) {
    final publicKeyBytes = base64.decode(AppConstants.rsaPublicKey);
    final publicKey = _parsePublicKey(publicKeyBytes);

    final cipher = PKCS1Encoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    final inputBytes = Uint8List.fromList(utf8.encode(plainText));
    final encrypted = _processInBlocks(cipher, inputBytes);
    return base64.encode(encrypted);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static RSAPublicKey _parsePublicKey(Uint8List keyBytes) {
    final asn1Parser = ASN1Parser(keyBytes);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

    // SubjectPublicKeyInfo structure:
    //   SEQUENCE {
    //     SEQUENCE { OID, NULL }   ← algorithm identifier
    //     BIT STRING               ← public key bytes
    //   }
    final publicKeyBitString = topLevelSeq.elements![1] as ASN1BitString;
    // ASN1BitString.valueBytes includes a leading "unused bits" count byte (0x00).
    // Skipping it gives the raw DER bytes of the inner RSAPublicKey SEQUENCE.
    final innerBytes =
        Uint8List.fromList(publicKeyBitString.valueBytes!.sublist(1));
    final publicKeyAsn = ASN1Parser(innerBytes);
    final publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;

    final modulus = (publicKeySeq.elements![0] as ASN1Integer).integer!;
    final exponent = (publicKeySeq.elements![1] as ASN1Integer).integer!;

    return RSAPublicKey(modulus, exponent);
  }

  static Uint8List _processInBlocks(
    AsymmetricBlockCipher cipher,
    Uint8List input,
  ) {
    final blockSize = cipher.inputBlockSize;
    final output = <int>[];
    var offset = 0;
    while (offset < input.length) {
      final end = (offset + blockSize < input.length)
          ? offset + blockSize
          : input.length;
      output.addAll(cipher.process(input.sublist(offset, end)));
      offset += blockSize;
    }
    return Uint8List.fromList(output);
  }
}
