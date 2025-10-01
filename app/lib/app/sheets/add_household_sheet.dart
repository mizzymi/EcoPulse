/// add_household_sheet.dart
/// --------------------------------------------
/// Hoja inferior (bottom sheet) con accesos rápidos:
/// - Crear hogar (y navegar al detalle si procede).
/// - Unirse por código.
/// - Al cerrar cada flujo, invalida el provider del carrusel para refrescar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/households/create_household_screen.dart';
import '../../features/households/household_detail_screen.dart';
import '../../features/households/join_household_screen.dart';
import '../../features/households/providers/household_summaries_provider.dart';
import '../../l10n/l10n.dart';

Future<void> openAddHouseholdSheet(BuildContext ctx, WidgetRef ref) async {
  final s = S.of(ctx);
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: false,
    backgroundColor: Theme.of(ctx).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(.12),
                child: const Icon(Icons.add_home_outlined, color: Colors.green),
              ),
              title: Text(s.createAccount),
              onTap: () async {
                Navigator.pop(ctx);
                final created = await Navigator.push<Map<String, dynamic>?>(
                  ctx,
                  MaterialPageRoute(
                      builder: (_) => const CreateHouseholdScreen()),
                );
                if (created == null) return;

                ref.invalidate(householdPreviewsProvider);

                final messenger = ScaffoldMessenger.of(ctx);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      s.createdAccount(created['name']?.toString() ?? ''),
                    ),
                  ),
                );

                final id = created['id']?.toString();
                final name = created['name']?.toString();
                if (id != null) {
                  // ignore: use_build_context_synchronously
                  await Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => HouseholdDetailScreen(
                        householdId: id,
                        householdName: name,
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(.12),
                child:
                    const Icon(Icons.meeting_room_outlined, color: Colors.blue),
              ),
              title: Text(s.joinAccountByCode),
              onTap: () async {
                Navigator.pop(ctx);
                await Navigator.push(
                  ctx,
                  MaterialPageRoute(
                      builder: (_) => const JoinHouseholdScreen()),
                );
                ref.invalidate(householdPreviewsProvider);
              },
            ),
            const SizedBox(height: 70),
          ],
        ),
      );
    },
  );
}
