import 'params.dart';

class RequestArguments {
  String method;
  Params? params;

  RequestArguments({required this.method, this.params});

  factory RequestArguments.fromJson(Map<String, dynamic> json) {
    return RequestArguments(
      method: json['method'] as String,
      params: json['params'] == null
          ? null
          : Params.fromJson(json['params'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method,
        'params': params?.toJson(),
      };
}
