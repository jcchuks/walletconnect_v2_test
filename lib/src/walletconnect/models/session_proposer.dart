import 'app_metadata.dart';

class SessionProposer {
  String publicKey;
  bool controller;
  AppMetadata? metadata;

  SessionProposer(
      {required this.publicKey, required this.controller, this.metadata});

  factory SessionProposer.fromJson(Map<String, dynamic> json) {
    return SessionProposer(
      publicKey: json['publicKey'] as String,
      controller: json['controller'] as bool,
      metadata: json['metadata'] == null
          ? null
          : AppMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
        'controller': controller,
        'metadata': metadata?.toJson(),
      };
}
