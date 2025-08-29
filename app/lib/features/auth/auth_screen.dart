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

      ref.read(authTokenProvider.notifier).state = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(_isLogin ? 'Sesión iniciada' : 'Registro completado')),
        );
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
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Introduce tu email';
                    if (!RegExp(r'.+@.+\..+').hasMatch(t))
                      return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Contraseña', border: OutlineInputBorder()),
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
                          child: CircularProgressIndicator(strokeWidth: 2))
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
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
