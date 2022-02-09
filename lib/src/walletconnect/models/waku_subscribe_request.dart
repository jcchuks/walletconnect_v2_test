import 'params.dart';

class WakuSubscibeParams {
  String topic;

  WakuSubscibeParams({
    required this.topic,
  });

  factory WakuSubscibeParams.fromJson(Map<String, dynamic> json) {
    return WakuSubscibeParams(
      topic: json['topic'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
      };
}

class WakuSubscribeRequest {
  int? id;
  String jsonrpc;
  String method;
  WakuSubscibeParams? wakuParams;

  WakuSubscribeRequest({
    this.id,
    this.jsonrpc = '2.0',
    this.method = 'waku_subscribe',
    this.wakuParams,
  });

  factory WakuSubscribeRequest.fromJson(Map<String, dynamic> json) {
    return WakuSubscribeRequest(
      id: json['id'] as int?,
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      method: json['method'] as String? ?? 'waku_subscribe',
      wakuParams: json['params'] == null
          ? null
          : WakuSubscibeParams.fromJson(json['params'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'jsonrpc': jsonrpc,
        'method': method,
        'params': wakuParams?.toJson(),
      };
}
