// -----------------------------------------------------------------------------
// Pantalla principal de detalle de la cuenta (Household).
//
// Auto-post y forecast con INCOME/EXPENSE fijos:
//   • Asienta automáticamente fijos (ingresos y gastos) cuando llega su fecha.
//   • Forecast suma ingresos fijos pendientes a income y gastos fijos pendientes a expense.
//   • Evita duplicar: lo ya asentado (según entries o nota [RECURRING:<id>]) no se vuelve a sumar.
//   • En meses futuros: apertura/income/expense = 0 (resumen sintético).
//
// FIX anti-duplicados:
//   1) _fixedExpandedForMonth ahora DESDUPLICA por (id@occursAt), prefiriendo
//      la instancia real (traída por el BE) frente a la generada localmente.
//   2) _autoPostDueFixedIfNeeded coloca el candado _autoPosting ANTES de calcular
//      los vencidos y usa _postingKeys para evitar doble POST en paralelo por (id@occursAt).
// -----------------------------------------------------------------------------

import 'package:dio/dio.dart';
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
import 'widgets/actions_row.dart'; // HouseholdHeaderMenu

class _RecurringAutopostGuard {
  static bool busy = false;
  static final Set<String> inflightKeys = <String>{};
}

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

  List<Map<String, dynamic>> _entries = [];
  Map<String, dynamic>? _summary;

  bool _viewAllMonths = false;
  bool _deleting = false;

  // Previstos / Fijos
  List<Map<String, dynamic>> _planned = [];
  List<Map<String, dynamic>> _fixedRaw = []; // definiciones o instancias
  bool _includeForecast = true; // ON por defecto

  // Todos los meses
  List<Map<String, dynamic>> _allSummaries = [];

  String? _householdNameState;

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  // Para evitar bucles durante autopost
  bool _autoPosting = false;

  // Claves en vuelo para evitar doble POST en paralelo por (id@occursAt)
  final Set<String> _postingKeys = {};

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

  // ==== Utilidades ====
  bool _isFutureMonth(DateTime m) {
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    final cand = DateTime(m.year, m.month);
    return cand.isAfter(now);
  }

  bool _isCurrentMonth(DateTime m) {
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    final cand = DateTime(m.year, m.month);
    return cand == now;
  }

  List<Map<String, dynamic>> _asListOfMap(dynamic data) {
    final raw = (data is List) ? data : const [];
    return raw.map<Map<String, dynamic>>((e) {
      if (e is Map<String, dynamic>) return e;
      if (e is Map) return Map<String, dynamic>.from(e);
      return <String, dynamic>{};
    }).toList();
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

  DateTime? _parseDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ==== EXPANSIÓN LOCAL DE FIJOS (si el BE no manda instancias por mes) ====

  bool _isInstanceForMonth(Map e, DateTime month) {
    final occursAtStr = e['occursAt']?.toString();
    if (occursAtStr == null || occursAtStr.isEmpty) return false;
    final dt = DateTime.tryParse(occursAtStr);
    if (dt == null) return false;
    return dt.year == month.year && dt.month == month.month;
  }

  int? _byMonthDayFromRRule(String rrule) {
    final up = rrule.toUpperCase();
    if (!up.contains('FREQ=MONTHLY')) return null;
    for (final p in up.split(';')) {
      final kv = p.split('=');
      if (kv.length == 2 && kv[0] == 'BYMONTHDAY') {
        return int.tryParse(kv[1]);
      }
    }
    return null;
  }

  int _daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

  // DEVUELVE lista EXPANDIDA y DESDUPLICADA por (id@occursAt).
  // Si existe instancia real y generada para el mismo id/fecha, se queda la instancia real.
  List<Map<String, dynamic>> _fixedExpandedForMonth(
      List<Map<String, dynamic>> raw, DateTime month) {
    final Map<String, Map<String, dynamic>> byKey = {};

    for (final item in raw) {
      final e = Map<String, dynamic>.from(item);

      DateTime? occurs;
      bool isRealInstance = false;

      if (_isInstanceForMonth(e, month)) {
        occurs = DateTime.parse(e['occursAt'].toString());
        isRealInstance = true;
      } else {
        // Definición: generar instancia del mes
        int? day;
        if (e['dayOfMonth'] != null) {
          day = int.tryParse(e['dayOfMonth'].toString());
        } else if (e['rrule'] != null && e['rrule'].toString().isNotEmpty) {
          day = _byMonthDayFromRRule(e['rrule'].toString());
        }
        if (day != null) {
          final clamped = day.clamp(1, _daysInMonth(month));
          occurs = DateTime(month.year, month.month, clamped);
        }
      }

      if (occurs == null) continue;

      final id = e['id']?.toString() ?? '';
      final key = '$id@${DateUtils.dateOnly(occurs).toIso8601String()}';

      final candidate = {
        ...e,
        'occursAt': occurs.toIso8601String(),
      };

      if (!byKey.containsKey(key)) {
        byKey[key] = candidate;
      } else {
        // Prefiere instancia real si ya había una generada
        final alreadyReal =
        _isInstanceForMonth(byKey[key]!, month); // ya tiene occursAt real?
        if (!alreadyReal && isRealInstance) {
          byKey[key] = candidate;
        }
      }
    }

    return byKey.values.toList();
  }

  // ---- Identificador único por nota de recurrentes ----
  String _recurringMarkerFor(Map e) => (e['id'] ?? '').toString();

  bool _entryHasRecurringMarker(Map<String, dynamic> entry, String recurringId) {
    final note = entry['note']?.toString() ?? '';
    final concept = (entry['concept'] ?? entry['title'] ?? '').toString();

    // Compat: marcador antiguo en NOTE
    if (note.contains('[RECURRING:$recurringId]')) return true;

    // Nuevo: marcador en CONCEPT => [recurring: ... : <id>]
    final re = RegExp(r'^\[recurring:\s*.+?:\s*([^\]]+)\]$', caseSensitive: false);
    final m = re.firstMatch(concept);
    if (m != null && (m.group(1)?.trim() == recurringId)) return true;

    return false;
  }

  // ¿Está asentada esta ocurrencia? (usa nota [RECURRING:<id>] o fallback día/importe)
  bool _occurrenceIsPosted(
      Map<String, dynamic> occ,
      List<Map<String, dynamic>> entries,
      ) {
    final recurringId = occ['id']?.toString();
    if (recurringId != null && recurringId.isNotEmpty) {
      for (final en in entries) {
        if (_entryHasRecurringMarker(en, recurringId)) return true;
      }
    }

    // Fallback
    final occDate = _parseDate(occ['occursAt']);
    if (occDate == null) return false;
    final targetAmt = _asDouble(occ['amount']);
    final targetType = (occ['type'] ?? '').toString();

    for (final en in entries) {
      final enType = (en['type'] ?? '').toString();
      if (enType != targetType) continue;
      final enDate = _parseDate(en['occursAt']);
      if (enDate == null) continue;
      if (_sameDay(occDate, enDate)) {
        final amt = _asDouble(en['amount']);
        if ((amt - targetAmt).abs() < 0.005) return true;
      }
    }
    return false;
  }

  // ==== Totales forecast (pendiente, sin duplicar lo asentado) ====
  double _sumAmount(Iterable it) =>
      it.fold<double>(0, (acc, e) => acc + _asDouble((e as Map)['amount']));

  double get _plannedExpenseTotal =>
      _sumAmount(_planned.where((e) => (e['type'] ?? 'EXPENSE') == 'EXPENSE'));

  double get _fixedExpensePendingTotal {
    final expanded = _fixedExpandedForMonth(_fixedRaw, _month);
    final pending = expanded.where((e) =>
    (e['type'] ?? 'EXPENSE') == 'EXPENSE' &&
        !_occurrenceIsPosted(e, _entries));
    return _sumAmount(pending);
  }

  double get _fixedIncomePendingTotal {
    final expanded = _fixedExpandedForMonth(_fixedRaw, _month);
    final pending = expanded.where((e) =>
    (e['type'] ?? '') == 'INCOME' && !_occurrenceIsPosted(e, _entries));
    return _sumAmount(pending);
  }

  Map<String, dynamic>? get _effectiveSummary {
    if (_summary == null) return null;

    double opening = _asDouble(_summary!['openingBalance']);
    double income = _asDouble(_summary!['income']);
    double expense = _asDouble(_summary!['expense']);

    if (_isFutureMonth(_month)) {
      opening = 0;
      income = 0;
      expense = 0;
    }

    if (_includeForecast) {
      income += _fixedIncomePendingTotal;
      expense += _plannedExpenseTotal + _fixedExpensePendingTotal;
    }

    final net = income - expense;
    final closing = opening + net;

    return {
      ..._summary!,
      'openingBalance': opening,
      'income': income,
      'expense': expense,
      'net': net,
      'closingBalance': closing,
    };
  }

  // ==== Auto-post de fijos vencidos (INCOME y EXPENSE) en mes actual ====
  Future<void> _autoPostDueFixedIfNeeded() async {
    if (!_isCurrentMonth(_month)) return;

    // Candado GLOBAL (evita carreras entre instancias / hot-reloads)
    if (_RecurringAutopostGuard.busy) return;
    _RecurringAutopostGuard.busy = true;

    try {
      final now = DateTime.now();
      final expanded = _fixedExpandedForMonth(_fixedRaw, _month);

      // Construye lote vencido, no asentado, DEDUP por (id@día)
      final Set<String> seen = {};
      final List<Map<String, dynamic>> dueUnique = [];

      for (final f in expanded) {
        final t = (f['type'] ?? '').toString();
        if (t != 'EXPENSE' && t != 'INCOME') continue;

        final occursAt = _parseDate(f['occursAt']);
        if (occursAt == null || occursAt.isAfter(now)) continue;
        if (_occurrenceIsPosted(f, _entries)) continue;

        final idStr = (f['id'] ?? '').toString();
        if (idStr.isEmpty) continue;

        final key = '$idStr@${DateUtils.dateOnly(occursAt).toIso8601String()}';

        // Evita duplicar dentro del mismo lote y también si otra instancia ya lo está posteando
        if (_RecurringAutopostGuard.inflightKeys.contains(key)) continue;
        if (seen.add(key)) dueUnique.add(f);
      }

      if (dueUnique.isEmpty) return;

      // Marca claves en vuelo de forma global
      _RecurringAutopostGuard.inflightKeys.addAll(dueUnique.map((f) {
        final d = DateTime.parse((f['occursAt'] ?? '').toString());
        return '${f['id']}@${DateUtils.dateOnly(d).toIso8601String()}';
      }));

      final dio = ref.read(dioProvider);
      int okCount = 0;

      for (final f in dueUnique) {
        final occursAt = DateTime.parse((f['occursAt'] ?? '').toString());
        final dayKey = '${f['id']}@${DateUtils.dateOnly(occursAt).toIso8601String()}';

        try {
          await dio.post(
            '/households/${widget.householdId}/recurring/${f['id']}/post',
            data: {'occursAt': occursAt.toIso8601String()},
            // Si el BE lo soporta, esta cabecera lo hace idempotente:
            options: Options(headers: {'Idempotency-Key': dayKey}),
          );
          okCount++;
        } catch (_) {
          // Si el BE ya lo creó, simplemente seguimos.
        }
      }

      // Recarga ligera
      final (from, to) = _rangeOfMonth(_month);
      final resList = await dio.get(
        '/households/${widget.householdId}/entries',
        queryParameters: {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
          'limit': 200,
        },
      );
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

      setState(() {
        _entries = _asListOfMap(resList.data);
        _summary = summary;
      });

      if (mounted && okCount > 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$okCount OK')));
      }
    } finally {
      // Libera el candado global y claves en vuelo
      _RecurringAutopostGuard.busy = false;
      _RecurringAutopostGuard.inflightKeys.clear();
    }
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

  // ==== Carga de datos ====
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

      // Resumen del mes
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

      final resPlanned = await dio.get(
        '/households/${widget.householdId}/planned',
        queryParameters: {'month': _monthStr},
      );

      final resFixedMonth = await dio.get(
        '/households/${widget.householdId}/recurring',
        queryParameters: {'month': _monthStr},
      );

      List<Map<String, dynamic>> fixedList = _asListOfMap(resFixedMonth.data);
      if (fixedList.isEmpty) {
        try {
          final resFixedDefs =
          await dio.get('/households/${widget.householdId}/recurring');
          fixedList = _asListOfMap(resFixedDefs.data);
        } catch (_) {}
      }

      setState(() {
        _entries = _asListOfMap(resList.data);
        _summary = summary;
        _planned = _asListOfMap(resPlanned.data);
        _fixedRaw = fixedList;
      });

      // Autopost de fijos vencidos (ingresos y gastos)
      await _autoPostDueFixedIfNeeded();
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

  // ==== Todos los meses ====
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

      final entries = _asListOfMap(resList.data);

      final monthsSet = <String>{};
      for (final e in entries) {
        final dt = DateTime.tryParse(e['occursAt']?.toString() ?? '');
        if (dt == null) continue;
        monthsSet.add(
            '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}');
      }

      if (monthsSet.isEmpty) {
        setState(() => _allSummaries = []);
        return;
      }

      final months = monthsSet.toList()..sort();
      final futures = months
          .map((m) async {
        try {
          final r = await dio.get(
            '/households/${widget.householdId}/summary',
            queryParameters: {'month': m},
          );
          return Map<String, dynamic>.from(r.data as Map);
        } catch (_) {
          return null;
        }
      })
          .toList();

      final results = await Future.wait(futures);

      final summaries = results.whereType<Map<String, dynamic>>().toList()
        ..sort((a, b) => (b['month'] ?? '')
            .toString()
            .compareTo((a['month'] ?? '').toString()));

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

    // Totales pendientes para subtítulos
    final fixedExpanded = _fixedExpandedForMonth(_fixedRaw, _month);
    final fixedPending = fixedExpanded
        .where((e) =>
    ((e['type'] ?? '') == 'INCOME' || (e['type'] ?? '') == 'EXPENSE') &&
        !_occurrenceIsPosted(e, _entries))
        .toList();

    final fixedPendingIncomeTotal = fixedPending
        .where((e) => (e['type'] ?? '') == 'INCOME')
        .fold<double>(0, (a, b) => a + _asDouble(b['amount']));

    final fixedPendingExpenseTotal = fixedPending
        .where((e) => (e['type'] ?? '') == 'EXPENSE')
        .fold<double>(0, (a, b) => a + _asDouble(b['amount']));

    final fixedPendingNet = fixedPendingIncomeTotal - fixedPendingExpenseTotal;

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
                      opening:
                      _asDouble(summary['openingBalance']),
                      income: _asDouble(summary['income']!),
                      expense: _asDouble(summary['expense']!),
                      net: _asDouble(summary['net']!),
                      closing: _asDouble(summary['closingBalance']!),
                      onTap: () {
                        final ym =
                            summary['month']?.toString() ?? '';
                        _openMonthFromYm(ym);
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 72),
            ] else ...[
              // Switch forecast
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
                  net: _asDouble(_effectiveSummary?['net'] ??
                      _summary!['net']),
                  closing: _asDouble(
                      _effectiveSummary?['closingBalance'] ??
                          _summary!['closingBalance']),
                ),
              const SizedBox(height: 12),

              // ---- PREVISTOS (solo gastos) --------------------------------------
              ExpansionTile(
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
                      final due = (e['dueDate'] ?? e['occursAt'] ?? '')
                          .toString();
                      return ListTile(
                        dense: true,
                        title: Text(concept),
                        subtitle: Text(
                            '${due.isEmpty ? '' : '$due • '}${amount.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.check_circle_outline),
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

              // ---- FIJOS (ingresos y gastos) -------------------------------------
              ExpansionTile(
                title:
                Text(S.of(context).fixedTitle ?? 'Gastos fijos'),
                subtitle: Text(
                  '${fixedPending.length} • Neto pendiente (mes): ${fixedPendingNet.toStringAsFixed(2)}',
                ),
                children: [
                  if (_fixedRaw.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child:
                      Text(S.of(context).fixedEmpty ?? 'Sin fijos'),
                    )
                  else
                    ...fixedExpanded.map((e) {
                      final concept =
                      (e['concept'] ?? e['title'] ?? '').toString();
                      final amount = _asDouble(e['amount']);
                      final rule =
                      (e['rrule'] ?? e['dayOfMonth'] ?? '')
                          .toString();
                      final occursAt =
                      (e['occursAt'] ?? '').toString();
                      final posted = _occurrenceIsPosted(e, _entries);
                      final type =
                      (e['type'] ?? 'EXPENSE').toString();
                      final sign = type == 'INCOME' ? '+' : '-';
                      return ListTile(
                        dense: true,
                        title: Text(concept),
                        subtitle: Text(
                            '${occursAt.isEmpty ? (rule.isEmpty ? "Mensual" : rule) : occursAt} • $sign${amount.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (posted)
                              const Icon(Icons.check_circle,
                                  size: 20, color: Colors.green),
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
