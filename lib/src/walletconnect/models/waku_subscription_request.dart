import 'package:flutter/material.dart';

import 'params.dart';

class WakuSubsciptionData {
  String topic;
  String message;

  WakuSubsciptionData({required this.topic, required this.message});

  factory WakuSubsciptionData.fromJson(Map<String, dynamic> json) {
    return WakuSubsciptionData(
      topic: json['topic'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'topic': topic, 'message': message};
}

class WakuSubsciptionParams {
  String id;
  WakuSubsciptionData data;

  WakuSubsciptionParams({required this.id, required this.data});

  factory WakuSubsciptionParams.fromJson(Map<String, dynamic> json) {
    return WakuSubsciptionParams(
      id: json['id'] as String,
      data: WakuSubsciptionData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'data': data};
}

class WakuSubscriptionRequest {
  int? id;
  String jsonrpc;
  String method;
  WakuSubsciptionParams params;

  WakuSubscriptionRequest(
      {this.id,
      this.jsonrpc = '2.0',
      this.method = 'waku_subscription',
      required this.params});

  factory WakuSubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return WakuSubscriptionRequest(
      id: json['id'] as int?,
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      method: json['method'] as String? ?? 'waku_subscription',
      params: WakuSubsciptionParams.fromJson(
          json['params'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'jsonrpc': jsonrpc,
        'method': method,
        'params': params.toJson(),
      };
}
