// -----------------------------------------------------------------------------
// Pantalla principal de detalle de la cuenta (Household).
//
// Incluye:
//   • Gastos previstos (planned) y Gastos fijos (recurring)
//   • Switch para incluir previstos+fijos en el resumen (forecast)
//   • Acciones para “asentar” (settle/post), editar y borrar previstos/fijos
//   • Navegación a meses futuros (con resumen sintético si el BE no devuelve datos)
//   • EXPANSIÓN LOCAL de fijos por mes cuando el BE devuelve solo definiciones
//
// Backend esperado:
//   GET  /households/:id/entries
//   GET  /households/:id/summary?month=YYYY-MM
//   GET  /households/:id/planned?month=YYYY-MM
//   GET  /households/:id/recurring?month=YYYY-MM   (si vacío, hacemos fallback a GET /recurring)
//   POST /households/:id/planned
//   PATCH /households/:id/planned/:plannedId
//   DELETE /households/:id/planned/:plannedId
//   POST /households/:id/planned/:plannedId/settle
//   POST /households/:id/recurring
//   PATCH /households/:id/recurring/:recurringId
//   DELETE /households/:id/recurring/:recurringId
//   POST /households/:id/recurring/:recurringId/post
// -----------------------------------------------------------------------------

import 'package:dio/dio.dart';
import 'package:ecopulse/features/households/widgets/actions_row.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/dio.dart';
import '../../ui/theme/app_theme.dart';

// Sheets
import '../../ui/widgets/add_fixed_expense_sheet.dart';
import '../../ui/widgets/add_planned_expense_sheet.dart';

// Pantallas relacionadas
import 'generate_invite_screen.dart';
import 'savings/savings_goals_screen.dart';

// UI extraídas a widgets/dialogs propios
import 'widgets/summary_card.dart';
import 'widgets/movements_list.dart';
import 'widgets/add_entry_sheet.dart';
import 'dialogs/rename_household_dialog.dart';
import 'dialogs/savings_deposit_dialog.dart';

class HouseholdDetailScreen extends ConsumerStatefulWidget {
  final String householdId;
  final String? householdName;

  const HouseholdDetailScreen({
    super.key,
    required this.householdId,
    this.householdName,
  });

  @override
  ConsumerState<HouseholdDetailScreen> createState() =>
      _HouseholdDetailScreenState();
}

class _HouseholdDetailScreenState extends ConsumerState<HouseholdDetailScreen> {
  bool _loading = true;

  List<dynamic> _entries = [];
  Map<String, dynamic>? _summary;

  bool _viewAllMonths = false;
  bool _deleting = false;

  // Previstos / Fijos
  List<dynamic> _planned = [];
  List<dynamic> _fixedRaw = []; // puede traer instancias del mes o definiciones
  bool _includeForecast = true;

  // Todos los meses
  List<Map<String, dynamic>> _allSummaries = [];

