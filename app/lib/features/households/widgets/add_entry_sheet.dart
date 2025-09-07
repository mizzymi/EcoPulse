// BottomSheet para crear o editar un movimiento del ledger.
// Reutilizable: si 'existing' es null -> crea, si no -> edita.

import 'dart:math';
import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

  String _fmtDate(BuildContext context, DateTime d) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).format(d.toLocal());
  }

  /// Crea o edita según corresponda.
  Future<void> _submit() async {
    final s = S.of(context);
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.invalidAmountToast)));
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
          : (e.message ?? s.errorSave);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;
    final s = S.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: max(bottom, 16),
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encabezado + selector tipo (Gasto/Ingreso)
          Row(
            children: [
              Text(
                isEdit ? s.editMovementTitle : s.newMovementTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
            ],
          ),
          Row(
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'EXPENSE',
                    label: Text(s.expenseGeneric), // ya definida antes
                    icon: const Icon(Icons.trending_down),
                  ),
                  ButtonSegment(
                    value: 'INCOME',
                    label: Text(s.incomeGeneric),
                    icon: const Icon(Icons.trending_up),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) =>
                    setState(() => _type = selection.first),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Importe
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: s.amountLabel,
              hintText: s.amountHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Categoría (opcional)
          TextField(
            controller: _categoryCtrl,
            decoration: InputDecoration(
              labelText: s.categoryOptionalLabel,
              hintText: s.categoryOptionalHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Nota (opcional)
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: s.noteOptionalLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Fecha y botón para cambiarla
          Row(
            children: [
              Text(s.dateLabel(_fmtDate(context, _date))),
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
                    setState(() => _date = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          _date.hour,
                          _date.minute,
                        ));
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(s.changeDate),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Guardar
          FilledButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(isEdit ? s.saveChanges : s.save),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
