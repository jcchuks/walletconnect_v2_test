import 'dart:convert';

import 'package:web3dart/crypto.dart';

import 'params.dart';

class WakuPublishParams {
  String topic;
  String message;
  int ttl;

  WakuPublishParams(
      {required this.topic, required this.message, this.ttl = 30});

  factory WakuPublishParams.fromJson(Map<String, dynamic> json) {
    return WakuPublishParams(
      ttl: json['id'] as int,
      message: json['jsonrpc'] as String,
      topic: json['method'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'message': bytesToHex(utf8.encode(message)),
        'ttl': ttl,
      };
}

class WakuPublishRequest {
  int? id;
  String jsonrpc;
  String method;
  WakuPublishParams? wakuParams;

  WakuPublishRequest(
      {this.id,
      this.jsonrpc = '2.0',
      this.method = 'waku_publish',
      this.wakuParams});

  factory WakuPublishRequest.fromJson(Map<String, dynamic> json) {
    return WakuPublishRequest(
      id: json['id'] as int?,
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      method: json['method'] as String? ?? 'waku_publish',
      wakuParams: json['params'] == null
          ? null
          : WakuPublishParams.fromJson(json['params'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'jsonrpc': jsonrpc,
        'method': method,
        'params': wakuParams!.toJson()
      };
}
