import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/l10n.dart';
import '../../ui/theme/app_theme.dart';
import '../../../features/settings/language_picker.dart';

class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  // Alto un poco mayor para que respire como en el mock
  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    // Colores (usa los tuyos si los tienes en el theme)
    const hero = Color(0xFFCFEBC7); // fondo barra
    final primary = T.cPrimary;     // verde de marca

    final langName = _currentLanguageLabel(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: hero,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Logo SVG
              SvgPicture.asset(
                'lib/assets/app_icon.svg', // si lo moviste: 'assets/app_icon.svg'
                width: 28,
                height: 28,
                colorFilter: ColorFilter.mode(primary, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),

              // Título
              Text(
                s.appTitle, // "EcoPulse"
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: primary,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),

              // Selector de idioma como texto + chevron
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => showLanguagePicker(context, ref),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
            ],
          ),
        ),
      ),
    );
  }

  // Nombre legible del idioma según locale actual
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
