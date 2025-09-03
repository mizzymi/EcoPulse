// -----------------------------------------------------------------------------
// Pantalla principal de detalle de la casa (Household).
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
//   - dialogs/rename_household_dialog.dart → diálogo para renombrar la casa
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/dio.dart';
import 'generate_invite_screen.dart';
import 'savings/savings_goals_screen.dart';

// UI extraídas a widgets/dialogs propios
import 'widgets/month_nav_row.dart';
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

  // Rango exacto de un mes [from, to] (ej. 2025-09-01 00:00:00 → 2025-09-30 23:59:59.999)
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

    try {
      final (from, to) = _rangeOfMonth(_month);

      // Movimientos del mes (limite 200; pagina si necesitas más)
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
          const SnackBar(content: Text('Error al cargar datos')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Carga resúmenes de TODOS los meses con movimientos
  // Nota: para grandes volúmenes, conviene un endpoint de backend que
  // devuelva todo en una sola llamada.
  Future<void> _loadAllMonths() async {
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);

    try {
      // 1) Traer todas las entries para deducir meses únicos
      final resList = await dio.get(
        '/households/${widget.householdId}/entries',
        queryParameters: {
          'from': DateTime(2000, 1, 1).toIso8601String(),
          'to': DateTime.now().toIso8601String(),
          'limit': 10000, // TODO: pagina/optimiza si tu dataset crece
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

      // 2) Pedir summary por cada mes deducido
      final months = monthsSet.toList()..sort(); // asc
      final futures = months.map((m) async {
        try {
          final r = await dio.get(
            '/households/${widget.householdId}/summary',
            queryParameters: {'month': m},
          );
          return Map<String, dynamic>.from(r.data as Map);
        } catch (_) {
          return null; // ignora errores aislados de un mes
        }
      }).toList();

      final results = await Future.wait(futures);

      // Orden descendente por “month” (YYYY-MM) para ver lo más reciente primero
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

  // Abre el bottom sheet para crear/editar movimiento y refresca al volver
  Future<void> _openAddEntry({Map<String, dynamic>? existing}) async {
    final res = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true, // permite crecer con teclado
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

      final txt =
          (res['type'] == 'INCOME') ? 'Ingreso guardado' : 'Gasto guardado';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt)));
    }
  }

  // Diálogo rápido para ingreso a ahorro (delegado en dialogs/savings_deposit_dialog.dart)
  Future<void> _openQuickSavingsDeposit() async {
    final dio = ref.read(dioProvider);

    final ok = await showQuickSavingsDepositDialog(
      context: context,
      dio: dio,
      householdId: widget.householdId,
      householdName: _householdNameState ?? widget.householdName ?? 'Casa',
    );

    // Si hubo depósito, refrescar la vista que corresponda
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

  // Navegar al mes siguiente (no permite ir al futuro)
  void _nextMonth() {
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    final cand = DateTime(_month.year, _month.month + 1);
    if (cand.isAfter(now)) return;
    setState(() => _month = cand);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final name = _householdNameState ?? widget.householdName ?? 'Casa';

    final nowMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final isAtCurrentMonth =
        _month.year == nowMonth.year && _month.month == nowMonth.month;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),

        // Usamos un PreferredSize con dos filas: navegación y acciones.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fila de navegación entre meses / alternar vista
                MonthNavRow(
                  viewAllMonths: _viewAllMonths,
                  monthStr: _monthStr,
                  isAtCurrentMonth: isAtCurrentMonth,
                  onPrev: _prevMonth,
                  onNext: _nextMonth,
                  onToggleViewAll: _toggleViewAll,
                ),

                const SizedBox(height: 8),

                // Fila de acciones (ahorro, ingreso, invitar, config, refresh)
                ActionsRow(
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
                    // Diálogo para renombrar la casa; si retorna nombre, actualiza título
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
                        const SnackBar(content: Text('Nombre actualizado')),
                      );
                    }
                  },
                  onRefresh: _viewAllMonths ? _loadAllMonths : _refresh,
                ),
              ],
            ),
          ),
        ),

        // No usamos AppBar.actions; todo va en el "bottom" para quedar en filas.
        actions: const [],
      ),

      // FAB para crear movimientos
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEntry(),
        icon: const Icon(Icons.add),
        label: const Text('Añadir'),
      ),

      // Cuerpo: spinner o contenido con pull-to-refresh
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _viewAllMonths ? _loadAllMonths : _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ---- Vista: TODOS LOS MESES ----
                  if (_viewAllMonths) ...[
                    if (_allSummaries.isEmpty)
                      const Text('No hay meses con movimientos.')
                    else
                      ..._allSummaries.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SummaryCard(
                            month: s['month']?.toString() ?? '',
                            opening: _asDouble(s['openingBalance']),
                            income: _asDouble(s['income']),
                            expense: _asDouble(s['expense']),
                            net: _asDouble(s['net']),
                            closing: _asDouble(s['closingBalance']),
                            onTap: () {
                              final ym = s['month']?.toString() ?? '';
                              _openMonthFromYm(ym);
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 72),
                  ]

                  // ---- Vista: MES ACTUAL ----
                  else ...[
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

                    const Text(
                      'Movimientos del mes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    // Lista de movimientos reutilizable
                    MovementsList(
                      entries: _entries,
                      onEdit: (e) => _openAddEntry(existing: e),
                      onDelete: (id) async {
                        final dio = ref.read(dioProvider);
                        try {
                          await dio.delete(
                              '/households/${widget.householdId}/entries/$id');
                          if (_viewAllMonths) {
                            await _loadAllMonths();
                          } else {
                            await _refresh();
                          }
                          return true;
                        } on DioException {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('No se pudo eliminar')),
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
