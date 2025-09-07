import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../api/dio.dart';
import 'savings_goal_detail_screen.dart';

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

class SavingsGoalsScreen extends ConsumerStatefulWidget {
  final String householdId;
  final String? householdName;
  const SavingsGoalsScreen({
    super.key,
    required this.householdId,
    this.householdName,
  });

  @override
  ConsumerState<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends ConsumerState<SavingsGoalsScreen> {
  bool _loading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);
    try {
      final res =
          await dio.get('/households/${widget.householdId}/savings-goals');
      setState(() => _items = (res.data as List).toList());
    } on DioException catch (e) {
      final s = S.of(context);
      final msg = e.response?.data is Map &&
              (e.response!.data as Map)['message'] != null
          ? (e.response!.data as Map)['message'].toString()
          : (e.message ?? s.errorLoadingGoals);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreate() async {
    final s = S.of(context);
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    DateTime? deadline;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(s.newSavingsGoalTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: s.nameLabel,
                  border: const OutlineInputBorder(),
                ),
                controller: nameCtrl,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: s.targetAmountLabel,
                  border: const OutlineInputBorder(),
                ),
                controller: targetCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deadline == null
                          ? s.noDeadlineLabel
                          : s.deadlineLabel(_fmtDate(context, deadline!)),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final pick = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                        initialDate:
                            DateTime.now().add(const Duration(days: 30)),
                      );
                      if (pick != null) {
                        setStateDialog(() => deadline = pick);
                      }
                    },
                    icon: const Icon(Icons.event),
                    label: Text(s.chooseDateButton),
                  ),
                ],
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
              child: Text(s.createAction),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final dio = ref.read(dioProvider);
      try {
        await dio.post(
          '/households/${widget.householdId}/savings-goals',
          data: {
            'name': nameCtrl.text.trim(),
            'target':
                double.tryParse(targetCtrl.text.replaceAll(',', '.')) ?? 0,
            if (deadline != null) 'deadline': deadline!.toIso8601String(),
          },
        );
        await _load();
      } on DioException catch (e) {
        final msg = e.response?.data is Map &&
                (e.response!.data as Map)['message'] != null
            ? (e.response!.data as Map)['message'].toString()
            : (e.message ?? s.createGoalFailed);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    }
  }

  Future<void> _deleteGoal(Map<String, dynamic> g) async {
    final s = S.of(context);
    final id = g['id'].toString();
    final name = g['name']?.toString() ?? s.goalGeneric;

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
      await dio.delete('/households/${widget.householdId}/savings-goals/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.goalDeletedToast(name))),
      );
      await _load();
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
    final name = widget.householdName ?? s.accountGenericLower;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.savingsTitle(name)),
        actions: [
          IconButton(
            onPressed: _load,
            tooltip: s.refreshTooltip,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: Text(s.newGoalFab),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(s.noGoalsEmptyState))
              : ListView.builder(
                  itemCount: _items.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, i) {
                    final g = Map<String, dynamic>.from(_items[i] as Map);
                    final saved = _asDouble(g['saved']);
                    final target = _asDouble(g['target']);
                    final pct =
                        _asDouble(g['progress']).clamp(0, 100).toDouble();

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.savings)),
                        title: Text(g['name']?.toString() ?? s.goalGeneric),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                          ],
                        ),
                        onTap: () async {
                          final deleted = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SavingsGoalDetailScreen(
                                householdId: widget.householdId,
                                goalId: g['id'].toString(),
                                goalName: g['name']?.toString(),
                              ),
                            ),
                          );
                          await _load();
                          if (deleted == true && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.goalDeletedSimple)),
                            );
                          }
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'delete') _deleteGoal(g);
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline),
                                  const SizedBox(width: 8),
                                  Text(s.deleteAction),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
