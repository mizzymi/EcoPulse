import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../savings/savings_goals_screen.dart';

// Devuelve true si se registró un depósito, false/null si no.
Future<bool?> showQuickSavingsDepositDialog({
  required BuildContext context,
  required Dio dio,
  required String householdId,
  required String householdName,
}) async {
  // 1) Traer metas
  List<dynamic> goals = [];
  try {
    final res = await dio.get('/households/$householdId/savings-goals');
    goals = (res.data as List).toList();
  } on DioException catch (e) {
    final msg =
        e.response?.data is Map && (e.response!.data as Map)['message'] != null
            ? (e.response!.data as Map)['message'].toString()
            : (e.message ?? 'No se pudieron cargar las metas');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
    return false;
  }

  // 2) Si no hay metas, ofrecer crear
  if (goals.isEmpty) {
    final go = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sin metas de ahorro'),
        content:
            const Text('Crea primero una meta para poder registrar depósitos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Crear meta')),
        ],
      ),
    );
    if (go == true && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SavingsGoalsScreen(
            householdId: householdId,
            householdName: householdName,
          ),
        ),
      );
    }
    return false;
  }

  // 3) Diálogo de depósito
  String? selectedGoalId = goals.first['id'].toString();
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  bool saving = false;

  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setStateDialog) => AlertDialog(
        title: const Text('Ingreso a ahorro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedGoalId,
              items: [
                ...goals.map((g) {
                  final name = g['name']?.toString() ?? 'Meta';
                  return DropdownMenuItem(
                    value: g['id'].toString(),
                    child: Text(name),
                  );
                }),
              ],
              onChanged: (v) => setStateDialog(() => selectedGoalId = v),
              decoration: const InputDecoration(
                labelText: 'Meta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importe',
                hintText: 'Ej. 50.00',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: saving ? null : () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: saving
                ? null
                : () async {
                    final amt =
                        double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                    if (amt == null || amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Importe inválido')),
                      );
                      return;
                    }
                    if (selectedGoalId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecciona una meta')),
                      );
                      return;
                    }
                    setStateDialog(() => saving = true);
                    try {
                      await dio.post(
                        '/households/$householdId/savings-goals/$selectedGoalId/txns',
                        data: {
                          'type': 'DEPOSIT',
                          'amount': amt,
                          if (noteCtrl.text.trim().isNotEmpty)
                            'note': noteCtrl.text.trim(),
                        },
                      );
                      if (context.mounted) Navigator.pop(context, true);
                    } on DioException catch (e) {
                      final msg = e.response?.data is Map &&
                              (e.response!.data as Map)['message'] != null
                          ? (e.response!.data as Map)['message'].toString()
                          : (e.message ?? 'No se pudo registrar el depósito');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(msg)));
                      }
                    } finally {
                      if (context.mounted) setStateDialog(() => saving = false);
                    }
                  },
            icon: saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );

  if (ok == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Depósito de ahorro registrado')));
  }

  return ok;
}
