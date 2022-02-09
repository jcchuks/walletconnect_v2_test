import 'error.dart';

class JsonRpcError {
  int? id;
  String jsonrpc;
  Error? error;

  JsonRpcError({this.id, this.jsonrpc = '2.0', this.error});

  factory JsonRpcError.fromJson(Map<String, dynamic> json) => JsonRpcError(
        id: json['id'] as int?,
        jsonrpc: json['jsonrpc'] as String? ?? '2.0',
        error: json['error'] == null
            ? null
            : Error.fromJson(json['error'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'jsonrpc': jsonrpc,
        'error': error?.toJson(),
      };
}
