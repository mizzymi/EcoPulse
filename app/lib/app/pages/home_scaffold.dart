/// home_scaffold.dart
/// --------------------------------------------
/// Estructura principal de la pantalla "home" autenticada:
/// - AppBar reutilizable (`AppTopBar`).
/// - Contenido centrado (CTA para crear/unirse y carrusel de hogares).
/// - Botón de logout usando `authTokenControllerProvider`.
/// - Abre el bottom sheet `AddHouseholdSheet`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../features/home/widgets/add_house_cta.dart';
import '../../../features/home/widgets/household_carousel.dart';
import '../../../providers/auth_token_provider.dart';
import '../../ui/theme/app_theme.dart';
import '../sheets/add_household_sheet.dart';
import '../widgets/app_topbar.dart';

class HomeScaffold extends ConsumerWidget {
  const HomeScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    return Scaffold(
      appBar: const AppTopBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              AddHouseCta(
                onTap: () => openAddHouseholdSheet(context, ref),
              ),
              const SizedBox(height: 16),
              const HouseholdCarousel(),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async { await ref.read(authTokenControllerProvider).clear(); },
                icon: const Icon(Icons.logout),
                label: Text(s.logout),
                style: TextButton.styleFrom(
                  foregroundColor: T.cPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
