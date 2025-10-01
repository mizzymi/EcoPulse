// -----------------------------------------------------------------------------
// Pantalla principal de detalle de la cuenta (Household).
//
// Muestra:
//   • Resumen del mes actual o “Todos los meses” (vista agregada)
//   • Lista de movimientos del mes actual
//   • Acciones rápidas: metas de ahorro, ingreso a ahorro, invitar, renombrar, refrescar
//
// Estructura (separada por archivos para mantener este widget liviano):
//   - widgets/month_nav_row.dart        → barra para navegar entre meses y alternar vista
//   - widgets/actions_row.dart          → fila de acciones (ahorro, ingreso, QR, config, refresh)
//   - widgets/summary_card.dart         → tarjeta de resumen mensual
//   - widgets/movements_list.dart       → lista de movimientos con edición/borrado
//   - widgets/add_entry_sheet.dart      → bottom sheet para crear/editar movimiento
//   - dialogs/rename_household_dialog.dart → diálogo para renombrar la cuenta
//   - dialogs/savings_deposit_dialog.dart  → diálogo rápido de ingreso a ahorro
//
// Backend esperado (ajusta si tus rutas difieren):
//   GET  /households/:id/entries
//   GET  /households/:id/summary?month=YYYY-MM
//   GET  /households/:id/savings-goals
//   POST /households/:id/savings-goals/:goalId/txns
//   PATCH /households/:id                     (renombrar)
//
// Notas de rendimiento:
//   _loadAllMonths() obtiene todas las entries para deducir meses y luego pide
//   summary de cada uno. Para grandes volúmenes conviene un endpoint agregado
//   que devuelva directamente los resúmenes por mes en una sola llamada.
// -----------------------------------------------------------------------------

import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/dio.dart';
import 'generate_invite_screen.dart';
import 'savings/savings_goals_screen.dart';

// UI extraídas a widgets/dialogs propios
import 'widgets/actions_row.dart';
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
  // Estado de carga (spinner)
  bool _loading = true;

  // Entradas (gastos/ingresos) del mes actual
  List<dynamic> _entries = [];

  // Resumen del mes actual (opening, income, expense, net, closing)
  Map<String, dynamic>? _summary;

  // Vista “Todos los meses”
  bool _viewAllMonths = false;

  bool _deleting = false;

  Future<void> _confirmAndDelete() async {
    final s = S.of(context);
    final dio = ref.read(dioProvider);

    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteHouseholdTitle), // “Borrar cuenta”
        content: Text(s
            .deleteHouseholdBody), // “¿Seguro? Esta acción no se puede deshacer…”
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
        SnackBar(content: Text(s.deletedOkToast)), // “Cuenta borrada”
      );
      Navigator.of(context).pop(true); // vuelve al listado
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.deleteFailedToast)), // “No se pudo borrar…”
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // Resúmenes de todos los meses (solo cuando _viewAllMonths = true)
  List<Map<String, dynamic>> _allSummaries = [];

  // Nombre editable para reflejar cambios en AppBar
  String? _householdNameState;

  // Mes en foco (YYYY-MM)
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    // Nombre inicial si vino por parámetro
    _householdNameState = widget.householdName;
    // Carga inicial del mes en foco
    _refresh();
  }

  // Helper: “YYYY-MM” del mes en foco
  String get _monthStr =>
      '${_month.year.toString().padLeft(4, '0')}-${_month.month.toString().padLeft(2, '0')}';

  // Rango exacto de un mes [from, to]
  (DateTime from, DateTime to) _rangeOfMonth(DateTime d) {
    final from = DateTime(d.year, d.month, 1, 0, 0, 0);
    final to = DateTime(d.year, d.month + 1, 0, 23, 59, 59, 999);
    return (from, to);
  }

  // Abre un mes (YYYY-MM) desde la vista “Todos los meses”
  void _openMonthFromYm(String ym) {
    final parts = ym.split('-');
    if (parts.length >= 2) {
      final year = int.tryParse(parts[0]) ?? DateTime.now().year;
      final month = int.tryParse(parts[1]) ?? DateTime.now().month;
      setState(() {
        _month = DateTime(year, month);
        _viewAllMonths = false;
      });
      _refresh();
    }
  }

  // Carga movimientos y resumen del mes en foco
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

      // Resumen del mes en foco
      final resSum = await dio.get(
        '/households/${widget.householdId}/summary',
        queryParameters: {'month': _monthStr},
      );

      setState(() {
        _entries = (resList.data as List).toList();
        _summary = Map<String, dynamic>.from(resSum.data as Map);
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

  // Carga resúmenes de TODOS los meses con movimientos
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

  // Alterna entre vista mensual y “Todos los meses”
  Future<void> _toggleViewAll() async {
    final newVal = !_viewAllMonths;
    setState(() => _viewAllMonths = newVal);
    if (newVal) {
      await _loadAllMonths();
    } else {
      await _refresh();
    }
  }

  // Bottom sheet para crear/editar movimiento y refrescar al volver
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

  // Diálogo rápido para ingreso a ahorro
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

  // Navegar al mes anterior
  void _prevMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1);
    });
    _refresh();
  }

  // Navegar al mes siguiente (no futuro)
  void _nextMonth() {
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    final cand = DateTime(_month.year, _month.month + 1);
    if (cand.isAfter(now)) return;
    setState(() => _month = cand);
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
          preferredSize: const Size.fromHeight(88),
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

      // FAB para crear movimientos
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEntry(),
        icon: const Icon(Icons.add),
        label: Text(s.addEntryFab),
      ),

      // Cuerpo
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
                            income: _asDouble(summary['income']),
                            expense: _asDouble(summary['expense']),
                            net: _asDouble(summary['net']),
                            closing: _asDouble(summary['closingBalance']),
                            onTap: () {
                              final ym = summary['month']?.toString() ?? '';
                              _openMonthFromYm(ym);
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 72),
                  ] else ...[
                    if (_summary != null)
                      SummaryCard(
                        month: _summary!['month']?.toString() ?? _monthStr,
                        opening: _asDouble(_summary!['openingBalance']),
                        income: _asDouble(_summary!['income']),
                        expense: _asDouble(_summary!['expense']),
                        net: _asDouble(_summary!['net']),
                        closing: _asDouble(_summary!['closingBalance']),
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

  // Parse seguro a double para valores provenientes del backend.
  static double _asDouble(dynamic x) {
    if (x is num) return x.toDouble();
    return double.tryParse(x?.toString() ?? '0') ?? 0;
  }
}
