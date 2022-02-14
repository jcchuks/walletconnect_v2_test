class EthereumMethods {
  static const String ethSendTransaction = "eth_sendTransaction";
  static const String ethSignTransaction = "eth_signTransaction";
  static const String ethSign = "eth_sign";
  static const String personalSign = "personal_sign";

  static List<String> getMethodList() {
    return [ethSendTransaction, ethSignTransaction, ethSign, personalSign];
  }
}
