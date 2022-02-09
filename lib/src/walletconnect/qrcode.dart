import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WCQRcode extends StatefulWidget {
  final String wcUri;

  const WCQRcode({Key? key, required this.wcUri}) : super(key: key);

  @override
  State<WCQRcode> createState() => _WCQRcodeState();
}

class _WCQRcodeState extends State<WCQRcode> {
  @override
  Widget build(BuildContext context) {
    return QrImage(
      data: widget.wcUri,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xff128760),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.circle,
        color: Color(0xff1a5441),
      ),
      // size: 320.0,
      embeddedImageStyle: QrEmbeddedImageStyle(
        size: const Size.square(60),
      ),
    );
  }
}
