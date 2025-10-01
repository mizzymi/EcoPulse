import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final s = S.of(context);
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
      if (token == null || token.isEmpty)
        throw Exception(s.missingTokenResponse);

      await ref.read(authTokenControllerProvider).set(token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isLogin ? s.loginSuccess : s.registerSuccess)),
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map &&
              (e.response!.data as Map)['message'] != null
          ? (e.response!.data as Map)['message'].toString()
          : (e.message ?? s.authErrorGeneric);
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
    final s = S.of(context);
    final dio = ref.read(dioProvider);
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    bool sending = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(s.forgotPasswordTitle),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: s.emailLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      final email = ctrl.text.trim();
                      if (!RegExp(r'.+@.+\..+').hasMatch(email)) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.invalidEmail)),
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
                            : (e.message ?? s.forgotPasswordFailed);
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
                  : Text(s.sendResetLink),
            ),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.forgotPasswordAfterMsg)),
      );
    }
  }

  // ===== Restablecer con código/token =====
  Future<void> _resetPasswordWithCode() async {
    final s = S.of(context);
    final dio = ref.read(dioProvider);
    final codeCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool saving = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(s.resetPasswordTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: InputDecoration(
                  labelText: s.codeTokenLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: s.newPasswordLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final tokenOrCode = codeCtrl.text.trim();
                      final newPass = passCtrl.text;
                      if (newPass.length < 6) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.minPasswordLen)),
                          );
                        }
                        return;
                      }
                      setStateDialog(() => saving = true);
                      try {
                        await dio.post('/auth/reset-password', data: {
                          'token': tokenOrCode,
                          'password': newPass,
                        });
                        if (context.mounted) Navigator.pop(ctx, true);
                      } on DioException catch (e) {
                        final msg = e.response?.data is Map &&
                                (e.response!.data as Map)['message'] != null
                            ? (e.response!.data as Map)['message'].toString()
                            : (e.message ?? s.resetPasswordFailed);
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
                  : Text(s.changeAction),
            ),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.passwordUpdatedToast)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? s.loginTitle : s.registerTitle),
      ),
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
                    decoration: InputDecoration(
                      labelText: s.emailLabel,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return s.enterYourEmail;
                      if (!RegExp(r'.+@.+\..+').hasMatch(t)) {
                        return s.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    decoration: InputDecoration(
                      labelText: s.passwordLabel,
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) =>
                        (v ?? '').length < 6 ? s.minPasswordLen : null,
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
                        : Text(_isLogin ? s.loginAction : s.registerAction),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _isLogin = !_isLogin),
                    child:
                        Text(_isLogin ? s.noAccountCta : s.alreadyAccountCta),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : _requestPasswordReset,
                    child: Text(s.forgotPasswordCta),
                  ),
                  TextButton(
                    onPressed: _loading ? null : _resetPasswordWithCode,
                    child: Text(s.haveCodeCta),
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
