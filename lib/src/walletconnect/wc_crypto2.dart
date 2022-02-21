import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:developer' as d;

import 'package:app/src/walletconnect/wc_errors.dart';
import 'package:app/src/walletconnect/wc_utils.dart';
import 'package:convert/convert.dart';
import 'package:pointycastle/pointycastle.dart' as pc;
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/random/fortuna_random.dart';

const bool ENCRYPT_MODE = true;
const bool DECRYPT_MODE = false;

class WcCrypto2 {
  static const int IV_LENGTH = 16;
  static pc.Digest get wSha256 => pc.Digest("SHA-256");
  static pc.Digest get wSha512 => pc.Digest("SHA-512");
  static pc.PaddedBlockCipher wAesCbcPkcs(
      {required Uint8List key, required Uint8List iv, required bool mode}) {
    var algo = pc.PaddedBlockCipher("AES/CBC/PKCS7");
    final parametersWithIV =
        ParametersWithIV<KeyParameter>(KeyParameter(key), iv);
    final paddedBlockCipherParameters =
        PaddedBlockCipherParameters(parametersWithIV, null);
    algo.init(mode, paddedBlockCipherParameters); // true=encrypt
    return algo;
  }

  static pc.Mac wHmac({required Uint8List key}) {
    var algorithm = pc.Mac('SHA-256/HMAC');
    algorithm.init(KeyParameter(key));
    return algorithm;
  }

  static FortunaRandom wRand = FortunaRandom();

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

  static List<Uint8List> getEncryptionDecryptionKeys(
      {required String sharedKey}) {
    List<int> sharedKeyBytes = hex.decode(sharedKey);
    var encAuthKeys = wSha512.process(Uint8List.fromList(sharedKeyBytes));
    int partition = encAuthKeys.length ~/ 2;

    var encryptionKeys =
        Uint8List.fromList(encAuthKeys.getRange(0, partition).toList());
    var authenticationKeys = Uint8List.fromList(
        encAuthKeys.getRange(partition, encAuthKeys.length).toList());

    return [encryptionKeys, authenticationKeys];
  }

  static String _computeHmac(
      {required Uint8List nonce,
      required Uint8List publicKey,
      required Uint8List cipherBytes,
      required Uint8List authenticationSecretKey}) {
    Uint8List payload = Uint8List.fromList(List.from(nonce)
      ..addAll(publicKey)
      ..addAll(cipherBytes));
    var algorithm = wHmac(key: authenticationSecretKey);
    var messageMac = algorithm.process(payload);
    return hex.encode(messageMac);
  }

  static getIv({Uint8List? seed}) {
    Random rand = Random.secure();
    var key =
        seed ?? Uint8List.fromList(List.generate(32, (_) => rand.nextInt(255)));
    wRand.seed(pc.KeyParameter(key));
    var bytes = wRand.nextBytes(IV_LENGTH);
    return bytes;
  }

  static String encrypt(
      {required String sharedKey,
      required String message,
      required String publicKey,
      String iv = ''}) {
    Uint8List nonce = iv.isEmpty ? getIv() : hex.decode(iv) as Uint8List;

    return _encrypt(
        sharedKey: sharedKey,
        message: message,
        publicKey: publicKey,
        iv: nonce);
  }

  static String _encrypt(
      {required String sharedKey,
      required String message,
      required String publicKey,
      required Uint8List iv}) {
    List<Uint8List> keys = getEncryptionDecryptionKeys(sharedKey: sharedKey);
    Uint8List encryptionSecretKey = keys.first;
    Uint8List authenticationSecretKey = keys.last;

    Uint8List messageBytes = utf8.encode(message) as Uint8List;

    //initialize paddedBlockCipher
    var algorithm =
        wAesCbcPkcs(key: encryptionSecretKey, iv: iv, mode: ENCRYPT_MODE);
    Uint8List secret = algorithm.process(messageBytes);

    String macStr = _computeHmac(
        nonce: iv,
        publicKey: hex.decode(publicKey) as Uint8List,
        cipherBytes: secret,
        authenticationSecretKey: authenticationSecretKey);

    String nonce = hex.encode(iv);
    String cipherTxt = hex.encode(secret);

    return '$nonce$publicKey$macStr$cipherTxt';
  }

  static String decrypt({required String sharedKey, required String message}) {
    return _decrypt(sharedKey: sharedKey, cipherText: message);
  }

  static String _decrypt(
      {required String sharedKey, required String cipherText}) {
    Uint8List nonce, publicKey, cipherBytes;

    List<Uint8List> keys = getEncryptionDecryptionKeys(sharedKey: sharedKey);
    Uint8List decryptionSecretKey = keys.first;
    Uint8List authenticationSecretKey = keys.last;

    DeserializedData deserializedData = getDeserializedData(data: cipherText);
    nonce = Uint8List.fromList(hex.decode(deserializedData.nonce));
    publicKey = Uint8List.fromList(hex.decode(deserializedData.publicKey));
    cipherBytes = Uint8List.fromList(hex.decode(deserializedData.cipher));

    //------------ verify mac
    String computedMac = _computeHmac(
        nonce: nonce,
        publicKey: publicKey,
        cipherBytes: cipherBytes,
        authenticationSecretKey: authenticationSecretKey);

    if (computedMac != deserializedData.mac) {
      throw WcException(
          type: WcErrorType.invalidValue,
          msg:
              "got mac string as $computedMac, received '${deserializedData.mac}' with invalid mac");
    }

    //---------- decrypt cipherText

    var algorithm =
        wAesCbcPkcs(key: decryptionSecretKey, iv: nonce, mode: DECRYPT_MODE);
    Uint8List messageBytes = algorithm.process(cipherBytes);
    d.log(messageBytes.join(","));
    final decodedPayload = utf8.decode(messageBytes);

    return decodedPayload;
  }

  static String getSha256({required Uint8List data}) {
    var topicHash = wSha256.process(data);
    return hex.encode(topicHash);
  }
}
