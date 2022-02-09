import 'pairing_participant.dart';
import 'pairing_state.dart';
import 'relay.dart';

class PairingSuccessResponse {
  String? topic;
  Relay? relay;
  PairingParticipant? responder;
  int? expiry;
  PairingState? state;

  PairingSuccessResponse({
    this.topic,
    this.relay,
    this.responder,
    this.expiry,
    this.state,
  });

  factory PairingSuccessResponse.fromJson(Map<String, dynamic> json) {
    return PairingSuccessResponse(
      topic: json['topic'] as String?,
      relay: json['relay'] == null
          ? null
          : Relay.fromJson(json['relay'] as Map<String, dynamic>),
      responder: json['responder'] == null
          ? null
          : PairingParticipant.fromJson(
              json['responder'] as Map<String, dynamic>),
      expiry: json['expiry'] as int?,
      state: json['state'] == null
          ? null
          : PairingState.fromJson(json['state'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'relay': relay?.toJson(),
        'responder': responder?.toJson(),
        'expiry': expiry,
        'state': state?.toJson(),
      };
}
