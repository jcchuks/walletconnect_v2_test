import 'jsonrpc.dart';
import 'notifications.dart';

class PairingProposedPermissions {
  Jsonrpc? jsonrpc;
  Notifications? notifications;

  PairingProposedPermissions({this.jsonrpc, this.notifications});

  factory PairingProposedPermissions.fromJson(Map<String, dynamic> json) {
    return PairingProposedPermissions(
      jsonrpc: json['jsonrpc'] == null
          ? null
          : Jsonrpc.fromJson(json['jsonrpc'] as Map<String, dynamic>),
      notifications: json['notifications'] == null
          ? null
          : Notifications.fromJson(
              json['notifications'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'jsonrpc': jsonrpc?.toJson(),
        'notifications': notifications?.toJson(),
      };
}
