import 'package:app/src/walletconnect/eth.dart';
import 'package:app/src/walletconnect/wc_errors.dart';

class BlockchainId {
  late String name;
  BlockchainId({required this.name});
}

class BlockChainIds {
  static BlockchainId etheriumMainet = BlockchainId(name: "eip155:1");
  static BlockchainId bitcoinMainet =
      BlockchainId(name: "bip122:000000000019d6689c085ae165831e93");

  static List<String> getChainMethods({required BlockchainId chain}) {
    if (chain.name == etheriumMainet.name) {
      return EthereumMethods.getMethodList();
    }

    throw WcException(
        type: WcErrorType.invalidValue, msg: "Chain not supported");
  }
}
