import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:app_links/app_links.dart';

import '../core/nav.dart';
import '../features/auth/reset_password_screen.dart';

class DeepLinkListener extends StatefulWidget {
  final Widget child;
  const DeepLinkListener({super.key, required this.child});

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  Uri? _lastHandled;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Cold start
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handle(initial);

    // Warm start
    _sub = _appLinks.uriLinkStream.listen((uri) {
      _handle(uri);
    }, onError: (_) {});
  }

  void _handle(Uri uri) {
    if (_lastHandled == uri) return;
    _lastHandled = uri;

    final isReset = uri.host == 'ecopulse.reimii.com' &&
        uri.path.startsWith('/reset-password');
    if (isReset) {
      final code = uri.queryParameters['code'] ?? '';
      final email = uri.queryParameters['email'] ?? '';
      if (code.isEmpty) return;

      rootNavKey.currentState?.push(
        ResetPasswordScreen.route(code: code, email: email),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
