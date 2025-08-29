import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../api/dio.dart';

class JoinHouseholdScreen extends ConsumerStatefulWidget {
  const JoinHouseholdScreen({super.key});

  @override
  ConsumerState<JoinHouseholdScreen> createState() =>
      _JoinHouseholdScreenState();
}

class _JoinHouseholdScreenState extends ConsumerState<JoinHouseholdScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _status;

  @override
  Widget build(BuildContext context) {
    final dio = ref.watch(dioProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Unirse a una casa')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              decoration:
                  const InputDecoration(labelText: 'Código (ej. 6YQ9-DA)'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() {
                        _loading = true;
                        _error = null;
                        _status = null;
                      });
                      try {
                        final res = await dio.post('/households/join',
                            data: {'code': _ctrl.text.trim()});
                        setState(() {
                          _status = res.data['status'] as String;
                        });
                        if (!mounted) return;
                        if (_status == 'PENDING') {
                          showDialog(
                              context: context,
                              builder: (_) => const AlertDialog(
                                    title: Text('Solicitud enviada'),
                                    content: Text(
                                        'Quedó pendiente de validación. Te avisaremos al aprobarla.'),
                                  ));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('¡Unido a la casa!')));
                          Navigator.pop(context, true);
                        }
                      } on DioException catch (e) {
                        setState(() {
                          _error =
                              e.response?.data?['message'] ?? 'Error de red';
                        });
                      } catch (e) {
                        setState(() {
                          _error = e.toString();
                        });
                      } finally {
                        setState(() {
                          _loading = false;
                        });
                      }
                    },
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Unirme'),
            ),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Estado: $_status'),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
