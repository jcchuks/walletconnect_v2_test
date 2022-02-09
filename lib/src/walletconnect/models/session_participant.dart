import 'app_metadata.dart';

class SessionParticipant {
  String? publicKey;
  AppMetadata? appMetadata;

  SessionParticipant({this.publicKey, this.appMetadata});

  factory SessionParticipant.fromJson(Map<String, dynamic> json) {
    return SessionParticipant(
      publicKey: json['publicKey'] as String?,
      appMetadata: json['AppMetadata'] == null
          ? null
          : AppMetadata.fromJson(json['AppMetadata'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
        'AppMetadata': appMetadata?.toJson(),
      };
}
