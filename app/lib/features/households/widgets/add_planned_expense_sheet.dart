// BottomSheet for creating or editing a planned expense.
// Reusable: if 'existing' is null -> create, else -> edit.
//
// UI: AddEntrySheet-like (outlined inputs + segmented buttons)
// Added:
// ✅ Money type selector: CASH / CARD / BANK
// ✅ Sends 'accountType' in payload (adjust key if your backend expects another)

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';

class AddPlannedExpenseSheet extends ConsumerStatefulWidget {
  final String householdId;
  final String month; // YYYY-MM
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
  final _conceptCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  late DateTime _dueDate;
  late String _type; // EXPENSE | INCOME
  late String _moneyType; // CASH | CARD | BANK

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;

    _type = (ex?['type']?.toString() ?? 'EXPENSE').toUpperCase();

    // Try to read money type from several possible keys
    final mt = (ex?['accountType'] ??
            ex?['moneyType'] ??
            ex?['paymentType'] ??
            ex?['account']?['type'])
        ?.toString()
        .toUpperCase();

    _moneyType = (mt == 'CASH' || mt == 'CARD' || mt == 'BANK') ? mt! : 'CASH';

    _conceptCtrl.text = (ex?['concept'] ?? ex?['title'] ?? '').toString();

    final amt = ex?['amount'];
    _amountCtrl.text = amt == null
        ? ''
        : (amt is num ? amt.toStringAsFixed(2) : amt.toString());

    _notesCtrl.text = (ex?['notes'] ?? ex?['note'] ?? '').toString();
    _categoryCtrl.text =
        (ex?['category'] ?? ex?['categoryId'] ?? '').toString();

    _dueDate = DateTime.tryParse((ex?['dueDate'] ?? '').toString()) ??
        DateTime.tryParse((ex?['occursAt'] ?? '').toString()) ??
        DateTime.now();
  }

  @override
  void dispose() {
    _conceptCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  String _extractApiMessage(dynamic data) {
    if (data is Map) {
      final err = data['error'];
      if (err != null) return err.toString();
      final msg = data['message'];
      if (msg != null) return msg.toString();
    }
    return '';
  }

  InputDecoration _deco({
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _submit() async {
    final s = S.of(context);

    final concept = _conceptCtrl.text.trim();
    if (concept.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.requiredField)));
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.invalidAmountToast)));
      return;
    }

    setState(() => _loading = true);
    final dio = ref.read(dioProvider);

    try {
      final payload = <String, dynamic>{
        'concept': concept,
        'type': _type, // INCOME | EXPENSE
        'amount': amount,
        'dueDate': _dueDate.toIso8601String(),
        'month': widget.month,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'category': _categoryCtrl.text.trim().isEmpty
            ? null
            : _categoryCtrl.text.trim(),

        // ✅ Money type field (adjust key if needed)
        'accountType': _moneyType, // CASH | CARD | BANK
      };

      if (widget.existing == null) {
        await dio.post(
          '/households/${widget.householdId}/planned',
          data: payload,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        final id = widget.existing!['id'].toString();
        await dio.patch(
          '/households/${widget.householdId}/planned/$id',
          data: payload,
        );
        if (mounted) Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      final apiMsg = _extractApiMessage(e.response?.data);
      final msg = apiMsg.isNotEmpty ? apiMsg : (e.message ?? s.errorSave);
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
    final s = S.of(context);
    final isEdit = widget.existing != null;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    ButtonStyle segmentedStyle() => ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return cs.primary.withOpacity(.14);
            }
            return cs.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return cs.primary;
            return cs.onSurfaceVariant;
          }),
          iconColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return cs.primary;
            return cs.onSurfaceVariant;
          }),
          side: WidgetStateProperty.all(BorderSide(color: cs.outlineVariant)),
        );

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
          Row(
            children: [
              Text(
                isEdit ? s.editPlannedTitle : s.newPlannedTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),

          // Type selector
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'EXPENSE',
                      label: Text(s.expenseGeneric),
                      icon: const Icon(Icons.trending_down),
                    ),
                    ButtonSegment(
                      value: 'INCOME',
                      label: Text(s.incomeGeneric),
                      icon: const Icon(Icons.trending_up),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (sel) =>
                      setState(() => _type = sel.first),
                  style: segmentedStyle(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ Money type selector
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'CASH',
                      label: Text('Cash'),
                      icon: Icon(Icons.payments_outlined),
                    ),
                    ButtonSegment(
                      value: 'CARD',
                      label: Text('Card'),
                      icon: Icon(Icons.credit_card_outlined),
                    ),
                    ButtonSegment(
                      value: 'BANK',
                      label: Text('Bank'),
                      icon: Icon(Icons.account_balance_outlined),
                    ),
                  ],
                  selected: {_moneyType},
                  onSelectionChanged: (sel) =>
                      setState(() => _moneyType = sel.first),
                  style: segmentedStyle(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _conceptCtrl,
            textInputAction: TextInputAction.next,
            decoration: _deco(
              label: s.concept,
              hint: null,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: _deco(label: s.amountLabel, hint: s.amountHint),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _categoryCtrl,
            textInputAction: TextInputAction.next,
            decoration: _deco(
              label: s.categoryOptionalLabel,
              hint: s.categoryOptionalHint,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _notesCtrl,
            minLines: 1,
            maxLines: 3,
            decoration: _deco(
              label: s.noteOptionalLabel,
              hint: s.noteOptionalHint,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Text(s.dateLabel(_dueDate.toLocal().toString().split(' ').first)),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: _dueDate,
                  );
                  if (picked != null) {
                    setState(() => _dueDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          _dueDate.hour,
                          _dueDate.minute,
                        ));
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(s.changeDate),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
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
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
