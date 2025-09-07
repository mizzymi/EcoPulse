import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';

class MonthNavRow extends StatelessWidget {
  final bool viewAllMonths;
  final String monthStr;
  final bool isAtCurrentMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToggleViewAll;

  const MonthNavRow({
    super.key,
    required this.viewAllMonths,
    required this.monthStr,
    required this.isAtCurrentMonth,
    required this.onPrev,
    required this.onNext,
    required this.onToggleViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (!viewAllMonths) {
      return Row(
        children: [
          IconButton(
            tooltip: s.prevMonthTooltip,
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Center(
              child: Text(
                monthStr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            tooltip: s.nextMonthTooltip,
            onPressed: isAtCurrentMonth ? null : onNext,
            icon: const Icon(Icons.chevron_right),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: viewAllMonths
                ? s.seeCurrentMonthTooltip
                : s.seeAllMonthsTooltip,
            onPressed: onToggleViewAll,
            icon: Icon(
              viewAllMonths ? Icons.filter_1 : Icons.calendar_view_month,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const SizedBox(width: 40),
        Expanded(
          child: Center(
            child: Text(
              s.allMonthsTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: s.seeCurrentMonthTooltip,
          onPressed: onToggleViewAll,
          icon: const Icon(Icons.filter_1),
        ),
      ],
    );
  }
}
