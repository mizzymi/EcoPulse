import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../api/dio.dart';
import 'savings_goal_detail_screen.dart';

double _asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
  return 0;
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
      final msg = e.response?.data is Map &&
              (e.response!.data as Map)['message'] != null
          ? (e.response!.data as Map)['message'].toString()
          : (e.message ?? 'Error al cargar objetivos');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreate() async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    DateTime? deadline;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Nueva meta de ahorro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                controller: nameCtrl,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Objetivo (€)',
                  border: OutlineInputBorder(),
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
                          ? 'Sin fecha límite'
                          : 'Límite: ${deadline!.year}-${deadline!.month.toString().padLeft(2, '0')}-${deadline!.day.toString().padLeft(2, '0')}',
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
                    label: const Text('Elegir fecha'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Crear'),
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
            : (e.message ?? 'No se pudo crear');
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    }
  }

  Future<void> _deleteGoal(Map<String, dynamic> g) async {
    final id = g['id'].toString();
    final name = g['name']?.toString() ?? 'meta';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text('¿Eliminar "$name" y todos sus movimientos de ahorro?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton.tonal(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm != true) return;

    final dio = ref.read(dioProvider);
    try {
      await dio.delete('/households/${widget.householdId}/savings-goals/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meta "$name" eliminada')),
      );
      await _load();
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 403
          ? 'No tienes permisos para eliminar esta meta'
          : e.response?.data is Map &&
                  (e.response!.data as Map)['message'] != null
              ? (e.response!.data as Map)['message'].toString()
              : (e.message ?? 'No se pudo eliminar');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.householdName ?? 'Casa';
    return Scaffold(
      appBar: AppBar(
        title: Text('Ahorro – $name'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Nueva meta'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text('Sin metas. Crea la primera con el botón +'),
                )
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
                        title: Text(g['name']?.toString() ?? 'Meta'),
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
                              '${saved.toStringAsFixed(2)} / ${target.toStringAsFixed(2)}  (${pct.toStringAsFixed(0)}%)',
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
                              const SnackBar(content: Text('Meta eliminada')),
                            );
                          }
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'delete') _deleteGoal(g);
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline),
                                  SizedBox(width: 8),
                                  Text('Eliminar'),
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
