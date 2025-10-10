import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../members/household_members_screen.dart';
import 'trends/household_movements_chart_screen.dart';

class HouseholdHeaderMenu extends StatelessWidget {
  // ── Navegación de meses ──
  final String monthStr;
  final bool viewAllMonths;
  final bool isAtCurrentMonth; // ya no bloquea "siguiente", lo dejamos por compat
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToggleViewAll;

  // ── Acciones de la cuenta ──
  final String householdId;
  final String? householdName;
  final VoidCallback onOpenSavingsGoals;
  final VoidCallback onOpenQuickSavingsDeposit;
  final VoidCallback onOpenInvite;
  final VoidCallback onOpenSettings;
  final VoidCallback onRefresh;
  final VoidCallback? onDeleteHousehold;

  const HouseholdHeaderMenu({
    super.key,
    // meses
    required this.monthStr,
    required this.viewAllMonths,
    required this.isAtCurrentMonth,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onToggleViewAll,
    // acciones
    required this.householdId,
    required this.householdName,
    required this.onOpenSavingsGoals,
    required this.onOpenQuickSavingsDeposit,
    required this.onOpenInvite,
    required this.onOpenSettings,
    required this.onRefresh,
    this.onDeleteHousehold,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final name = householdName ?? s.accountGenericLower;

    return Row(
      children: [
        // ── Hamburguesa con TODO dentro ──
        PopupMenuButton<_MenuAction>(
          icon: const Icon(Icons.menu),
          tooltip: s.appTitle,
          onSelected: (action) async {
            switch (action) {
            // meses
              case _MenuAction.prevMonth:
                onPrevMonth();
                break;
              case _MenuAction.nextMonth:
                onNextMonth();
                break;
              case _MenuAction.toggleAllMonths:
                onToggleViewAll();
                break;
            // acciones
              case _MenuAction.savingsGoals:
                onOpenSavingsGoals();
                break;
              case _MenuAction.quickDeposit:
                onOpenQuickSavingsDeposit();
                break;
              case _MenuAction.invite:
                onOpenInvite();
                break;
              case _MenuAction.members:
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HouseholdMembersScreen(
                      householdId: householdId,
                      householdName: name,
                    ),
                  ),
                );
                break;
              case _MenuAction.settings:
                onOpenSettings();
                break;
              case _MenuAction.delete:
                onDeleteHousehold?.call();
                break;
              case _MenuAction.chart:
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HouseholdMovementsChartScreen(
                      householdId: householdId,
                      householdName: name,
                    ),
                  ),
                );
                break;
              case _MenuAction.refresh:
                onRefresh();
                break;
            }
          },
          itemBuilder: (ctx) => [
            // navegación mensual
            PopupMenuItem(
              value: _MenuAction.prevMonth,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.chevron_left),
                title: Text(s.prevMonthTooltip),
              ),
            ),
            PopupMenuItem(
              // ¡Ahora SIEMPRE habilitado para poder ir a meses futuros!
              value: _MenuAction.nextMonth,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.chevron_right),
                title: Text(s.nextMonthTooltip),
              ),
            ),
            PopupMenuItem(
              value: _MenuAction.toggleAllMonths,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                    viewAllMonths ? Icons.filter_1 : Icons.calendar_view_month),
                title: Text(
                  viewAllMonths
                      ? s.seeCurrentMonthTooltip
                      : s.seeAllMonthsTooltip,
                ),
              ),
            ),
            const PopupMenuDivider(),
            // acciones
            PopupMenuItem(
              value: _MenuAction.savingsGoals,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.list_alt),
                title: Text(s.savingsTooltip),
              ),
            ),
            PopupMenuItem(
              value: _MenuAction.quickDeposit,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.savings),
                title: Text(s.quickSavingsDepositTooltip),
              ),
            ),
            PopupMenuItem(
              value: _MenuAction.invite,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.qr_code_2),
                title: Text(s.generateCodeTooltip),
              ),
            ),
            PopupMenuItem(
              value: _MenuAction.members,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.group),
                title: Text(s.membersTooltip),
              ),
            ),
            PopupMenuItem(
              value: _MenuAction.settings,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.settings),
                title: Text(s.settingsTooltip),
              ),
            ),
            PopupMenuItem(
              value: _MenuAction.delete,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text(
                  s.deleteHouseholdTooltip,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: _MenuAction.chart,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.multiline_chart),
                title: Text(s.movementsChartTooltip),
              ),
            ),
            PopupMenuItem(
              value: _MenuAction.refresh,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.refresh),
                title: Text(s.refreshTooltip),
              ),
            ),
          ],
        ),

        // ── Mes visible fuera de la hamburguesa ──
        Expanded(
          child: Center(
            child: Text(
              viewAllMonths ? s.allMonthsTitle : monthStr,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Espaciador para compensar el icono de la izquierda
        const SizedBox(width: 48),
      ],
    );
  }
}

enum _MenuAction {
  // meses
  prevMonth,
  nextMonth,
  toggleAllMonths,
  // acciones
  savingsGoals,
  quickDeposit,
  invite,
  members,
  settings,
  delete,
  chart,
  refresh,
}
