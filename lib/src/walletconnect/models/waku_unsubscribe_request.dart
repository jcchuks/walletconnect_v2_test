import 'params.dart';

class WakuUnsubscibeParams {
  String id;
  String topic;

  WakuUnsubscibeParams({required this.id, required this.topic});

  factory WakuUnsubscibeParams.fromJson(Map<String, dynamic> json) {
    return WakuUnsubscibeParams(
        id: json['id'] as String, topic: json['topic'] as String);
  }

  Map<String, dynamic> toJson() => {'id': id, 'topic': topic};
}

class WakuUnsubscribeRequest {
  int? id;
  String jsonrpc;
  String method;
  WakuUnsubscibeParams? params;

  WakuUnsubscribeRequest({
    this.id,
    this.jsonrpc = '2.0',
    this.method = 'waku_unsubscribe',
    this.params,
  });

  factory WakuUnsubscribeRequest.fromJson(Map<String, dynamic> json) {
    return WakuUnsubscribeRequest(
      id: json['id'] as int?,
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      method: json['method'] as String? ?? 'waku_unsubscribe',
      params: json['params'] == null
          ? null
          : WakuUnsubscibeParams.fromJson(
              json['params'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'jsonrpc': jsonrpc,
        'method': method,
        'params': params?.toJson(),
      };
}
