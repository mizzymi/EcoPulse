import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../api/dio.dart';

class CreateHouseholdScreen extends ConsumerStatefulWidget {
  const CreateHouseholdScreen({super.key});

  @override
  ConsumerState<CreateHouseholdScreen> createState() =>
      _CreateHouseholdScreenState();
}

class _CreateHouseholdScreenState extends ConsumerState<CreateHouseholdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController(text: 'EUR');
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);

    try {
      final res = await dio.post('/households', data: {
        'name': _nameCtrl.text.trim(),
        'currency': _currencyCtrl.text.trim().toUpperCase(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Casa creada correctamente')),
        );
        Navigator.pop(
            context, res.data);
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map &&
              (e.response!.data as Map)['message'] != null
          ? (e.response!.data as Map)['message'].toString()
          : (e.message ?? 'Error al crear la casa');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Crear casa')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la casa',
                hintText: 'Ej. Piso Calle Mayor',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Escribe un nombre';
                if (t.length < 3) return 'Mínimo 3 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currencyCtrl,
              decoration: const InputDecoration(
                labelText: 'Moneda (ISO-4217)',
                hintText: 'EUR, USD, GBP…',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              maxLength: 3,
              textCapitalization: TextCapitalization.characters,
              validator: (v) {
                final t = (v ?? '').trim().toUpperCase();
                final ok = RegExp(r'^[A-Z]{3}$').hasMatch(t);
                if (!ok) return 'Usa un código de 3 letras (ej. EUR)';
                return null;
              },
              onChanged: (v) {
                final up = v.toUpperCase();
                if (up != v) {
                  final sel = _currencyCtrl.selection;
                  _currencyCtrl.value =
                      TextEditingValue(text: up, selection: sel);
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add),
              label: const Text('Crear casa'),
            ),
          ],
        ),
      ),
    );
  }
}
