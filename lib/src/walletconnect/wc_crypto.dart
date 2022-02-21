import 'dart:convert';
import 'dart:developer';

import 'package:app/src/walletconnect/wc_errors.dart';
import 'package:app/src/walletconnect/wc_utils.dart';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/pointycastle.dart' as pc;

class WcCrypto {
  final pc.Digest sha256 = pc.Digest("SHA-256");
  final pc.Digest sha512 = pc.Digest("SHA-512");
  final pc.PaddedBlockCipher aesCbcPkcs = pc.PaddedBlockCipher("AES/CBC/PKCS7");
  final pc.Mac hmac = pc.Mac('SHA-256/HMAC');

  static DeserializedData getDeserializedData({required String data}) {
    int nonceEnds = 32;
    int publicKeyEnds = 96;
    int macEnds = 160;

    String nonceStr = data.substring(0, nonceEnds);

    String publicKeyStr = data.substring(nonceEnds, publicKeyEnds);
    String macStr = data.substring(publicKeyEnds, macEnds);
    String cipherStr = data.substring(macEnds);
    return DeserializedData(
        nonce: nonceStr,
        publicKey: publicKeyStr,
        mac: macStr,
        cipher: cipherStr);
  }

  static Future<List<SecretKey>> getEncryptionDecryptionKeys(
      {required String sharedKey}) async {
    List<int> sharedKeyBytes = hex.decode(sharedKey);
    Sha512 encAuthHash = Sha512();
    Hash encAuthKeys = await encAuthHash.hash(sharedKeyBytes);
    int partition = encAuthKeys.bytes.length ~/ 2;

    var encryptionKeys = encAuthKeys.bytes.getRange(0, partition).toList();
    var authenticationKeys = encAuthKeys.bytes
        .getRange(partition, encAuthKeys.bytes.length)
        .toList();

    var algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);
    SecretKey encryptionSecretKey =
        await algorithm.newSecretKeyFromBytes(encryptionKeys);
    SecretKey authenticationSecretKey =
        await algorithm.newSecretKeyFromBytes(authenticationKeys);
    return [encryptionSecretKey, authenticationSecretKey];
  }

  static Future<String> computeHmac(
      {required List<int> nonce,
      required List<int> publicKey,
      required List<int> cipherBytes,
      required SecretKey authenticationSecretKey}) async {
    Hmac mac = Hmac.sha256();
    List<int> payload = List.from(nonce)
      ..addAll(publicKey)
      ..addAll(cipherBytes);
    Mac messageMac =
        await mac.calculateMac(payload, secretKey: authenticationSecretKey);
    String macStr = hex.encode(messageMac.bytes);
    return macStr;
  }

  static Future<String> encrypt(
      {required String sharedKey,
      required String message,
      required String publicKey,
      String iv = ''}) async {
    List<SecretKey> keys =
        await getEncryptionDecryptionKeys(sharedKey: sharedKey);
    SecretKey encryptionSecretKey = keys[0];
    SecretKey authenticationSecretKey = keys[1];

    var messageBytes =
        utf8.encode(message); //addPkcs7Padding(message: message);

    var algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);
    List<int> nonce = iv.isEmpty ? algorithm.newNonce() : hex.decode(iv);

    final secret = await algorithm.encrypt(messageBytes,
        secretKey: encryptionSecretKey, nonce: nonce);

    String macStr = await computeHmac(
        nonce: nonce,
        publicKey: hex.decode(publicKey),
        cipherBytes: secret.cipherText,
        authenticationSecretKey: authenticationSecretKey);

    iv = hex.encode(nonce);
    String cipherTxt = hex.encode(secret.cipherText);

    var data = '$iv$publicKey$macStr$cipherTxt';

    return data;
  }

// @TODO - replace 'message' with a custom type containing iv, pk, mac, cipher.
  static Future<String> decrypt(
      {required String sharedKey, required String message}) async {
    String nonce, publicKey, macStr, cipherText = '';

    List<SecretKey> keys =
        await getEncryptionDecryptionKeys(sharedKey: sharedKey);
    SecretKey decryptionSecretKey = keys[0];
    SecretKey authenticationSecretKey = keys[1];

    DeserializedData deserializedData = getDeserializedData(data: message);
    nonce = deserializedData.nonce;
    publicKey = deserializedData.publicKey;
    macStr = deserializedData.mac;
    cipherText = deserializedData.cipher;

    var cipherTextBytes = hex.decode(cipherText);
    log("public key: : " + publicKey);

    //------------ verify mac
    String computedMac = await computeHmac(
        nonce: hex.decode(nonce),
        publicKey: hex.decode(publicKey),
        cipherBytes: cipherTextBytes,
        authenticationSecretKey: authenticationSecretKey);

    if (computedMac != macStr) {
      throw WcException(
          type: WcErrorType.invalidValue,
          msg:
              "got mac string as $computedMac, received '$macStr' with invalid mac");
    }

    //---------- decrypt cipherText
    SecretBox secretBox =
        SecretBox(cipherTextBytes, nonce: hex.decode(nonce), mac: Mac.empty);

    var algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);
    final messageBytes =
        await algorithm.decrypt(secretBox, secretKey: decryptionSecretKey);
    log(messageBytes.join(","));
    final decodedPayload = utf8.decode(messageBytes);

    //log(cipherTextBytes.length.toString());

    return decodedPayload;
  }

  static Future<String> getSha256({required List<int> data}) async {
    final hashAlgorithm = Sha256();
    Hash topicHash = await hashAlgorithm.hash(data);
    String _hash = hex.encode(topicHash.bytes);
    return _hash;
  }
}
