// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:app/src/walletconnect/models/json_rpc_request.dart';
import 'package:app/src/walletconnect/models/params.dart';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/src/walletconnect/helpers.dart';

import 'test_constants.dart';

void main() {
  late X25519 algorithm;
  setUp(() {
    algorithm = X25519();
  });

  String TEST_MESSAGE = jsonEncode(
      JsonRpcRequest(method: "test_method", id: 1, params: Params(data: {})));
  KeyPairString TEST_SELF = TEST_KEY_PAIRS["A"]!;
  const TEST_IV = "f0d00d4274a7e9711e4e0f21820b8877";
  KeyPairString TEST_PEER = TEST_KEY_PAIRS["B"]!;
  const TEST_MAC =
      "fc6d3106fa827043279f9db08cd2e29a988c7272fa3cfdb739163bb9606822c7";
  const TEST_CIPHERTEXT =
      "14aa7f6034dd0213be5901b472f461769855ac1e2f6bec6a8ed1157a9da3b2df08802cbd6e0d030d86ff99011040cfc831eec3636c1d46bfc22cbe055560fea3";
  String TEST_ENCRYPTED =
      TEST_IV + TEST_SELF.publicKey + TEST_MAC + TEST_CIPHERTEXT;

  test('Verify Cryptolibrary Algorithm', () {
    expect(algorithm.keyPairType, same(KeyPairType.x25519));
    expect(algorithm.keyPairType.name, 'x25519');
    expect(algorithm.keyPairType.publicKeyLength, 32);
  });

  for (var letter in [
    "A",
    "B",
    "C",
  ]) {
    test("Verify Cryptography Library Key Pairs $letter", () async {
      List<int> privateKeyBytes =
          hex.decode(TEST_KEY_PAIRS[letter]!.privateKey);
      List<int> publicKeyBytes = hex.decode(TEST_KEY_PAIRS[letter]!.publicKey);
      SimpleKeyPair keyPair =
          await algorithm.newKeyPairFromSeed(privateKeyBytes);

      final keyPairData = await keyPair.extract();
      expect(keyPairData.type, KeyPairType.x25519,
          reason: "Type is not x25519");
      expect(keyPairData.bytes,
          equals(DartX25519.modifiedPrivateKeyBytes(privateKeyBytes)),
          reason:
              "Failed to compare generated private key with original string private key");

      List<int> privateKeyWrapped = await keyPair.extractPrivateKeyBytes();
      expect(keyPairData.bytes, equals(privateKeyWrapped),
          reason: "Failed to match keypairdata to keypair private keys");
      expect(privateKeyWrapped,
          DartX25519.modifiedPrivateKeyBytes(privateKeyBytes),
          reason:
              "Failed to match keyPair private keys with original string private key");

      final regeneratedPublicKey = await keyPair.extractPublicKey();
      expect(regeneratedPublicKey.type, KeyPairType.x25519,
          reason: "Type is not x25519");

      expect(regeneratedPublicKey.bytes, equals(publicKeyBytes),
          reason:
              "Compare original publicKeyBytes with regeneratedPublicKey.bytes");
    });
  }
  test("Verify Derived Shared Key", () async {
    List<int> privateKeyBytes = hex.decode(TEST_SELF.privateKey);
    SimpleKeyPair keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);
    SecretKey sharedKey = await Helpers.getSharedKey(
        keyPair: keyPair, responderPublicKey: TEST_PEER.publicKey);
    String sharedKeyString = hex.encode(await sharedKey.extractBytes());
    expect(TEST_SHARED_KEY, sharedKeyString,
        reason: "Failed Shared String comparison");
  });

  test("Verify sha256 for Topic generation", () async {
    final String hash =
        await Helpers.getSha256(data: hex.decode(TEST_SHARED_KEY));
    expect(hash, equals(TEST_HASHED_KEY));
  });

  test("Verify encryption algorithm", () async {
    String encrypted = await Helpers.encrypt(
      iv: TEST_IV,
      message: TEST_MESSAGE,
      sharedKey: TEST_SHARED_KEY,
      publicKey: TEST_SELF.publicKey,
    );
    DeserializedData deserialized =
        Helpers.getDeserializedData(data: encrypted);

    expect(deserialized.nonce, equals(TEST_IV),
        reason: "Failed IV match/deserialization");
    expect(deserialized.publicKey, equals(TEST_SELF.publicKey),
        reason: "Failed publicKey match/deserialization");
    expect(deserialized.mac, equals(TEST_MAC),
        reason: "Failed mac match/deserialization");
    expect(deserialized.cipher, equals(TEST_CIPHERTEXT),
        reason: "Failed cipher match/deserialization");
  });

  test("Verify decryption algorithm", () async {
    String decrypted = await Helpers.decrypt(
      message: TEST_ENCRYPTED,
      sharedKey: TEST_SHARED_KEY,
    );
    expect(decrypted, equals(TEST_MESSAGE),
        reason: "Failed decryption match/deserialization");
  });
}
