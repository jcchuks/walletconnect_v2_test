class WakuSubscriptionResponse {
	int? id;
	String? jsonrpc;
	bool? result;

	WakuSubscriptionResponse({this.id, this.jsonrpc, this.result});

	factory WakuSubscriptionResponse.fromJson(Map<String, dynamic> json) {
		return WakuSubscriptionResponse(
			id: json['id'] as int?,
			jsonrpc: json['jsonrpc'] as String?,
			result: json['result'] as bool?,
		);
	}



	Map<String, dynamic> toJson() => {
				'id': id,
				'jsonrpc': jsonrpc,
				'result': result,
			};
}
