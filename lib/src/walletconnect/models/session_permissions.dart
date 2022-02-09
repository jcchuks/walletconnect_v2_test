import 'package:app/src/walletconnect/models/session_proposed_permissions.dart';

class SessionPermissionsController {
  late String publicKey;
  SessionPermissionsController({required this.publicKey});
}

class SessionPermissions {
  late SessionPermissionsController controller;

  SessionPermissions(
      {required SessionPermissionsController pairingPermissionsController,
      SessionProposedPermissions? sessionProposedPermissions}) {
    pairingPermissionsController = pairingPermissionsController;
  }

  // factory SessionPermissions.fromJson(Map<String, dynamic> json) {
  //   // TODO: implement fromJson
  //   throw UnimplementedError(
  //       'SessionPermissions.fromJson($json) is not implemented');
  // }

  // Map<String, dynamic> toJson() {
  //   // TODO: implement toJson
  //   throw UnimplementedError();
  // }
}
