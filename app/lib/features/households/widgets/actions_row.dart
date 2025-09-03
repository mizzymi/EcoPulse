import 'package:flutter/material.dart';

import '../members/household_members_screen.dart';

class ActionsRow extends StatelessWidget {
  final String householdId;
  final String? householdName;

  final VoidCallback onOpenSavingsGoals;
  final VoidCallback onOpenQuickSavingsDeposit;
  final VoidCallback onOpenInvite;
  final VoidCallback onOpenSettings;
  final VoidCallback onRefresh;

  const ActionsRow({
    super.key,
    required this.householdId,
    required this.householdName,
    required this.onOpenSavingsGoals,
    required this.onOpenQuickSavingsDeposit,
    required this.onOpenInvite,
    required this.onOpenSettings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final name = householdName ?? 'Casa';
    return Row(
      children: [
        IconButton(
          tooltip: 'Ahorro',
          onPressed: onOpenSavingsGoals,
          icon: const Icon(Icons.list_alt),
        ),
        IconButton(
          tooltip: 'Ingreso ahorro',
          onPressed: onOpenQuickSavingsDeposit,
          icon: const Icon(Icons.savings),
        ),
        IconButton(
          tooltip: 'Generar código',
          onPressed: onOpenInvite,
          icon: const Icon(Icons.qr_code_2),
        ),
        IconButton(
          tooltip: 'Miembros',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HouseholdMembersScreen(
                  householdId: householdId,
                  householdName: name,
                ),
              ),
            );
          },
          icon: const Icon(Icons.group),
        ),
        IconButton(
          tooltip: 'Configurar',
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings),
        ),
        IconButton(
          tooltip: 'Refrescar',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
        const Spacer(),
      ],
    );
  }
}
