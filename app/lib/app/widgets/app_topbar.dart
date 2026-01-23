// app_topbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/l10n.dart';
import '../../core/app_reloader.dart';
import '../../ui/theme/app_theme.dart';
import '../../../features/settings/language_picker.dart';
import '../../../providers/app_reload_provider.dart'; // <--- NUEVO

class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  // Un poco más alto para encajar la segunda fila
  @override
  Size get preferredSize => const Size.fromHeight(96); // <--- CAMBIO

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    const hero = T.cBg;
    final primary = T.cPrimary;

    final langName = _currentLanguageLabel(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Container(
          height: 102,
          decoration: BoxDecoration(
            color: hero,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Fila superior (igual que antes) ----
              Row(
                children: [
                  Image.asset(
                    'lib/assets/ReimiiLogo.png',
                    height: 28,
                    width: 70,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    semanticLabel: 'Reimii',
                  ),
                  const Spacer(),
                  Text(
                    s.appTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Impact',
                      color: primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Spacer(),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => showLanguagePicker(context, ref),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      child: Row(
                        children: [
                          Text(
                            langName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_more, size: 18, color: Colors.black87),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Reload',
                    icon: const Icon(Icons.refresh),
                    color: primary,
                    onPressed: () => AppReloader.restart(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _currentLanguageLabel(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    switch (code) {
      case 'es':
        return 'Español';
      case 'ca':
        return 'Català';
      case 'gl':
        return 'Galego';
      default:
        return 'English';
    }
  }
}
