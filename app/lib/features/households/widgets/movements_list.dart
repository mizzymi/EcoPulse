import 'package:flutter/material.dart';

class MovementsList extends StatelessWidget {
  final List<dynamic> entries;
  final void Function(Map<String, dynamic> entry) onEdit;
  final Future<bool> Function(String entryId)
      onDelete; // debe devolver true si borró

  const MovementsList({
    super.key,
    required this.entries,
    required this.onEdit,
    required this.onDelete,
  });

  String _fmtAmount(dynamic a) {
    final n = (a is num) ? a : double.tryParse(a.toString()) ?? 0;
    return n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text('No hay movimientos en este mes.');
    }

    return Column(
      children: entries.map((e) {
        final isIncome = e['type'] == 'INCOME';
        final amount = _fmtAmount(e['amount']);
        final dt = DateTime.tryParse(e['occursAt']?.toString() ?? '');
        final when = dt != null
            ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'
            : '';

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(isIncome ? Icons.trending_up : Icons.trending_down),
            ),
            title: Text(
                e['category']?.toString() ?? (isIncome ? 'Ingreso' : 'Gasto')),
            subtitle: Text([
              when,
              if ((e['note'] ?? '').toString().isNotEmpty) e['note'].toString()
            ].join('  •  ')),
            trailing: Text(
              (isIncome ? '+' : '-') + amount,
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
                  title: const Text('Eliminar movimiento'),
                  content: const Text('¿Seguro que quieres eliminarlo?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Eliminar')),
                  ],
                ),
              );
              if (ok == true) {
                final success = await onDelete(e['id'].toString());
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Eliminado')));
                }
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
