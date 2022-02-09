import 'app_metadata.dart';

class SessionProposer {
  String publicKey;
  bool controller;
  AppMetadata? appMetadata;

  SessionProposer(
      {required this.publicKey, required this.controller, this.appMetadata});

  factory SessionProposer.fromJson(Map<String, dynamic> json) {
    return SessionProposer(
      publicKey: json['publicKey'] as String,
      controller: json['controller'] as bool,
      appMetadata: json['AppMetadata'] == null
          ? null
          : AppMetadata.fromJson(json['AppMetadata'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
        'controller': controller,
        'AppMetadata': appMetadata?.toJson(),
      };
}
