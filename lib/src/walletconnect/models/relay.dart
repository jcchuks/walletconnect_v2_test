import 'params.dart';

class Relay {
  String protocol;
  Params? params;

  Relay({this.protocol = "waku", this.params});

  factory Relay.fromJson(Map<String, dynamic> json) => Relay(
        protocol: json['protocol'] as String,
        params: json['params'] == null
            ? null
            : Params.fromJson(json['params'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'protocol': protocol,
        'params': params?.toJson(),
      };
}
