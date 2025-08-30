import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../api/dio.dart';

double _asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
  return 0;
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
          '/households/${widget.householdId}/savings-goals/${widget.goalId}/summary');
      final txs = await dio.get(
          '/households/${widget.householdId}/savings-goals/${widget.goalId}/txns');
      setState(() {
        _summary = Map<String, dynamic>.from(sum.data as Map);
        _txns = (txs.data as List).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar meta')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addTxn({required bool deposit}) async {
    final ctrl = TextEditingController();
    final note = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(deposit ? 'Añadir depósito' : 'Registrar retiro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar')),
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(deposit ? 'Depósito registrado' : 'Retiro registrado'),
          ));
        }
      } on DioException catch (e) {
        final msg =
            e.response?.data is Map && (e.response!.data as Map)['message'] != null
                ? (e.response!.data as Map)['message'].toString()
                : (e.message ?? 'No se pudo guardar');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    }
  }

  Future<void> _deleteThisGoal() async {
    final name =
        widget.goalName ?? _summary?['goal']?['name']?.toString() ?? 'Meta';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text('¿Eliminar "$name" y todos sus movimientos de ahorro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm != true) return;

    final dio = ref.read(dioProvider);
    try {
      await dio.delete('/households/${widget.householdId}/savings-goals/${widget.goalId}');
      if (!mounted) return;
      Navigator.pop(context, true); // ← devolvemos true para avisar que se borró
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 403
          ? 'No tienes permisos para eliminar esta meta'
          : e.response?.data is Map && (e.response!.data as Map)['message'] != null
              ? (e.response!.data as Map)['message'].toString()
              : (e.message ?? 'No se pudo eliminar');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        widget.goalName ?? _summary?['goal']?['name']?.toString() ?? 'Meta';
    final saved = _asDouble(_summary?['saved']);
    final target = _asDouble(_summary?['target']);
    final pct = _asDouble(_summary?['progress']);

    DateTime? deadline;
    final dRaw = _summary?['goal']?['deadline'];
    if (dRaw is String) deadline = DateTime.tryParse(dRaw);
    if (dRaw is DateTime) deadline = dRaw;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ahorro: $name'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: _deleteThisGoal,
            tooltip: 'Eliminar meta',
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
            label: const Text('Depósito'),
          ),
          FloatingActionButton.extended(
            onPressed: () => _addTxn(deposit: false),
            icon: const Icon(Icons.remove),
            label: const Text('Retiro'),
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
                        Text(name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: target > 0 ? (saved / target).clamp(0, 1).toDouble() : 0,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${saved.toStringAsFixed(2)} / ${target.toStringAsFixed(2)}  (${pct.clamp(0, 100).toStringAsFixed(0)}%)',
                        ),
                        if (deadline != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Fecha límite: ${deadline.toLocal()}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Movimientos de ahorro',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_txns.isEmpty) const Text('Aún no hay transacciones.'),
                ..._txns.map((t) {
                  final isDep = t['type'] == 'DEPOSIT';
                  final amt = _asDouble(t['amount']);
                  DateTime? dt;
                  final raw = t['occursAt'];
                  if (raw is String) dt = DateTime.tryParse(raw);
                  if (raw is DateTime) dt = raw;
                  final when = dt != null
                      ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'
                      : '';

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(isDep ? Icons.trending_up : Icons.trending_down),
                      ),
                      title: Text(isDep ? 'Depósito' : 'Retiro'),
                      subtitle: Text([
                        when,
                        if ((t['note'] ?? '').toString().isNotEmpty) t['note'].toString()
                      ].join('  •  ')),
                      trailing: Text(
                        (isDep ? '+' : '-') + amt.toStringAsFixed(2),
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
