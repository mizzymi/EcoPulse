import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_locale_provider.dart';

Future<void> showLanguagePicker(BuildContext context, WidgetRef ref) async {
  final localeNow = ref.read(appLocaleProvider);
  String value = localeNow?.languageCode ?? 'system';

  Future<void> setLang(String code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == 'system') {
      ref.read(appLocaleProvider.notifier).state = null;
      await prefs.setString('appLocaleCode', 'system');
    } else {
      ref.read(appLocaleProvider.notifier).state = Locale(code);
      await prefs.setString('appLocaleCode', code);
    }
  }

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Idioma / Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              value: 'system',
              groupValue: value,
              onChanged: (v) => setState(() => value = v!),
              title: const Text('Usar idioma del sistema'),
              subtitle: const Text('Follow system language'),
            ),
            RadioListTile<String>(
              value: 'es',
              groupValue: value,
              onChanged: (v) => setState(() => value = v!),
              title: const Text('Español'),
            ),
            RadioListTile<String>(
              value: 'ca',
              groupValue: value,
              onChanged: (v) => setState(() => value = v!),
              title: const Text('Català'),
            ),
            RadioListTile<String>(
              value: 'gl',
              groupValue: value,
              onChanged: (v) => setState(() => value = v!),
              title: const Text('Galego'),
            ),
            RadioListTile<String>(
              value: 'en',
              groupValue: value,
              onChanged: (v) => setState(() => value = v!),
              title: const Text('English'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await setLang(value);
              if (context.mounted) Navigator.pop(ctx);
              // MaterialApp se reconstruye y cambia el idioma solo.
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    ),
  );
}