  String? _householdNameState;

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _householdNameState = widget.householdName;
    _refresh();
  }

  String get _monthStr =>
      '${_month.year.toString().padLeft(4, '0')}-${_month.month.toString().padLeft(2, '0')}';

  (DateTime from, DateTime to) _rangeOfMonth(DateTime d) {
    final from = DateTime(d.year, d.month, 1, 0, 0, 0);
    final to = DateTime(d.year, d.month + 1, 0, 23, 59, 59, 999);
    return (from, to);
  }

  // ==== Utilidades meses futuros y resumen vacío ====
  bool _isFutureMonth(DateTime m) {
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    final cand = DateTime(m.year, m.month);
    return cand.isAfter(now);
  }

  Map<String, dynamic> _emptySummaryFor(String ym) => {
    'month': ym,
    'openingBalance': 0,
    'income': 0,
    'expense': 0,
    'net': 0,
    'closingBalance': 0,
    '_synthetic': true,
  };

  // ==== EXPANSIÓN LOCAL DE FIJOS (cuando el BE no los expande por mes) ====
  // Detecta si el item es una instancia concreta (tiene occursAt en el mes)
  bool _isInstanceForMonth(Map e, DateTime month) {
    final occursAtStr = e['occursAt']?.toString();
    if (occursAtStr == null || occursAtStr.isEmpty) return false;
    final dt = DateTime.tryParse(occursAtStr);
    if (dt == null) return false;
    return dt.year == month.year && dt.month == month.month;
  }

  // Parse RRULE MUY SIMPLE: soporta "FREQ=MONTHLY;BYMONTHDAY=5"
  int? _byMonthDayFromRRule(String rrule) {
    final up = rrule.toUpperCase();
    if (!up.contains('FREQ=MONTHLY')) return null;
    final parts = up.split(';');
    for (final p in parts) {
      final kv = p.split('=');
      if (kv.length == 2 && kv[0] == 'BYMONTHDAY') {
        return int.tryParse(kv[1]);
      }
    }
    return null;
  }

  int _daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

  // Devuelve una lista "expandida" de fijos que ocurren en el mes seleccionado.
  // Si el backend ya trajo instancias del mes, las usa; si trajo definiciones,
  // las convierte a una instancia sintética (una por mes).
  List<Map<String, dynamic>> _fixedExpandedForMonth(
      List<dynamic> raw, DateTime month) {
    final List<Map<String, dynamic>> out = [];

    for (final item in raw) {
      final e = Map<String, dynamic>.from(item as Map);

      // 1) Si ya es instancia del mes (occursAt en el mes), la usamos.
      if (_isInstanceForMonth(e, month)) {
        out.add(e);
        continue;
      }

      // 2) Si es definición: dayOfMonth o rrule => generar instancia en este mes
      final dynamic domDyn = e['dayOfMonth'];
      final String? rrule = e['rrule']?.toString();

      int? day;
      if (domDyn != null) {
        day = int.tryParse(domDyn.toString());
      } else if (rrule != null && rrule.isNotEmpty) {
        day = _byMonthDayFromRRule(rrule);
      }

      if (day != null) {
        final dayClamped = day.clamp(1, _daysInMonth(month));
        final occurs = DateTime(month.year, month.month, dayClamped);
        out.add({
          ...e,
          'occursAt': occurs.toIso8601String(),
        });
      }
      // Si no hay day/rrule, no podemos determinar ocurrencia -> lo ignoramos.
    }

    return out;
  }

  // ==== Totales de forecast (solo gastado, como estaba planteado) ====
  double _sumAmount(Iterable it) =>
      it.fold<double>(0, (acc, e) => acc + _asDouble(e['amount']));

  double get _plannedExpenseTotal =>
      _sumAmount(_planned.where((e) => (e['type'] ?? 'EXPENSE') == 'EXPENSE'));

  double get _fixedExpenseTotal {
    final expanded = _fixedExpandedForMonth(_fixedRaw, _month);
    return _sumAmount(
      expanded.where((e) => (e['type'] ?? 'EXPENSE') == 'EXPENSE'),
    );
  }

  Map<String, dynamic>? get _effectiveSummary {
    if (!_includeForecast || _summary == null) return _summary;

    final base = _summary!;
    final opening = _asDouble(base['openingBalance']);
    final income = _asDouble(base['income']); // seguimos sin sumar ingresos previstos
    final expense =
        _asDouble(base['expense']) + _plannedExpenseTotal + _fixedExpenseTotal;
    final net = income - expense;
    final closing = opening + net;

    return {
      ...base,
      'income': income,
      'expense': expense,
      'net': net,
      'closingBalance': closing,
    };
  }

  // ==== Borrados con confirmación ====
  Future<void> plannedDelete(Map e) async {
    final s = S.of(context);

    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar previsto'),
        content: const Text('¿Seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (sure != true) return;

    final dio = ref.read(dioProvider);
    try {
      await dio.delete('/households/${widget.householdId}/planned/${e['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.deletedOkToast)),
      );
      await _refresh();
    } on DioException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.deleteFailedToast)),
      );
    }
  }

  Future<void> _confirmDeleteRecurring(Map e) async {
    final s = S.of(context);
    final title = s.fixedDeleteTitle ?? 'Eliminar gasto fijo';
    final body =
        s.fixedDeleteBody ?? '¿Seguro? Esta acción no se puede deshacer.';

    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel ?? 'Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete ?? 'Eliminar'),
          ),
        ],
      ),
    );

    if (sure != true) return;

    final dio = ref.read(dioProvider);
    try {
      await dio.delete(
          '/households/${widget.householdId}/recurring/${e['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.deletedOkToast ?? 'Eliminado')),
      );
      await _refresh();
    } on DioException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.deleteFailedToast ?? 'No se pudo eliminar')),
      );
    }
  }

  // ==== Cambios de mes ====
  void _openMonthFromYm(String ym) {
    final parts = ym.split('-');
    if (parts.length >= 2) {
      final year = int.tryParse(parts[0]) ?? DateTime.now().year;
      final month = int.tryParse(parts[1]) ?? DateTime.now().month;
      final next = DateTime(year, month);
      setState(() {
        _month = next;
        _viewAllMonths = false;
        _includeForecast = _isFutureMonth(next);
      });
      _refresh();
    }
  }

  Future<void> _confirmAndDelete() async {
    final s = S.of(context);
    final dio = ref.read(dioProvider);

    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteHouseholdTitle),
        content: Text(s.deleteHouseholdBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (sure != true || _deleting) return;

    setState(() => _deleting = true);
    try {
      await dio.delete('/households/${widget.householdId}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.deletedOkToast)),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.deleteFailedToast)),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // ==== Carga de datos (con fallback para fijos) ====
  Future<void> _refresh() async {
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);
    final s = S.of(context);

    try {
      final (from, to) = _rangeOfMonth(_month);

      // Movimientos del mes
      final resList = await dio.get(
        '/households/${widget.householdId}/entries',
        queryParameters: {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
          'limit': 200,
        },
      );

      // Resumen del mes (puede no existir en meses futuros)
      Map<String, dynamic>? summary;
      try {
        final resSum = await dio.get(
          '/households/${widget.householdId}/summary',
          queryParameters: {'month': _monthStr},
        );
        summary = Map<String, dynamic>.from(resSum.data as Map);
      } on DioException {
        summary = _emptySummaryFor(_monthStr);
      }

      if (_isFutureMonth(_month)) {
        summary = _emptySummaryFor(_monthStr);
      }

      // Previstos de este mes
      final resPlanned = await dio.get(
        '/households/${widget.householdId}/planned',
        queryParameters: {'month': _monthStr},
      );

      // Fijos: intentamos instancias del mes; si vacío -> traemos definiciones
      final resFixedMonth = await dio.get(
        '/households/${widget.householdId}/recurring',
        queryParameters: {'month': _monthStr},
      );
      List fixedList = (resFixedMonth.data as List).toList();
      if (fixedList.isEmpty) {
        try {
          final resFixedDefs =
          await dio.get('/households/${widget.householdId}/recurring');
          fixedList = (resFixedDefs.data as List).toList();
        } catch (_) {
          // si también falla, dejamos vacío y el total será 0
        }
      }

      setState(() {
        _entries = (resList.data as List).toList();
        _summary = summary;
        _planned = (resPlanned.data as List).toList();
        _fixedRaw = fixedList.cast<Map>();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.errorLoadData)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ==== Todos los meses (sin cambios) ====
  Future<void> _loadAllMonths() async {
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);

    try {
      final resList = await dio.get(
        '/households/${widget.householdId}/entries',
        queryParameters: {
          'from': DateTime(2000, 1, 1).toIso8601String(),
          'to': DateTime.now().toIso8601String(),
          'limit': 10000,
        },
      );
      final entries = (resList.data as List).toList();

      final monthsSet = <String>{};
      for (final e in entries) {
        final dt = DateTime.tryParse(e['occursAt']?.toString() ?? '');
        if (dt == null) continue;
        final key =
            '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';
        monthsSet.add(key);
      }

      if (monthsSet.isEmpty) {
        setState(() => _allSummaries = []);
        return;
      }

      final months = monthsSet.toList()..sort(); // asc
      final futures = months.map((m) async {
        try {
          final r = await dio.get(
            '/households/${widget.householdId}/summary',
            queryParameters: {'month': m},
          );
          return Map<String, dynamic>.from(r.data as Map);
        } catch (_) {
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);

      final summaries = results.whereType<Map<String, dynamic>>().toList()
        ..sort((a, b) => (b['month'] ?? '').toString().compareTo(
          (a['month'] ?? '').toString(),
        ));

      setState(() => _allSummaries = summaries);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleViewAll() async {
    final newVal = !_viewAllMonths;
    setState(() => _viewAllMonths = newVal);
    if (newVal) {
      await _loadAllMonths();
    } else {
      await _refresh();
    }
  }

  // ==== Sheets ====
  Future<void> _openAddEntry({Map<String, dynamic>? existing}) async {
    final res = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          AddEntrySheet(householdId: widget.householdId, existing: existing),
    );

    if (res != null) {
      if (_viewAllMonths) {
        await _loadAllMonths();
      } else {
        await _refresh();
      }
      if (!mounted) return;

      final s = S.of(context);
      final txt =
      (res['type'] == 'INCOME') ? s.incomeSavedToast : s.expenseSavedToast;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt)));
    }
  }

  Future<void> _openQuickSavingsDeposit() async {
    final dio = ref.read(dioProvider);
    final s = S.of(context);

    final ok = await showQuickSavingsDepositDialog(
      context: context,
      dio: dio,
      householdId: widget.householdId,
      householdName:
      _householdNameState ?? widget.householdName ?? s.accountGenericLower,
    );

    if (ok == true) {
      if (_viewAllMonths) {
        await _loadAllMonths();
      } else {
        await _refresh();
      }
    }
  }

  Future<void> _openAddPlanned({Map<String, dynamic>? existing}) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddPlannedExpenseSheet(
        householdId: widget.householdId,
        month: _monthStr,
        existing: existing,
      ),
    );
    if (res == true) await _refresh();
  }

  Future<void> _openAddFixed({Map<String, dynamic>? existing}) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddFixedExpenseSheet(
        householdId: widget.householdId,
        existing: existing,
      ),
    );
    if (res == true) await _refresh();
  }

  // ==== Navegación mensual ====
  void _prevMonth() {
    final next = DateTime(_month.year, _month.month - 1);
    setState(() {
      _month = next;
    });
    _refresh();
  }

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1);
    setState(() {
      _month = next;
    });
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final name =
        _householdNameState ?? widget.householdName ?? s.accountGenericLower;

    final nowMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final isAtCurrentMonth =
        _month.year == nowMonth.year && _month.month == nowMonth.month;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                HouseholdHeaderMenu(
                  viewAllMonths: _viewAllMonths,
                  monthStr: _monthStr,
                  isAtCurrentMonth: isAtCurrentMonth,
                  onPrevMonth: _prevMonth,
                  onNextMonth: _nextMonth,
                  onToggleViewAll: _toggleViewAll,
                  householdId: widget.householdId,
                  householdName: name,
                  onOpenSavingsGoals: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SavingsGoalsScreen(
                          householdId: widget.householdId,
                          householdName: name,
                        ),
                      ),
                    );
                  },
                  onOpenQuickSavingsDeposit: _openQuickSavingsDeposit,
                  onOpenInvite: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GenerateInviteScreen(
                          householdId: widget.householdId,
                          householdName: name,
                        ),
                      ),
                    );
                  },
                  onOpenSettings: () async {
                    final dio = ref.read(dioProvider);
                    final newName = await showRenameHouseholdDialog(
                      context,
                      dio,
                      initialName: name,
                      householdId: widget.householdId,
                    );
                    if (newName != null && mounted) {
                      setState(() => _householdNameState = newName);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.updatedNameToast)),
                      );
                    }
                  },
                  onRefresh: _viewAllMonths ? _loadAllMonths : _refresh,
                  onDeleteHousehold: _confirmAndDelete,
                ),
              ],
            ),
          ),
        ),
        actions: const [],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEntry(),
        icon: const Icon(Icons.add),
        label: Text(s.addEntryFab),
        backgroundColor: T.cPrimary,
        foregroundColor: Colors.white,
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _viewAllMonths ? _loadAllMonths : _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_viewAllMonths) ...[
              if (_allSummaries.isEmpty)
                Text(s.noMonthsWithMovements)
              else
                ..._allSummaries.map(
                      (summary) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SummaryCard(
                      month: summary['month']?.toString() ?? '',
                      opening: _asDouble(summary['openingBalance']),
                      income: _asDouble(summary['income']!),
                      expense: _asDouble(summary['expense']!),
                      net: _asDouble(summary['net']!),
                      closing: _asDouble(summary['closingBalance']!),
                      onTap: () {
                        final ym = summary['month']?.toString() ?? '';
                        _openMonthFromYm(ym);
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 72),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(S.of(context).forecastIncludeLabel ??
                      'Incluir previstos y fijos'),
                  Switch(
                    value: _includeForecast,
                    onChanged: (v) =>
                        setState(() => _includeForecast = v),
                  ),
                ],
              ),

              if (_summary != null)
                SummaryCard(
                  month: (_effectiveSummary?['month'] ??
                      _summary!['month'] ??
                      _monthStr)
                      .toString(),
                  opening: _asDouble(_effectiveSummary?['openingBalance'] ??
                      _summary!['openingBalance']),
                  income: _asDouble(_effectiveSummary?['income'] ??
                      _summary!['income']),
                  expense: _asDouble(_effectiveSummary?['expense'] ??
                      _summary!['expense']),
                  net: _asDouble(
                      _effectiveSummary?['net'] ?? _summary!['net']),
                  closing: _asDouble(
                      _effectiveSummary?['closingBalance'] ??
                          _summary!['closingBalance']),
                ),
              const SizedBox(height: 12),

              // ---- PREVISTOS ---------------------------------------------------------
              ExpansionTile(
                initiallyExpanded: _planned.isNotEmpty,
                title: Text(S.of(context).plannedTitle ??
                    'Gastos previstos (mes)'),
                subtitle: Text(
                    '${_planned.length} • Total: ${_plannedExpenseTotal.toStringAsFixed(2)}'),
                children: [
                  if (_planned.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(S.of(context).plannedEmpty ??
                          'Sin previstos'),
                    )
                  else
                    ..._planned.map((e) {
                      final concept =
                      (e['concept'] ?? e['title'] ?? '').toString();
                      final amount = _asDouble(e['amount']);
                      final due =
                      (e['dueDate'] ?? e['occursAt'] ?? '').toString();
                      return ListTile(
                        dense: true,
                        title: Text(concept),
                        subtitle: Text(
                            '${due.isEmpty ? '' : '$due • '}${amount.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                              const Icon(Icons.check_circle_outline),
                              tooltip: S.of(context).plannedSettle ??
                                  'Marcar como pagado',
                              onPressed: () async {
                                try {
                                  final dio = ref.read(dioProvider);
                                  await dio.post(
                                    '/households/${widget.householdId}/planned/${e['id']}/settle',
                                    data: {'month': _monthStr},
                                  );
                                  await _refresh();
                                } catch (_) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                        content: Text(S
                                            .of(context)
                                            .actionFailed ??
                                            'No se pudo completar')));
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _openAddPlanned(existing: e),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Eliminar previsto',
                              onPressed: () => plannedDelete(e),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(S.of(context).plannedAdd ??
                            'Añadir previsto'),
                        onPressed: () => _openAddPlanned(),
                      ),
                    ),
                  ),
                ],
              ),

              // ---- FIJOS -------------------------------------------------------------
              ExpansionTile(
                initiallyExpanded: _fixedRaw.isNotEmpty,
                title:
                Text(S.of(context).fixedTitle ?? 'Gastos fijos'),
                subtitle: Text(
                    '${_fixedRaw.length} • Total (mes): ${_fixedExpenseTotal.toStringAsFixed(2)}'),
                children: [
                  if (_fixedRaw.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                          S.of(context).fixedEmpty ?? 'Sin fijos'),
                    )
                  else
                    ..._fixedRaw.map((e) {
                      final concept =
                      (e['concept'] ?? e['title'] ?? '').toString();
                      final amount = _asDouble(e['amount']);
                      final rule =
                      (e['rrule'] ?? e['dayOfMonth'] ?? '').toString();
                      return ListTile(
                        dense: true,
                        title: Text(concept),
                        subtitle: Text(
                            '${rule.isEmpty ? 'Mensual' : rule} • ${amount.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _openAddFixed(existing: e),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: S.of(context).fixedDelete ??
                                  'Eliminar gasto fijo',
                              onPressed: () =>
                                  _confirmDeleteRecurring(e),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(S.of(context).fixedAdd ??
                            'Añadir gasto fijo'),
                        onPressed: () => _openAddFixed(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                s.monthMovementsTitle,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              MovementsList(
                entries: _entries,
                onEdit: (e) => _openAddEntry(existing: e),
                onDelete: (id) async {
                  final dio = ref.read(dioProvider);
                  try {
                    await dio.delete(
                      '/households/${widget.householdId}/entries/$id',
                    );
                    if (_viewAllMonths) {
                      await _loadAllMonths();
                    } else {
                      await _refresh();
                    }
                    return true;
                  } on DioException {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.deleteFailedToast)),
                      );
                    }
                    return false;
                  }
                },
              ),

              const SizedBox(height: 72),
            ],
          ],
        ),
      ),
    );
  }

  static double _asDouble(dynamic x) {
    if (x is num) return x.toDouble();
    return double.tryParse(x?.toString() ?? '0') ?? 0;
  }
}
