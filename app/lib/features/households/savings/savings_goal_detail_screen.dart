import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../api/dio.dart';

double _asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
  return 0;
}

String _fmtNumber(BuildContext context, double n, {int min = 2, int max = 2}) {
  final locale = Localizations.localeOf(context).toString();
  final f = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = min
    ..maximumFractionDigits = max;
  return f.format(n);
}

String _fmtDate(BuildContext context, DateTime d) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMd(locale).format(d.toLocal());
}

class SavingsGoalDetailScreen extends ConsumerStatefulWidget {
  final String householdId;
  final String goalId;
  final String? goalName;
  const SavingsGoalDetailScreen({
    super.key,
    required this.householdId,
    required this.goalId,
    this.goalName,
  });

  @override
  ConsumerState<SavingsGoalDetailScreen> createState() =>
      _SavingsGoalDetailScreenState();
}

class _SavingsGoalDetailScreenState
    extends ConsumerState<SavingsGoalDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _summary;
  List<dynamic> _txns = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);
    try {
      final sum = await dio.get(
        '/households/${widget.householdId}/savings-goals/${widget.goalId}/summary',
      );
      final txs = await dio.get(
        '/households/${widget.householdId}/savings-goals/${widget.goalId}/txns',
      );
      setState(() {
        _summary = Map<String, dynamic>.from(sum.data as Map);
        _txns = (txs.data as List).toList();
      });
    } catch (e) {
      if (mounted) {
        final s = S.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.errorLoadingGoal)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addTxn({required bool deposit}) async {
    final s = S.of(context);
    final ctrl = TextEditingController();
    final note = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(deposit ? s.addDepositTitle : s.registerWithdrawalTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: s.amountLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: InputDecoration(
                labelText: s.noteOptionalLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.save),
          ),
        ],
      ),
    );

    if (ok == true) {
      final dio = ref.read(dioProvider);
      try {
        await dio.post(
          '/households/${widget.householdId}/savings-goals/${widget.goalId}/txns',
          data: {
            'type': deposit ? 'DEPOSIT' : 'WITHDRAW',
            'amount': double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0,
            if (note.text.trim().isNotEmpty) 'note': note.text.trim(),
          },
        );
        await _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                deposit ? s.depositRecordedToast : s.withdrawalRecordedToast,
              ),
            ),
          );
        }
      } on DioException catch (e) {
        final msg = e.response?.data is Map &&
                (e.response!.data as Map)['message'] != null
            ? (e.response!.data as Map)['message'].toString()
            : (e.message ?? s.errorSave);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    }
  }

  Future<void> _deleteThisGoal() async {
    final s = S.of(context);
    final name = widget.goalName ??
        _summary?['goal']?['name']?.toString() ??
        s.goalGeneric;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deleteGoalTitle),
        content: Text(s.deleteGoalConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.deleteAction),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final dio = ref.read(dioProvider);
    try {
      await dio.delete(
        '/households/${widget.householdId}/savings-goals/${widget.goalId}',
      );
      if (!mounted) return;
      Navigator.pop(context, true); // notifica borrado
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 403
          ? s.deleteGoalForbidden
          : e.response?.data is Map &&
                  (e.response!.data as Map)['message'] != null
              ? (e.response!.data as Map)['message'].toString()
              : (e.message ?? s.deleteGoalFailed);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final name = widget.goalName ??
        _summary?['goal']?['name']?.toString() ??
        s.goalGeneric;
    final saved = _asDouble(_summary?['saved']);
    final target = _asDouble(_summary?['target']);
    final pct = _asDouble(_summary?['progress']).clamp(0, 100).toDouble();

    DateTime? deadline;
    final dRaw = _summary?['goal']?['deadline'];
    if (dRaw is String) deadline = DateTime.tryParse(dRaw);
    if (dRaw is DateTime) deadline = dRaw;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.savingsGoalTitle(name)),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: s.refreshTooltip,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _deleteThisGoal,
            tooltip: s.deleteGoalTitle,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      floatingActionButton: Wrap(
        spacing: 12,
        children: [
          FloatingActionButton.extended(
            onPressed: () => _addTxn(deposit: true),
            icon: const Icon(Icons.add),
            label: Text(s.depositAction),
          ),
          FloatingActionButton.extended(
            onPressed: () => _addTxn(deposit: false),
            icon: const Icon(Icons.remove),
            label: Text(s.withdrawalAction),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: target > 0
                              ? (saved / target).clamp(0, 1).toDouble()
                              : 0,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.progressTriple(
                            _fmtNumber(context, saved),
                            _fmtNumber(context, target),
                            _fmtNumber(context, pct, min: 0, max: 0),
                          ),
                        ),
                        if (deadline != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            s.deadlineLabel(_fmtDate(context, deadline)),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.savingsMovementsTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_txns.isEmpty) Text(s.noSavingsTransactions),
                ..._txns.map((t) {
                  final isDep = t['type'] == 'DEPOSIT';
                  final amt = _asDouble(t['amount']);
                  DateTime? dt;
                  final raw = t['occursAt'];
                  if (raw is String) dt = DateTime.tryParse(raw);
                  if (raw is DateTime) dt = raw;
                  final when =
                      dt != null ? _fmtDate(context, dt.toLocal()) : '';

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          isDep ? Icons.trending_up : Icons.trending_down,
                        ),
                      ),
                      title: Text(isDep ? s.depositAction : s.withdrawalAction),
                      subtitle: Text([
                        when,
                        if ((t['note'] ?? '').toString().isNotEmpty)
                          t['note'].toString(),
                      ].join('  •  ')),
                      trailing: Text(
                        (isDep ? '+' : '-') +
                            _fmtNumber(context, amt, min: 2, max: 2),
                        style: TextStyle(
                          color: isDep ? Colors.teal : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 72),
              ],
            ),
    );
  }
}
