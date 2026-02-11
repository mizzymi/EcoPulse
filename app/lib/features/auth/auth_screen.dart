import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/dio.dart';
import '../../core/app_reloader.dart';
import '../../providers/auth_token_provider.dart';
import '../../ui/theme/app_theme.dart';

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

  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();

    _termsTap = TapGestureRecognizer()
      ..onTap = () => _openUrl('https://apps.reimii.com/terms/');

    _privacyTap = TapGestureRecognizer()
      ..onTap = () => _openUrl('https://apps.reimii.com');
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();

    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showTopToast(String text) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final topPad = MediaQuery.of(context).padding.top;

    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(12, topPad + 12, 12, 0),
        dismissDirection: DismissDirection.up,
        duration: const Duration(seconds: 2),
      ),
    );
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

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        final ok2 = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!ok2 && mounted) _showTopToast('No se pudo abrir el enlace');
      }
    } catch (_) {
      if (mounted) _showTopToast('No se pudo abrir el enlace');
    }
  }

  Future<void> _submit() async {
    final s = S.of(context);
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final dio = ref.read(dioProvider);

    try {
      final path = _isLogin ? '/auth/login' : '/auth/register';
      final res = await dio.post(
        path,
        data: {
          'email': _emailCtrl.text.trim(),
          'password': _passCtrl.text,
        },
      );

      final token = res.data['accessToken']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception(s.missingTokenResponse);
      }

      await ref.read(authTokenControllerProvider).set(token);
      AppReloader.restart(context);

      if (!mounted) return;
      _showTopToast(_isLogin ? s.loginSuccess : s.registerSuccess);
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      if (_isLogin && status == 401) {
        if (mounted) _showTopToast('Correo o contraseña equivocado');
        return;
      }

      String msg = s.authErrorGeneric;
      final apiMsg = _extractApiMessage(e.response?.data);
      if (apiMsg.isNotEmpty) {
        msg = apiMsg;
      } else if (e.response?.statusMessage != null &&
          e.response!.statusMessage!.isNotEmpty) {
        msg = e.response!.statusMessage!;
      }

      if (mounted) _showTopToast(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                        if (context.mounted) _showTopToast(s.minPasswordLen);
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
                        final apiMsg = _extractApiMessage(e.response?.data);
                        final msg =
                            apiMsg.isNotEmpty ? apiMsg : s.resetPasswordFailed;
                        if (context.mounted) _showTopToast(msg);
                      } finally {
                        if (context.mounted)
                          setStateDialog(() => saving = false);
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

    codeCtrl.dispose();
    passCtrl.dispose();

    if (ok == true && mounted) _showTopToast(s.passwordUpdatedToast);
  }

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
                        if (context.mounted) _showTopToast(s.invalidEmail);
                        return;
                      }

                      setStateDialog(() => sending = true);
                      try {
                        await dio.post('/auth/forgot-password',
                            data: {'email': email});
                        if (context.mounted) Navigator.pop(ctx, true);
                      } on DioException catch (e) {
                        final apiMsg = _extractApiMessage(e.response?.data);
                        final msg =
                            apiMsg.isNotEmpty ? apiMsg : s.forgotPasswordFailed;
                        if (context.mounted) _showTopToast(msg);
                      } finally {
                        if (context.mounted)
                          setStateDialog(() => sending = false);
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

    ctrl.dispose();

    if (ok == true && mounted) _showTopToast(s.forgotPasswordAfterMsg);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final primaryLabel = _isLogin ? s.loginAction : s.registerAction;
    final secondaryLabel = _isLogin ? s.registerAction : s.loginAction;

    final surface = cs.surface;
    final surface2 = cs.surfaceVariant;
    final border = cs.outlineVariant;
    final textMain = cs.onSurface;
    final textSub = cs.onSurfaceVariant;

    return Scaffold(
      backgroundColor: cs.background, // neutral app background
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HERO
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: surface2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border, width: 1),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          'lib/assets/app_icon.svg',
                          height: 60,
                          colorFilter:
                              ColorFilter.mode(cs.primary, BlendMode.srcIn),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.welcomeTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: textMain,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.welcomeSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textSub,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // FORM CARD
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: InputDecoration(
                              labelText: s.emailLabel,
                              hintText: s.enterYourEmail,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return s.enterYourEmail;
                              if (!RegExp(r'.+@.+\..+').hasMatch(t))
                                return s.invalidEmail;
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passCtrl,
                            decoration: InputDecoration(
                              labelText: s.passwordLabel,
                              hintText: s.enterYourPassword,
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass),
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 22,
                                ),
                                tooltip: _obscurePass ? 'Mostrar' : 'Ocultar',
                              ),
                            ),
                            obscureText: _obscurePass,
                            validator: (v) =>
                                (v ?? '').length < 6 ? s.minPasswordLen : null,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: cs.onPrimary,
                                      ),
                                    )
                                  : Text(
                                      primaryLabel,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                            ),
                          ),
                          if (_isLogin) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed:
                                  _loading ? null : _requestPasswordReset,
                              child: Text(s.forgotPasswordCta),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed:
                                  _loading ? null : _resetPasswordWithCode,
                              child: Text(s.haveCodeCta),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: Divider(color: border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: Text(
                                  s.orLabel,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: textSub),
                                ),
                              ),
                              Expanded(child: Divider(color: border)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: cs.primary, width: 1.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _loading
                                  ? null
                                  : () => setState(() => _isLogin = !_isLogin),
                              child: Text(
                                secondaryLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // LEGAL
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text.rich(
                      TextSpan(
                        text: s.legalPrefix,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: textSub,
                        ),
                        children: [
                          TextSpan(
                            text: s.termsOfService,
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _termsTap,
                          ),
                          TextSpan(text: ' ${s.andLabel} '),
                          TextSpan(
                            text: s.privacyPolicy,
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _privacyTap,
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
