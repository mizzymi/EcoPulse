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
    if (!viewAllMonths) {
      return Row(
        children: [
          IconButton(
            tooltip: 'Mes anterior',
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
            tooltip: 'Mes siguiente',
            onPressed: isAtCurrentMonth ? null : onNext,
            icon: const Icon(Icons.chevron_right),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: viewAllMonths ? 'Ver mes actual' : 'Ver todos los meses',
            onPressed: onToggleViewAll,
            icon: Icon(
                viewAllMonths ? Icons.filter_1 : Icons.calendar_view_month),
          ),
        ],
      );
    }

    return Row(
      children: [
        const SizedBox(width: 40),
        const Expanded(
          child: Center(
            child: Text(
              'Todos los meses',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Ver mes actual',
          onPressed: onToggleViewAll,
          icon: const Icon(Icons.filter_1),
        ),
      ],
    );
  }
}
