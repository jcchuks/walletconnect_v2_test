import 'relay.dart';

class UriParameters {
  String protocol;
  int version;
  String? topic;
  String? publicKey;
  bool controller;
  Relay? relay;

  UriParameters(
      {this.protocol = 'waku',
      this.version = 2,
      this.topic,
      this.publicKey,
      this.controller = false,
      this.relay}) {
    relay = relay ?? Relay();
  }

  factory UriParameters.fromJson(Map<String, dynamic> json) => UriParameters(
        protocol: json['protocol'] as String? ?? 'waku',
        version: json['version'] as int? ?? 2,
        topic: json['topic'] as String?,
        publicKey: json['publicKey'] as String?,
        controller: json['controller'] as bool,
        relay: json['relay'] == null
            ? null
            : Relay.fromJson(json['relay'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'protocol': protocol,
        'version': version,
        'topic': topic,
        'publicKey': publicKey,
        'controller': controller,
        'relay': relay?.toJson(),
      };
}
