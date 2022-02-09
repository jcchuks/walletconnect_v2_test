class SessionState {
  List<dynamic>? accounts;

  SessionState({this.accounts});

  factory SessionState.fromJson(Map<String, dynamic> json) => SessionState(
        accounts: json['accounts'] as List<dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'accounts': accounts,
      };
}
