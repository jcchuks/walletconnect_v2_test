import 'dart:convert';

class Params {
  Map<String, dynamic>? data;

  Params({this.data});

  factory Params.fromJson(Map<String, dynamic> json) {
    // TODO: implement fromJson
    // throw UnimplementedError('Params.fromJson($json) is not implemented');
    return Params(data: json);
  }

  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    return data ?? {};
  }
}
