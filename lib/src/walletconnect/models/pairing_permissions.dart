import 'package:app/src/walletconnect/models/jsonrpc.dart';
import 'package:app/src/walletconnect/models/notifications.dart';
import 'package:app/src/walletconnect/models/pairing_proposed_permissions.dart';

class PairingPermissionsController {
  late String publicKey;
  PairingPermissionsController({required this.publicKey});
}

class PairingPermissions extends PairingProposedPermissions {
  late PairingPermissionsController controller;

  PairingPermissions(
      {required this.controller,
      PairingProposedPermissions? pairingProposedPermissions});

  // factory PairingPermissions.fromJson(Map<String, dynamic> json) {
  //   // TODO: implement fromJson
  //   throw UnimplementedError(
  //       'PairingPermissions.fromJson($json) is not implemented');
  // }

  // Map<String, dynamic> toJson() {
  //   // TODO: implement toJson
  //   throw UnimplementedError();
  // }
}
