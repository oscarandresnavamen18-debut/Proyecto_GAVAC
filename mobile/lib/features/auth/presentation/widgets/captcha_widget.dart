import 'package:flutter/material.dart';
import 'captcha_widget_stub.dart'
    if (dart.library.html) 'captcha_widget_web.dart' as platform;

class CaptchaWidget extends StatelessWidget {
  const CaptchaWidget({
    super.key,
    required this.onToken,
    this.onTokenReceived,
    this.onResetReady,
  });

  final ValueChanged<String?> onToken;
  final ValueChanged<String?>? onTokenReceived;
  final ValueChanged<VoidCallback>? onResetReady;

  @override
  Widget build(BuildContext context) {
    return platform.buildCaptchaWidget(
      onToken: onTokenReceived ?? onToken,
      onResetReady: onResetReady ?? (_) {},
    );
  }
}
