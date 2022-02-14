import 'dart:convert';
import 'dart:developer';

import 'package:app/src/walletconnect/models/app_metadata.dart';

class PairingState {
  AppMetadata? metadata;

  PairingState({this.metadata});

  factory PairingState.fromJson(Map<String, dynamic>? json) {
    log(jsonEncode(json));
    return PairingState(
      metadata: AppMetadata.fromJson(json?['metadata']),
    );
  }

  Map<String, dynamic> toJson() => {
        'metadata': metadata!.toJson(),
      };
}
