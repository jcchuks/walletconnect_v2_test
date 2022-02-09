import 'result.dart';

class JsonRpcResult {
  int? id;
  String jsonrpc;
  Result? result;

  JsonRpcResult({this.id, this.jsonrpc = '2.0', this.result});

  factory JsonRpcResult.fromJson(Map<String, dynamic> json) => JsonRpcResult(
        id: json['id'] as int?,
        jsonrpc: json['jsonrpc'] as String? ?? '2.0',
        result: json['result'] == null
            ? null
            : Result.fromJson(json['result'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'jsonrpc': jsonrpc,
        'result': result is Result && result!.isBoolType
            ? result?.toBool()
            : result?.toString(),
      };
}
