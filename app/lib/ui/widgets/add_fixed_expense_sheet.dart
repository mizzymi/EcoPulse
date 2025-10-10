import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/dio.dart';
import '../../l10n/l10n.dart';

class AddFixedExpenseSheet extends ConsumerStatefulWidget {
  final String householdId;
  final Map<String, dynamic>? existing;

  const AddFixedExpenseSheet({
    super.key,
    required this.householdId,
    this.existing,
  });

  @override
  ConsumerState<AddFixedExpenseSheet> createState() =>
      _AddFixedExpenseSheetState();
}

class _AddFixedExpenseSheetState extends ConsumerState<AddFixedExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _conceptCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  // Recurrencia simple por defecto: mensual en día N
  String _type = 'EXPENSE';
  String _recurrenceMode = 'MONTHLY_BY_DAY'; // or 'ADVANCED_RRULE'
  int _dayOfMonth = 1; // 1..28(31) - permitimos 1..28 en UI básica para simplificar
  late final TextEditingController _rruleCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _conceptCtrl = TextEditingController(text: (e?['concept'] ?? e?['title'] ?? '').toString());
    _amountCtrl  = TextEditingController(text: (e?['amount'] ?? '').toString());
    _noteCtrl    = TextEditingController(text: (e?['notes'] ?? '').toString());
    _type        = (e?['type'] ?? 'EXPENSE').toString();

    if ((e?['rrule'] ?? '').toString().isNotEmpty) {
      _recurrenceMode = 'ADVANCED_RRULE';
    } else {
      _recurrenceMode = 'MONTHLY_BY_DAY';
    }
    _dayOfMonth = int.tryParse((e?['dayOfMonth'] ?? '1').toString()) ?? 1;
    _rruleCtrl  = TextEditingController(text: (e?['rrule'] ?? '').toString());
  }

  @override
  void dispose() {
    _conceptCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _rruleCtrl.dispose();
    super.dispose();
  }

  double? _parseAmount(String raw) {
    if (raw.trim().isEmpty) return null;
    return double.tryParse(raw.replaceAll(',', '.'));
  }

  Future<void> _onSave() async {
    final s = S.of(context);
    if (!_formKey.currentState!.validate()) return;

    final amount = _parseAmount(_amountCtrl.text);
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.invalidAmount ?? 'Importe inválido')),
      );
      return;
    }

    final dio = ref.read(dioProvider);

    final body = <String, dynamic>{
      'concept': _conceptCtrl.text.trim(),
      'amount': amount,
      'type': _type,
      if (_noteCtrl.text.trim().isNotEmpty) 'notes': _noteCtrl.text.trim(),
    };

    if (_recurrenceMode == 'ADVANCED_RRULE') {
      if (_rruleCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.requiredField ?? 'Campo obligatorio')),
        );
        return;
      }
      body['rrule'] = _rruleCtrl.text.trim(); // p.ej: FREQ=MONTHLY;BYMONTHDAY=5
    } else {
      // Mensual simple por día concreto:
      body['dayOfMonth'] = _dayOfMonth.clamp(1, 28);
    }

    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await dio.post('/households/${widget.householdId}/recurring', data: body);
      } else {
        final id = widget.existing!['id'];
        await dio.patch('/households/${widget.householdId}/recurring/$id', data: body);
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
                      ? (s.editFixedTitle ?? 'Editar gasto fijo')
                      : (s.addFixedTitle ?? 'Añadir gasto fijo'),
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

                InputDecorator(
                  decoration: InputDecoration(
                    labelText: s.recurrence ?? 'Recurrencia',
                    border: const OutlineInputBorder(),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              value: 'MONTHLY_BY_DAY',
                              groupValue: _recurrenceMode,
                              onChanged: (v) => setState(() => _recurrenceMode = v!),
                              title: Text(s.monthlyByDay ?? 'Mensual por día'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RadioListTile<String>(
                              value: 'ADVANCED_RRULE',
                              groupValue: _recurrenceMode,
                              onChanged: (v) => setState(() => _recurrenceMode = v!),
                              title: Text(s.advancedRrule ?? 'RRULE avanzado'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_recurrenceMode == 'MONTHLY_BY_DAY') ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.dayOfMonth ?? 'Día del mes'),
                                  const SizedBox(height: 6),
                                  Slider(
                                    min: 1,
                                    max: 28,
                                    divisions: 27,
                                    value: _dayOfMonth.toDouble().clamp(1, 28),
                                    label: _dayOfMonth.toString(),
                                    onChanged: (v) => setState(() => _dayOfMonth = v.toInt()),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 64,
                              child: TextFormField(
                                initialValue: _dayOfMonth.toString(),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) {
                                  final parsed = int.tryParse(v);
                                  if (parsed != null) {
                                    setState(() => _dayOfMonth = parsed.clamp(1, 28));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _rruleCtrl,
                          decoration: InputDecoration(
                            labelText: s.rrule ?? 'RRULE (iCal)',
                            hintText: 'FREQ=MONTHLY;BYMONTHDAY=5',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (_recurrenceMode == 'ADVANCED_RRULE' &&
                                (v == null || v.trim().isEmpty)) {
                              return s.requiredField ?? 'Campo obligatorio';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
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
