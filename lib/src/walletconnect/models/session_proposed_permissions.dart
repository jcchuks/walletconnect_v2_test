import 'blockchain.dart';
import 'jsonrpc.dart';
import 'notifications.dart';

class SessionProposedPermissions {
  Blockchain blockchain;
  Jsonrpc? jsonrpc;
  Notifications? notifications;

  SessionProposedPermissions({
    required this.blockchain,
    this.jsonrpc,
    this.notifications,
  });

  factory SessionProposedPermissions.fromJson(Map<String, dynamic> json) {
    return SessionProposedPermissions(
      blockchain:
          Blockchain.fromJson(json['blockchain'] as Map<String, dynamic>),
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
        'blockchain': blockchain.toJson(),
        'jsonrpc': jsonrpc?.toJson(),
        'notifications': notifications?.toJson(),
      };
}
