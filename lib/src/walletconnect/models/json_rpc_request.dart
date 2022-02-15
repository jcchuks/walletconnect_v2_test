import 'package:app/src/walletconnect/models/params.dart';

class JsonRpcRequest {
  int id;
  String jsonrpc;
  String method;
  Params? params;

  JsonRpcRequest({
    this.id = 0,
    this.jsonrpc = '2.0',
    required this.method,
    this.params,
  });

  factory JsonRpcRequest.fromJson(Map<String, dynamic> json) {
    return JsonRpcRequest(
      id: json['id'] as int,
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      method: json['method'] as String,
      params: json['params'] == null
          ? null
          : Params.fromJson(json['params'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'jsonrpc': jsonrpc,
        'method': method,
        'params': params?.toJson(),
      };

  Map<String, dynamic> methodAndParamsAsJson() => {
        'method': method,
        'params': params?.toJson(),
      };

  Map<String, dynamic> paramsAsJson() => params?.toJson() ?? {};

  factory JsonRpcRequest.fromJsonParameter(Map<String, dynamic> json) {
    return JsonRpcRequest(
      method: 'empty',
      params: json['params'] == null
          ? null
          : Params.fromJson(json['params'] as Map<String, dynamic>),
    );
  }
}
