/// app_topbar.dart
/// --------------------------------------------
/// Barra superior reutilizable con:
/// - Icono SVG + título de la app.
/// - Botón para abrir el selector de idiomas.
///
/// Se usa dentro de `HomeScaffold`.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../features/settings/language_picker.dart';

class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
            children: [
              SvgPicture.asset(
                'lib/assets/app_icon.svg',
                width: 30,
                height: 30,
                colorFilter: ColorFilter.mode(
                  T.cPrimary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.appTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: s.changeLanguageTooltip,
                icon: const Icon(Icons.language),
                onPressed: () => showLanguagePicker(context, ref),
              ),
            ],
          ),
        ),
    );
  }
}
