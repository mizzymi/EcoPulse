/// ws_notifications_listener.dart
/// --------------------------------------------
/// Componente invisible que:
/// - Se suscribe al `wsNotificationsProvider`.
/// - Muestra cada mensaje como SnackBar.
/// - Invalida `householdPreviewsProvider` para refrescar la UI tras eventos.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ws/ws_client.dart';
import '../../../features/households/providers/household_summaries_provider.dart';

class WsNotificationsListener extends ConsumerStatefulWidget {
  const WsNotificationsListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<WsNotificationsListener> createState() =>
      _WsNotificationsListenerState();
}

class _WsNotificationsListenerState
    extends ConsumerState<WsNotificationsListener> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    // La suscripción se crea tras el primer frame para asegurar que
    // los providers están listos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sub = ref.read(wsNotificationsProvider).listen((msg) {
        _messenger.currentState?.showSnackBar(SnackBar(content: Text(msg)));
        ref.invalidate(householdPreviewsProvider);
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _messenger,
      child: widget.child,
    );
  }
}
