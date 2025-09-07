import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import '../savings/savings_goals_screen.dart';

// Devuelve true si se registró un depósito, false/null si no.
Future<bool?> showQuickSavingsDepositDialog({
  required BuildContext context,
  required Dio dio,
  required String householdId,
  required String householdName,
}) async {
  final s = S.of(context);

  // 1) Traer metas
  List<dynamic> goals = [];
  try {
    final res = await dio.get('/households/$householdId/savings-goals');
    goals = (res.data as List).toList();
  } on DioException catch (e) {
    final msg =
        e.response?.data is Map && (e.response!.data as Map)['message'] != null
            ? (e.response!.data as Map)['message'].toString()
            : (e.message ?? s.errorLoadingGoals);
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
        title: Text(s.noSavingsGoalsTitle),
        content: Text(s.createGoalFirstMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.createAction),
          ),
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
        title: Text(s.quickSavingsDepositTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedGoalId,
              items: [
                ...goals.map((g) {
                  final name = g['name']?.toString() ?? s.goalGeneric;
                  return DropdownMenuItem(
                    value: g['id'].toString(),
                    child: Text(name),
                  );
                }),
              ],
              onChanged: (v) => setStateDialog(() => selectedGoalId = v),
              decoration: InputDecoration(
                labelText: s.goalLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: s.amountLabel,
                hintText: s.amountHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: s.noteOptionalLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton.icon(
            onPressed: saving
                ? null
                : () async {
                    final amt =
                        double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                    if (amt == null || amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.invalidAmountToast)),
                      );
                      return;
                    }
                    if (selectedGoalId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.selectGoalFirst)),
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
                          : (e.message ?? s.depositRegisterFailed);
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(s.save),
          ),
        ],
      ),
    ),
  );

  if (ok == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.depositRecordedToast)),
    );
  }

  return ok;
}
