import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/app_locale_provider.dart';
import 'providers/auth_token_provider.dart';
import 'app/app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString('appLocaleCode');
  if (code != null && code != 'system') {
    container.read(appLocaleProvider.notifier).state = Locale(code);
  }

  await container.read(loadAuthTokenProvider.future);

  runApp(UncontrolledProviderScope(
    container: container,

    child: const EcoPulseApp(),
  ));
}
