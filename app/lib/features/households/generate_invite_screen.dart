import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/dio.dart';

class GenerateInviteScreen extends ConsumerStatefulWidget {
  final String householdId;
  final String? householdName;
  const GenerateInviteScreen(
      {super.key, required this.householdId, this.householdName});

  @override
  ConsumerState<GenerateInviteScreen> createState() =>
      _GenerateInviteScreenState();
}

class _GenerateInviteScreenState extends ConsumerState<GenerateInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _expiresCtrl = TextEditingController(text: '48');
  final _maxUsesCtrl = TextEditingController(text: '10');
  bool _requireApproval = true;
  bool _loading = false;

  String? _code;
  DateTime? _expiresAt;

  @override
  void dispose() {
    _expiresCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);
    try {
      final res = await dio.post(
        '/households/${widget.householdId}/invites',
        data: {
          'expiresInHours': int.parse(_expiresCtrl.text.trim()),
          'maxUses': int.parse(_maxUsesCtrl.text.trim()),
          'requireApproval': _requireApproval,
        },
      );
      setState(() {
        _code = res.data['code']?.toString();
        final exp = res.data['expiresAt']?.toString();
        _expiresAt = exp != null ? DateTime.tryParse(exp) : null;
      });
    } on DioException catch (e) {
      final msg = e.response?.data is Map &&
              (e.response!.data as Map)['message'] != null
          ? (e.response!.data as Map)['message'].toString()
          : (e.message ?? 'Error al generar el código');
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
    final title = widget.householdName != null
        ? 'Invitar a "${widget.householdName}"'
        : 'Generar código de invitación';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_code == null) ...[
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _expiresCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Caducidad (horas)',
                      hintText: 'Ej. 48',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Escribe las horas';
                      final n = int.tryParse(t);
                      if (n == null || n < 1 || n > 720)
                        return 'Entre 1 y 720 horas';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _maxUsesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Usos máximos',
                      hintText: 'Ej. 10',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Escribe un número';
                      final n = int.tryParse(t);
                      if (n == null || n < 1 || n > 999) return 'Entre 1 y 999';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _requireApproval,
                    onChanged: (v) => setState(() => _requireApproval = v),
                    title: const Text('Requiere aprobación del admin'),
                    subtitle: const Text(
                        'Si está activo, las uniones quedarán en PENDING'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _loading ? null : _generate,
                    icon: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.qr_code_2),
                    label: const Text('Generar código'),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text('Código generado', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal, width: 1.2),
              ),
              child: SelectableText(
                _code!,
                style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 2,
                    fontFeatures: [FontFeature.tabularFigures()]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            if (_expiresAt != null)
              Text(
                'Caduca: ${_expiresAt!.toLocal()}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _code!));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Código copiado')));
                      }
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, {
                      'code': _code,
                      'expiresAt': _expiresAt?.toIso8601String()
                    }),
                    icon: const Icon(Icons.check),
                    label: const Text('Listo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _code = null;
                  _expiresAt = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Generar otro código'),
            ),
          ],
        ],
      ),
    );
  }
}
