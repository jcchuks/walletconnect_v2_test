// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:app/src/walletconnect/models/json_rpc_request.dart';
import 'package:app/src/walletconnect/models/params.dart';
import 'package:app/src/walletconnect/models/session_proposal.dart';
import 'package:app/src/walletconnect/wc_crypto2.dart';
import 'package:app/src/walletconnect/wc_errors.dart';
import 'package:app/src/walletconnect/wc_utils.dart';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/src/walletconnect/helpers2.dart';
import 'package:x25519/x25519.dart' as x;

import 'test_constants.dart';

void main() {
  late X25519 algorithm;
  setUp(() {
    algorithm = X25519();
  });

  String TEST_MESSAGE = jsonEncode(
      JsonRpcRequest(method: "test_method", id: 1, params: Params(data: {}))
          .toJson());
  KeyPairString TEST_SELF = TEST_KEY_PAIRS["A"]!;
  const TEST_IV = "f0d00d4274a7e9711e4e0f21820b8877";
  KeyPairString TEST_PEER = TEST_KEY_PAIRS["B"]!;
  const TEST_MAC =
      "fc6d3106fa827043279f9db08cd2e29a988c7272fa3cfdb739163bb9606822c7";
  const TEST_CIPHERTEXT =
      "14aa7f6034dd0213be5901b472f461769855ac1e2f6bec6a8ed1157a9da3b2df08802cbd6e0d030d86ff99011040cfc831eec3636c1d46bfc22cbe055560fea3";
  String TEST_ENCRYPTED =
      TEST_IV + TEST_SELF.publicKey + TEST_MAC + TEST_CIPHERTEXT;

  test("Verify Key pairs C", () {
    List<int> evePrivateKey = hex.decode(TEST_KEY_PAIRS["C"]!.privateKey);
    List<int> evePublicKey = hex.decode(TEST_KEY_PAIRS["C"]!.publicKey);

    var evePublicKey2 = List<int>.filled(32, 0);

    x.ScalarBaseMult(evePublicKey2, evePrivateKey);
    expect(evePublicKey, Uint8List.fromList(evePublicKey2),
        reason: "Eve failed");
  });

  test("Verify Derived Shared Key", () async {
    List<int> privateKeyBytes = hex.decode(TEST_SELF.privateKey);
    SimpleKeyPair keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);
    SecretKey sharedKey = await Helpers2.getSharedKey(
        keyPair: keyPair, responderPublicKey: TEST_PEER.publicKey);
    String sharedKeyString = hex.encode(await sharedKey.extractBytes());
    expect(TEST_SHARED_KEY, sharedKeyString,
        reason: "Failed Shared String comparison");
  });

  test("Verify sha256 for Topic generation", () async {
    final String hash = await WcCrypto2.getSha256(
        data: hex.decode(TEST_SHARED_KEY) as Uint8List);
    expect(hash, equals(TEST_HASHED_KEY));
  });

  test("Verify encryption algorithm", () async {
    String encrypted = await WcCrypto2.encrypt(
      iv: TEST_IV,
      message: TEST_MESSAGE,
      sharedKey: TEST_SHARED_KEY,
      publicKey: TEST_SELF.publicKey,
    );
    DeserializedData deserialized =
        WcCrypto2.getDeserializedData(data: encrypted);

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
    String decrypted = WcCrypto2.decrypt(
      message: TEST_ENCRYPTED,
      sharedKey: TEST_SHARED_KEY,
    );
    expect(decrypted, equals(TEST_MESSAGE),
        reason: "Failed decryption match/deserialization");
  });

  test("Codec AES_256_CBC and Hmac_SHA256 authentication test", () async {
    String sharedKey =
        "94BA14D48AAF8E0D3FA13E94A73C8745136EB7C3D7BA6232E6512A78D6624A04";
    String message = "WalletConnect";

    String encryptedMessage = WcCrypto2.encrypt(
        message: message,
        sharedKey: sharedKey,
        publicKey:
            "355957413b1693eea042918f8f346618bfdc29e9d00f2e6bbd702bc29c3e2e4d");
    DeserializedData payload =
        WcCrypto2.getDeserializedData(data: encryptedMessage);
    expect(payload.publicKey,
        "355957413b1693eea042918f8f346618bfdc29e9d00f2e6bbd702bc29c3e2e4d");
    String text =
        WcCrypto2.decrypt(message: encryptedMessage, sharedKey: sharedKey);
    expect(text, message);
  });

  test("Codec AES_256_CBC and Hmac_SHA256 invalid HMAC test", () async {
    String sharedKey1 =
        "94BA14D48AAF8E0D3FA13E94A73C8745136EB7C3D7BA6232E6512A78D6624A04";
    String sharedKey2 =
        "95BA14D48AAF8E0D3FA13E94A73C8745136EB7C3D7BA6232E6512A78D6624A04";
    String message = "WalletConnect";

    String encryptedMessage = WcCrypto2.encrypt(
        message: message,
        sharedKey: sharedKey1,
        publicKey:
            "355957413b1693eea042918f8f346618bfdc29e9d00f2e6bbd702bc29c3e2e4d");
    DeserializedData payload =
        WcCrypto2.getDeserializedData(data: encryptedMessage);
    expect(payload.publicKey,
        "355957413b1693eea042918f8f346618bfdc29e9d00f2e6bbd702bc29c3e2e4d");

    anonymousFunc() =>
        WcCrypto2.decrypt(message: encryptedMessage, sharedKey: sharedKey2);
    expect(anonymousFunc, throwsA(isA<WcException>()));
  });

  test("Get auth and hmac keys test", () async {
    String sharedKey =
        "4b21b43b2e04dbe0105d250f5d72d5d9c28d8de202f240863e268e4ded9e9a6a";

    String decryptionKey =
        "c237bae5d78d52a6a718202fabfaae1cdfb83dd8a54b575c2e2f3e11fb67fa8b";
    String hmac =
        "50e98dc7a1013c3c38f76aaa80dd7ca6c4230a866298415f308c59d4285a6f48";

    List<Uint8List> keys =
        WcCrypto2.getEncryptionDecryptionKeys(sharedKey: sharedKey);
    var decrypt = keys.first;
    var auth = keys.last;

    expect(hex.encode(decrypt), decryptionKey);
    expect(hex.encode(auth), hmac);
  });

  test("deserialize encrypted message to encryption payload", () async {
    String hexPayload =
        "ffbecf819a49a266b262309ad269ae4016ef8b8ef1f010d4447b7e089aac0b943d5e2ca94646ddcfa92f4e8e5778cc3e39e3e876dd95065c5899b95a98512664a8c77853c47d31c2e714e50018f3d1b525dbd2f76cde5bff8b261f343ecb3d956ad9e74819c8729fa1c77be4b5fb7d39ccc697bda421fb90d11315d828e79fca6a27316d3b09f14c7f3483b25b000820e7b64a75e5f59216e5f0ecbc4ec20c53664ad5e967026aa119a32a655e3ff3e110ca4c7e629b845b8ecf7ea6f296a79a6de3dc5794c3a51059bb08b09974501ffcf2d7fddafafd9f1b22e97b6abbb6bcd978a8a87341f33bc662c101947a06c72f6c7709a0a612f46fcd8b5fbce0bdd4c56ca330e6e2802fbf6e3830210f3c1b626863de93fd02857c615436e1b9dc7d36d45bbec8acfb24cd45c46946832d5a7cc20334fd7405dba997daf4725bc849450f197e7e9e2f5e20839ba1f77895b3cbccc279fdc0a9d40156a28ad2adcd6a8afc68f9735c4e7c22c49caf5150f243bab702a71699c9b26420668c81fc5b311488331a4456ba1baf619818b4ecfe6f6de8f80dc42a85c785aa78dd187e82faec549780051551335c651af10f89a3e37103e56a8ebf27f3054e4303a6bce88d7c082bfda897facfd952df5d3d6776370884cb04923c804c99059bb269fdbff3543d89648f39a7cc6fdad61ea0f24deeab420bc65dde6c7a6a3f5fe3775fe4a95a8bf8b70ae946696c808206baf119f0b3142d502c7ca0c102548a1263de2c04bde47aa1a716ae7b00959e300b56d6f0595d1588e07c618b914e3c76cb7d103cd8c6b91ed0aaadc2c129455c07905e5272ea4039660cb8e53a64101dae6e8737a082ac9a9b531a4cbc83e009c1722ca108a26bd193817392890b80cf519f2f14e1fc0e1b47d0b7da47d0635eace28e42456a222da5f2044895914a0b21568d49c222f55b114a558649f094012dbaaabd02ad1aae591d80b8754bb39964f4b9c235166b1ea5c80eb9870e90f073722926f823e5ca72714de10f6f4ed4072bfd3ffc4d32ec0e920edb404b7b1afa1f001d18948fe25562c9b8d52824a4fad20082f28a13e96b7277cb4e7a5ccbbf8095293892b2bac008fcee038765743fb9688abf8affd2477f7de90494ccbba94f6a88a0e0c215d5134b70f41f28754e1b236ab43ec65696fa182fa9525a70e7f42141ec38cfe57d26230b3d520ba2769517c9f8f43a161d38438079b967ab73835865b68a22d3cde7a37fccad1ee3f33ae13bb0f09b4b86ce2ee07823ba793a0fafee";

    DeserializedData payload = WcCrypto2.getDeserializedData(data: hexPayload);

    expect(payload.nonce.length, 32);
    expect(payload.publicKey.length, 64);
    expect(payload.mac.length, 64);

    String sharedKey =
        "b426d6b8b7a57930cae8870179864849d6e89f1e8e801f7ca9a50bc2384ee043";
    String json =
        await WcCrypto2.decrypt(message: hexPayload, sharedKey: sharedKey);
    Map<String, dynamic> jsonMap = jsonDecode(json);

    JsonRpcRequest jsonRpcRequest = JsonRpcRequest.fromJson(jsonMap);
    JsonRpcRequest jsonRpcRequest2 = JsonRpcRequest.fromJsonParameter(
        jsonRpcRequest.params!.data!['request']);
    var proposal = SessionProposal.fromJson(jsonRpcRequest2.params!.data!);

    //@Todo - update with response post settlement pairing payload
    expect(proposal.proposer!.publicKey,
        "37d8c448a2241f21550329f451e8c1901e7dad5135ade604f1e106437843037f");
  });
}
