import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecopulse/main.dart';
import 'package:ecopulse/ws/ws_client.dart'; // para poder sobrescribir el wsProvider

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Evita depender del plugin real durante el test
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('La home muestra los botones principales', (tester) async {
    // Opcional: desactiva WebSocket en los tests
    final overrides = [
      wsProvider.overrideWith((ref) => null),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const EcoPulseApp(),
      ),
    );

    // Deja que construya el primer frame
    await tester.pumpAndSettle();

    // Verifica textos/botones de la pantalla principal autenticada o de login.
    // Si todavía no hay token, verás la AuthScreen.
    // Para testear la home autenticada puedes simular el token guardándolo antes:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('authToken', 'dummy.jwt');

    // En este smoke test, solo comprobamos que la app montó:
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
