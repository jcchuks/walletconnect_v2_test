import 'notification.dart';

class SessionNotificaiton {
  String topic;
  Notification? notification;

  SessionNotificaiton({required this.topic, this.notification});

  factory SessionNotificaiton.fromJson(Map<String, dynamic> json) {
    return SessionNotificaiton(
      topic: json['topic'] as String,
      notification: json['Notification'] == null
          ? null
          : Notification.fromJson(json['Notification'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'Notification': notification?.toJson(),
      };
}
