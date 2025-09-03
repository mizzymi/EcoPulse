import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/dio.dart';
import '../../providers/auth_token_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);

    try {
      final path = _isLogin ? '/auth/login' : '/auth/register';
      final res = await dio.post(path, data: {
        'email': _emailCtrl.text.trim(),
        'password': _passCtrl.text,
      });

      final token = res.data['accessToken']?.toString();
      if (token == null) throw Exception('Respuesta sin token');

      // guarda token en estado y almacenamiento
      ref.read(authTokenProvider.notifier).state = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLogin ? 'Sesión iniciada' : 'Registro completado'),
          ),
        );
        // Opcional: Navigator.pop(context); // si quieres cerrar la pantalla
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map &&
              (e.response!.data as Map)['message'] != null
          ? (e.response!.data as Map)['message'].toString()
          : (e.message ?? 'Error de autenticación');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===== Olvidé mi contraseña: solicitar enlace/código =====
  Future<void> _requestPasswordReset() async {
    final dio = ref.read(dioProvider);
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    bool sending = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Recuperar contraseña'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      final email = ctrl.text.trim();
                      if (!RegExp(r'.+@.+\..+').hasMatch(email)) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email inválido')),
                          );
                        }
                        return;
                      }
                      setStateDialog(() => sending = true);
                      try {
                        await dio.post('/auth/forgot-password', data: {
                          'email': email,
                        });
                        if (context.mounted) Navigator.pop(ctx, true);
                      } on DioException catch (e) {
                        final msg = e.response?.data is Map &&
                                (e.response!.data as Map)['message'] != null
                            ? (e.response!.data as Map)['message'].toString()
                            : (e.message ??
                                'No se pudo iniciar la recuperación');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setStateDialog(() => sending = false);
                        }
                      }
                    },
              child: sending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar enlace/código'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Si el email existe, te enviamos instrucciones para recuperar tu contraseña.'),
        ),
      );
    }
  }

  // ===== Restablecer con código/token =====
  Future<void> _resetPasswordWithCode() async {
    final dio = ref.read(dioProvider);
    final codeCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool saving = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Restablecer contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código / Token',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final token = codeCtrl.text.trim();
                      final newPass = passCtrl.text;
                      if (newPass.length < 6) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Mínimo 6 caracteres')),
                          );
                        }
                        return;
                      }
                      setStateDialog(() => saving = true);
                      try {
                        await dio.post('/auth/reset-password', data: {
                          'token': token,
                          'password': newPass,
                        });
                        if (context.mounted) Navigator.pop(ctx, true);
                      } on DioException catch (e) {
                        final msg = e.response?.data is Map &&
                                (e.response!.data as Map)['message'] != null
                            ? (e.response!.data as Map)['message'].toString()
                            : (e.message ?? 'No se pudo restablecer');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setStateDialog(() => saving = false);
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada. Inicia sesión.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Iniciar sesión' : 'Crear cuenta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Introduce tu email';
                      if (!RegExp(r'.+@.+\..+').hasMatch(t)) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) =>
                        (v ?? '').length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isLogin ? 'Entrar' : 'Registrarme'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin
                        ? '¿No tienes cuenta? Crea una'
                        : '¿Ya tienes cuenta? Inicia sesión'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : _requestPasswordReset,
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                  TextButton(
                    onPressed: _loading ? null : _resetPasswordWithCode,
                    child: const Text('Ya tengo un código'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
