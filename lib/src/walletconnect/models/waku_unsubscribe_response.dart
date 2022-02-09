class WakuUnsubscribeResponse {
  int? id;
  String jsonrpc;
  bool? result;

  WakuUnsubscribeResponse({this.id, this.jsonrpc = '2.0', this.result});

  factory WakuUnsubscribeResponse.fromJson(Map<String, dynamic> json) {
    return WakuUnsubscribeResponse(
      id: json['id'] as int?,
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      result: json['result'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'jsonrpc': jsonrpc,
        'result': result,
      };
}
