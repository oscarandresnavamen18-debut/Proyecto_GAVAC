// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

const _siteKey = String.fromEnvironment(
  'RECAPTCHA_SITE_KEY',
  defaultValue: '6LecqfYtAAAAAKLiGYaf-rWvhp_dKwCDgOMWBkGB',
);
const _viewType = 'gavac-recaptcha-v2';

@JS('gavacRenderRecaptcha')
external void _renderRecaptcha(int viewId, String siteKey);

@JS('gavacResetRecaptcha')
external void _resetRecaptcha(int viewId);

Widget buildCaptchaWidget({
  required ValueChanged<String?> onToken,
  required ValueChanged<VoidCallback> onResetReady,
}) {
  if (_siteKey.isEmpty) {
    return const Text(
      'Falta RECAPTCHA_SITE_KEY. Compila usando --dart-define.',
      style: TextStyle(color: Colors.red),
    );
  }

  return _CaptchaView(
    onToken: onToken,
    onResetReady: onResetReady,
  );
}

class _CaptchaView extends StatefulWidget {
  const _CaptchaView({
    required this.onToken,
    required this.onResetReady,
  });

  final ValueChanged<String?> onToken;
  final ValueChanged<VoidCallback> onResetReady;

  @override
  State<_CaptchaView> createState() => _CaptchaViewState();
}

class _CaptchaViewState extends State<_CaptchaView> {
  static int _nextId = 0;

  late final int _id;
  late final String _type;
  late final html.DivElement _element;

  late final html.EventListener _tokenListener;
  late final html.EventListener _expiredListener;
  late final html.EventListener _errorListener;

  bool _disposed = false;

  @override
  void initState() {
    super.initState();

    _id = _nextId++;
    _type = '$_viewType-$_id';

    _element = html.DivElement()
      ..id = 'gavac-recaptcha-$_id'
      ..style.width = '304px'
      ..style.height = '78px'
      ..style.display = 'block';

    ui_web.platformViewRegistry.registerViewFactory(
      _type,
      (int viewId) => _element,
    );

    _tokenListener = (html.Event event) {
      final data = _readDetail(event);
      if (data == null || data['viewId'].toString() != '$_id') return;
      final token = data['token'];
      if (token is String && token.isNotEmpty && !_disposed) {
        widget.onToken(token);
      }
    };

    _expiredListener = (html.Event event) {
      final data = _readDetail(event);
      if (data != null &&
          data['viewId'].toString() == '$_id' &&
          !_disposed) {
        widget.onToken(null);
      }
    };

    _errorListener = (html.Event event) {
      final data = _readDetail(event);
      if (data != null &&
          data['viewId'].toString() == '$_id' &&
          !_disposed) {
        widget.onToken(null);
      }
    };

    html.window.addEventListener('gavacRecaptchaToken', _tokenListener);
    html.window.addEventListener('gavacRecaptchaExpired', _expiredListener);
    html.window.addEventListener('gavacRecaptchaError', _errorListener);

    widget.onResetReady(reset);
  }

  Map<String, dynamic>? _readDetail(html.Event event) {
    try {
      if (event is! html.CustomEvent) return null;
      final dynamic raw = event.detail;

      if (raw is String) {
        final decoded = jsonDecode(raw);
        return decoded is Map<String, dynamic> ? decoded : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _render(int _) {
    try {
      _renderRecaptcha(_id, _siteKey);
    } catch (error) {
      debugPrint('Error al cargar reCAPTCHA: $error');
    }
  }

  void reset() {
    try {
      _resetRecaptcha(_id);
    } catch (error) {
      debugPrint('Error al reiniciar reCAPTCHA: $error');
    }
    widget.onToken(null);
  }

  @override
  void dispose() {
    _disposed = true;
    html.window.removeEventListener('gavacRecaptchaToken', _tokenListener);
    html.window.removeEventListener('gavacRecaptchaExpired', _expiredListener);
    html.window.removeEventListener('gavacRecaptchaError', _errorListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 304,
      height: 85,
      child: HtmlElementView(
        viewType: _type,
        onPlatformViewCreated: _render,
      ),
    );
  }
}
