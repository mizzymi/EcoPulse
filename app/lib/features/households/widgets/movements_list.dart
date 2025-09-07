import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MovementsList extends StatelessWidget {
  final List<dynamic> entries;
  final void Function(Map<String, dynamic> entry) onEdit;
  final Future<bool> Function(String entryId) onDelete; // debe devolver true si borró

  const MovementsList({
    super.key,
    required this.entries,
    required this.onEdit,
    required this.onDelete,
  });

  String _fmtAmount(BuildContext context, dynamic a, {required bool withSign}) {
    final n = (a is num) ? a.toDouble() : double.tryParse(a.toString()) ?? 0.0;
    final locale = Localizations.localeOf(context).toString();
    final f = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    final base = f.format(n.abs());
    if (!withSign) return f.format(n);
    final sign = n > 0 ? '+' : (n < 0 ? '-' : '');
    return '$sign$base';
  }

  String _fmtDate(BuildContext context, DateTime d) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).format(d);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (entries.isEmpty) {
      return Text(s.noMovementsThisMonth);
    }

    return Column(
      children: entries.map((e) {
        final isIncome = e['type'] == 'INCOME';
        final amount = _fmtAmount(context, e['amount'], withSign: true);
        final dt = DateTime.tryParse(e['occursAt']?.toString() ?? '');
        final when = dt != null ? _fmtDate(context, dt.toLocal()) : '';

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(isIncome ? Icons.trending_up : Icons.trending_down),
            ),
            title: Text(
              e['category']?.toString() ??
                  (isIncome ? s.incomeGeneric : s.expenseGeneric),
            ),
            subtitle: Text([
              when,
              if ((e['note'] ?? '').toString().isNotEmpty) e['note'].toString(),
            ].join('  •  ')),
            trailing: Text(
              isIncome ? amount : amount, // amount ya lleva el signo
              style: TextStyle(
                color: isIncome ? Colors.teal : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => onEdit(Map<String, dynamic>.from(e)),
            onLongPress: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(s.deleteMovementTitle),
                  content: Text(s.deleteMovementConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(s.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(s.deleteAction),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                final success = await onDelete(e['id'].toString());
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.deletedToast)),
                  );
                }
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
