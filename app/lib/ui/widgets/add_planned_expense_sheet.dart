import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/dio.dart';
import '../../l10n/l10n.dart';

class AddPlannedExpenseSheet extends ConsumerStatefulWidget {
  final String householdId;
  final String month; // YYYY-MM (solo informativo para el BE si lo necesita)
  final Map<String, dynamic>? existing;

  const AddPlannedExpenseSheet({
    super.key,
    required this.householdId,
    required this.month,
    this.existing,
  });

  @override
  ConsumerState<AddPlannedExpenseSheet> createState() =>
      _AddPlannedExpenseSheetState();
}

class _AddPlannedExpenseSheetState
    extends ConsumerState<AddPlannedExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _conceptCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  String _type = 'EXPENSE';
  DateTime? _dueDate; // fecha prevista de cargo/pago
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _conceptCtrl = TextEditingController(text: (e?['concept'] ?? e?['title'] ?? '').toString());
    _amountCtrl  = TextEditingController(text: (e?['amount'] ?? '').toString());
    _noteCtrl    = TextEditingController(text: (e?['notes'] ?? '').toString());
    _type        = (e?['type'] ?? 'EXPENSE').toString();
    final dueStr = (e?['dueDate'] ?? e?['occursAt'])?.toString();
    _dueDate     = _tryParseDate(dueStr);
  }

  @override
  void dispose() {
    _conceptCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  DateTime? _tryParseDate(String? isoLike) {
    if (isoLike == null || isoLike.isEmpty) return null;
    try { return DateTime.parse(isoLike); } catch (_) { return null; }
  }

  String _fmtDate(DateTime d) {
    // YYYY-MM-DD
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  double? _parseAmount(String raw) {
    if (raw.trim().isEmpty) return null;
    final normalized = raw.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dueDate ?? DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _onSave() async {
    final s = S.of(context);
    if (!_formKey.currentState!.validate()) return;

    final amount = _parseAmount(_amountCtrl.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.invalidAmount ?? 'Importe inválido')),
      );
      return;
    }
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.selectDate ?? 'Selecciona una fecha')),
      );
      return;
    }

    final dio = ref.read(dioProvider);
    final body = {
      'concept': _conceptCtrl.text.trim(),
      'amount': amount,
      'type': _type,
      'dueDate': _fmtDate(_dueDate!),
      if (_noteCtrl.text.trim().isNotEmpty) 'notes': _noteCtrl.text.trim(),
      // el BE puede ignorar/usar `month` según su modelo
      'month': widget.month,
    };

    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await dio.post('/households/${widget.householdId}/planned', data: body);
      } else {
        final id = widget.existing!['id'];
        await dio.patch('/households/${widget.householdId}/planned/$id', data: body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?.toString() ?? (s.actionFailed ?? 'No se pudo completar');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isEdit = widget.existing != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  isEdit
                      ? (s.editPlannedTitle ?? 'Editar previsto')
                      : (s.addPlannedTitle ?? 'Añadir previsto'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _conceptCtrl,
                  decoration: InputDecoration(
                    labelText: s.concept ?? 'Concepto',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? (s.requiredField ?? 'Campo obligatorio') : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                        decoration: InputDecoration(
                          labelText: s.amount ?? 'Importe',
                          hintText: '0.00',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final parsed = _parseAmount(v ?? '');
                          if (parsed == null || parsed < 0) {
                            return s.invalidAmount ?? 'Importe inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: s.type ?? 'Tipo',
                          border: const OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _type,
                            items: const [
                              DropdownMenuItem(value: 'EXPENSE', child: Text('Gasto')),
                              DropdownMenuItem(value: 'INCOME', child: Text('Ingreso')),
                            ],
                            onChanged: (v) => setState(() => _type = v ?? 'EXPENSE'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: s.date ?? 'Fecha prevista',
                      border: const OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_dueDate == null ? (s.selectDate ?? 'Seleccionar') : _fmtDate(_dueDate!)),
                        const Icon(Icons.calendar_today_outlined),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(
                    labelText: s.note ?? 'Nota (opcional)',
                    border: const OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context, false),
                        child: Text(s.cancel ?? 'Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _onSave,
                        child: Text(isEdit ? (s.save ?? 'Guardar') : (s.add ?? 'Añadir')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
