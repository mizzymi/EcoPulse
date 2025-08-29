import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/dio.dart';
import 'generate_invite_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);
    try {
      final now = DateTime.now();
      final month =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
      final resList = await dio.get('/households/${widget.householdId}/entries',
          queryParameters: {'limit': 100});
      final resSum = await dio.get('/households/${widget.householdId}/summary',
          queryParameters: {'month': month});
      setState(() {
        _entries = (resList.data as List).toList();
        _summary = Map<String, dynamic>.from(resSum.data as Map);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al cargar datos')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAddEntry({Map<String, dynamic>? existing}) async {
    final res = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _AddEntrySheet(householdId: widget.householdId, existing: existing),
    );
    if (res != null) {
      await _refresh();
      if (!mounted) return;
      final txt =
          (res['type'] == 'INCOME') ? 'Ingreso guardado' : 'Gasto guardado';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt)));
    }
  }

  String _fmtAmount(dynamic a) {
    final n = (a is num) ? a : double.tryParse(a.toString()) ?? 0;
    return n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.householdName ?? 'Casa';
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            tooltip: 'Generar código',
            onPressed: () async {
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
            icon: const Icon(Icons.qr_code_2),
          ),
          IconButton(
            tooltip: 'Refrescar',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEntry(),
        icon: const Icon(Icons.add),
        label: const Text('Añadir'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_summary != null)
                    _SummaryCard(
                      income: (_summary!['income'] as num?)?.toDouble() ??
                          double.tryParse(
                              _summary!['income']?.toString() ?? '0') ??
                          0,
                      expense: (_summary!['expense'] as num?)?.toDouble() ??
                          double.tryParse(
                              _summary!['expense']?.toString() ?? '0') ??
                          0,
                      net: (_summary!['net'] as num?)?.toDouble() ??
                          double.tryParse(
                              _summary!['net']?.toString() ?? '0') ??
                          0,
                      month: _summary!['month']?.toString() ?? '',
                    ),
                  const SizedBox(height: 12),
                  const Text('Movimientos recientes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (_entries.isEmpty)
                    const Text(
                        'Aún no hay movimientos. Usa el botón “Añadir”.'),
                  ..._entries.map((e) {
                    final isIncome = e['type'] == 'INCOME';
                    final amount = _fmtAmount(e['amount']);
                    final dt =
                        DateTime.tryParse(e['occursAt']?.toString() ?? '');
                    final when = dt != null
                        ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'
                        : '';
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                            child: Icon(isIncome
                                ? Icons.trending_up
                                : Icons.trending_down)),
                        title: Text(e['category']?.toString() ??
                            (isIncome ? 'Ingreso' : 'Gasto')),
                        subtitle: Text([
                          when,
                          if ((e['note'] ?? '').toString().isNotEmpty)
                            e['note'].toString()
                        ].join('  •  ')),
                        trailing: Text(
                          (isIncome ? '+' : '-') + amount,
                          style: TextStyle(
                            color: isIncome ? Colors.teal : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => _openAddEntry(existing: e), // EDITAR
                        onLongPress: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Eliminar movimiento'),
                              content:
                                  const Text('¿Seguro que quieres eliminarlo?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar')),
                                FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Eliminar')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            final dio = ref.read(dioProvider);
                            try {
                              await dio.delete(
                                  '/households/${widget.householdId}/entries/${e['id']}');
                              await _refresh();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Eliminado')));
                              }
                            } on DioException {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('No se pudo eliminar')));
                              }
                            }
                          }
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 72),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double income, expense, net;
  final String month;
  const _SummaryCard({
    required this.income,
    required this.expense,
    required this.net,
    required this.month,
  });
  @override
  Widget build(BuildContext context) {
    final pos = net >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Resumen $month',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Ingresos: ${income.toStringAsFixed(2)}'),
            Text('Gastos:   ${expense.toStringAsFixed(2)}'),
          ]),
          Text(
            (pos ? '+' : '') + net.toStringAsFixed(2),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: pos ? Colors.teal : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ]),
      ),
    );
  }
}

/* ===== Sheet Crear/Editar movimiento ===== */

class _AddEntrySheet extends ConsumerStatefulWidget {
  final String householdId;
  final Map<String, dynamic>? existing; // null = crear, no-null = editar
  const _AddEntrySheet({required this.householdId, this.existing});

  @override
  ConsumerState<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<_AddEntrySheet> {
  late String _type;
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late DateTime _date;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _type = (ex?['type']?.toString() ?? 'EXPENSE').toUpperCase();
    final amt = ex?['amount'];
    _amountCtrl.text = amt == null
        ? ''
        : (amt is num ? amt.toStringAsFixed(2) : amt.toString());
    _categoryCtrl.text = ex?['category']?.toString() ?? '';
    _noteCtrl.text = ex?['note']?.toString() ?? '';
    _date =
        DateTime.tryParse(ex?['occursAt']?.toString() ?? '') ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Importe inválido')));
      return;
    }

    setState(() => _loading = true);
    final dio = ref.read(dioProvider);

    try {
      if (widget.existing == null) {
        final res =
            await dio.post('/households/${widget.householdId}/entries', data: {
          'type': _type,
          'amount': amount,
          'category': _categoryCtrl.text.trim().isEmpty
              ? null
              : _categoryCtrl.text.trim(),
          'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          'occursAt': _date.toIso8601String(),
        });
        if (mounted) Navigator.pop(context, res.data);
      } else {
        final id = widget.existing!['id'].toString();
        final res = await dio
            .patch('/households/${widget.householdId}/entries/$id', data: {
          'type': _type,
          'amount': amount,
          'category': _categoryCtrl.text.trim().isEmpty
              ? null
              : _categoryCtrl.text.trim(),
          'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          'occursAt': _date.toIso8601String(),
        });
        if (mounted) Navigator.pop(context, res.data);
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map &&
              (e.response!.data as Map)['message'] != null
          ? (e.response!.data as Map)['message'].toString()
          : (e.message ?? 'Error al guardar');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
          bottom: max(bottom, 16), left: 16, right: 16, top: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Text(isEdit ? 'Editar movimiento' : 'Nuevo movimiento',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Spacer(),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'EXPENSE',
                  label: Text('Gasto'),
                  icon: Icon(Icons.trending_down)),
              ButtonSegment(
                  value: 'INCOME',
                  label: Text('Ingreso'),
                  icon: Icon(Icons.trending_up)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Importe',
            hintText: 'Ej. 25.50',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _categoryCtrl,
          decoration: const InputDecoration(
            labelText: 'Categoría (opcional)',
            hintText: 'Comida, Transporte, Nómina…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteCtrl,
          decoration: const InputDecoration(
            labelText: 'Nota (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Text(
              'Fecha: ${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
          const Spacer(),
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDate: _date,
              );
              if (picked != null) {
                setState(() => _date = DateTime(picked.year, picked.month,
                    picked.day, _date.hour, _date.minute));
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('Cambiar'),
          ),
        ]),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
          label: Text(isEdit ? 'Guardar cambios' : 'Guardar'),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}
