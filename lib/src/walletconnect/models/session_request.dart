import 'package:app/src/walletconnect/models/params.dart';

class SessionRequest {
  Params request;

  SessionRequest({required this.request});

  factory SessionRequest.fromJson(Map<String, dynamic> json) {
    return SessionRequest(
        request: Params.fromJson(json['request'] as Map<String, dynamic>));
  }

  Map<String, dynamic> toJson() => {'request': request.toJson()};
}
