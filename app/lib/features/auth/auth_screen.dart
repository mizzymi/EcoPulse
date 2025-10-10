import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

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

  bool _obscurePass = true;

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
          icon: TextButton(
            onPressed: _loading ? null : _resetPasswordWithCode,
            child: Text(
              s.haveCodeCta,
              style: const TextStyle(color: Colors.black54),
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
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // Paleta (ajústala si quieres clavar otros tonos)
    const bg = Color(0xFFEAF8E5);      // fondo general
    const hero = Color(0xFFCFEBC7);    // banda superior
    const card = Color(0xFFD9F2D4);    // panel del formulario
    const green = Color(0xFF3FA357);   // CTA principal
    const greenDark = Color(0xFF2E7D45);

    final primaryLabel = _isLogin ? s.loginAction : s.registerAction;
    final secondaryLabel = _isLogin ? s.registerAction : s.loginAction;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ===== HERO (icono + título + subtítulo) =====
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: hero,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          'lib/assets/app_icon.svg',
                          height: 60,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.welcomeTitle, // p.ej. "Welcome"
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.welcomeSubtitle, // p.ej. "Sign in to your account or create a new one"
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== CARD DEL FORM =====
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: InputDecoration(
                              labelText: s.emailLabel,
                              hintText: s.enterYourEmail, // "Enter your email address"
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return s.enterYourEmail;
                              if (!RegExp(r'.+@.+\..+').hasMatch(t)) return s.invalidEmail;
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            decoration: InputDecoration(
                              labelText: s.passwordLabel,
                              hintText: s.enterYourPassword,
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 22,
                                ),
                                tooltip: _obscurePass ? 'Mostrar' : 'Ocultar',
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            obscureText: _obscurePass, // <— usa el flag
                            validator: (v) => (v ?? '').length < 6 ? s.minPasswordLen : null,
                          ),
                          const SizedBox(height: 16),

                          // Botón principal (verde)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : Text(
                                primaryLabel, // login/register
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          // Forgot password (solo en login)
                          if (_isLogin) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _loading ? null : _requestPasswordReset,
                              child: Text(
                                s.forgotPasswordCta,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],

                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Colors.black26)),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text(
                                  s.orLabel, // "OR"
                                  style: const TextStyle(color: Colors.black45),
                                ),
                              ),
                              const Expanded(child: Divider(color: Colors.black26)),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Botón secundario (outlined) que invierte el modo
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: green, width: 1.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor: green,
                              ),
                              onPressed:
                              _loading ? null : () => setState(() => _isLogin = !_isLogin),
                              child: Text(
                                secondaryLabel, // Create Account / Sign In
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ===== LEGALES =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text.rich(
                      TextSpan(
                        text: s.legalPrefix, // "By continuing, you agree to our "
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                        children: [
                          TextSpan(
                            text: s.termsOfService,
                            style: const TextStyle(
                              color: greenDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: ' ${s.andLabel} '), // "and"
                          TextSpan(
                            text: s.privacyPolicy,
                            style: const TextStyle(
                              color: greenDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
