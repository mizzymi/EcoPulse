/// app.dart
/// --------------------------------------------
/// Define el widget raíz `EcoPulseApp`.
/// - Configura MaterialApp (tema, localización, título).
/// - Decide si muestra `AuthScreen` o `HomeScaffold` según el token.
/// - Instancia `WsNotificationsListener` para mostrar toasts de eventos WS.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import './widgets/ws_notifications_listener.dart';
import './pages/home_scaffold.dart';

import '../../providers/app_locale_provider.dart';
import '../../providers/auth_token_provider.dart';
import '../../l10n/l10n.dart';
import '../../ui/theme/app_theme.dart';
import '../../api/dio.dart'; // fuerza creación de Dio con el token
import '../../features/auth/auth_screen.dart';

class EcoPulseApp extends ConsumerWidget {
  const EcoPulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Asegura que Dio se construye con el token actual (y actualiza si cambia).
    ref.watch(dioProvider);

    final token = ref.watch(authTokenProvider);
    final appLocale = ref.watch(appLocaleProvider);

    return MaterialApp(
      locale: appLocale,
      onGenerateTitle: (ctx) => S.of(ctx).appTitle,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      title: 'EcoPulse',
      theme: AppTheme.light,
      home: token == null
          ? const AuthScreen()
          : const WsNotificationsListener(
              child: HomeScaffold(),
            ),
    );
  }
}
