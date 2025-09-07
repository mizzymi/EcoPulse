import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../members/household_members_screen.dart';
import 'trends/household_movements_chart_screen.dart';

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
    final s = S.of(context);
    final name = householdName ?? s.accountGenericLower;

    return Row(
      children: [
        IconButton(
          tooltip: s.savingsTooltip,
          onPressed: onOpenSavingsGoals,
          icon: const Icon(Icons.list_alt),
        ),
        IconButton(
          tooltip: s.quickSavingsDepositTooltip,
          onPressed: onOpenQuickSavingsDeposit,
          icon: const Icon(Icons.savings),
        ),
        IconButton(
          tooltip: s.generateCodeTooltip,
          onPressed: onOpenInvite,
          icon: const Icon(Icons.qr_code_2),
        ),
        IconButton(
          tooltip: s.membersTooltip,
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
          tooltip: s.settingsTooltip,
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings),
        ),
        IconButton(
          tooltip: s.movementsChartTooltip,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HouseholdMovementsChartScreen(
                  householdId: householdId,
                  householdName: name,
                ),
              ),
            );
          },
          icon: const Icon(Icons.multiline_chart),
        ),
        IconButton(
          tooltip: s.refreshTooltip,
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
        const Spacer(),
      ],
    );
  }
}
