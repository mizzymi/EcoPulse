import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/dio.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String code;
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.code,
    required this.email,
  });

  static Route<void> route({required String code, required String email}) {
    return MaterialPageRoute(
      builder: (_) => ResetPasswordScreen(code: code, email: email),
    );
  }

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = S.of(context);
    final newPass = _passCtrl.text.trim();

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.minPasswordLen)),
      );
      return;
    }

    setState(() => _saving = true);
    final dio = ref.read(dioProvider);

    try {
      await dio.post('/auth/reset-password', data: {
        'token': widget.code,
        'password': newPass,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.passwordUpdatedToast)),
      );
      Navigator.of(context).pop();
    } on DioException catch (e) {
      final msg = e.response?.data is Map &&
              (e.response!.data as Map)['message'] != null
          ? (e.response!.data as Map)['message'].toString()
          : (e.message ?? s.resetPasswordFailed);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const inputFill = Colors.white;

    InputDecoration deco({
      required String label,
      String? hint,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: inputFill,
        suffixIcon: suffixIcon,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.resetPasswordTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.email.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.email,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              enableSuggestions: false,
              autocorrect: false,
              inputFormatters: [LengthLimitingTextInputFormatter(64)],
              onSubmitted: (_) => _saving ? null : _submit(),
              style: const TextStyle(color: Colors.black87),
              decoration: deco(
                label: s.newPasswordLabel,
                hint: s.enterYourPassword,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon:
                      Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.changeAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
