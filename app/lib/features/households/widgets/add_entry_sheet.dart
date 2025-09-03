// BottomSheet para crear o editar un movimiento del ledger.
// Reutilizable: si 'existing' es null -> crea, si no -> edita.
//
// NOTAS:
// - Usa dioProvider para golpear endpoints de /entries.
// - Devuelve el movimiento creado/actualizado vía Navigator.pop(context, res.data);
//   para que la pantalla principal decida refrescar.

import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/dio.dart';

class AddEntrySheet extends ConsumerStatefulWidget {
  final String householdId;
  final Map<String, dynamic>? existing;
  const AddEntrySheet({super.key, required this.householdId, this.existing});

  @override
  ConsumerState<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<AddEntrySheet> {
  late String _type; // 'INCOME' o 'EXPENSE'
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late DateTime _date;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Inicializa con datos existentes o valores por defecto
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

  /// Crea o edita según corresponda.
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
        // Crear
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
        // Editar
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
        // Encabezado + selector tipo (Gasto/Ingreso)
        Row(children: [
          Text(isEdit ? 'Editar movimiento' : 'Nuevo movimiento',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Spacer(),
        ]),
        Row(
          children: [
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
          ],
        ),
        const SizedBox(height: 12),
        // Importe
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

        // Categoría (opcional)
        TextField(
          controller: _categoryCtrl,
          decoration: const InputDecoration(
            labelText: 'Categoría (opcional)',
            hintText: 'Comida, Transporte, Nómina…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // Nota (opcional)
        TextField(
          controller: _noteCtrl,
          decoration: const InputDecoration(
            labelText: 'Nota (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // Fecha y botón para cambiarla
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

        // Guardar
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
        const SizedBox(height: 80),
      ]),
    );
  }
}
