class DeserializedData {
  final String cipher;
  final String nonce;
  final String mac;
  final String publicKey;

  DeserializedData(
      {required this.cipher,
      required this.nonce,
      required this.mac,
      required this.publicKey});
}
