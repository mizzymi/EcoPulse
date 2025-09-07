import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String _normalize(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  String _beautify(String normalized) {
    final b = StringBuffer();
    for (int i = 0; i < normalized.length; i++) {
      if (i > 0 && i % 4 == 0) b.write('-');
      b.write(normalized[i]);
    }
    return b.toString();
  }

  String _extractError(BuildContext context, Object e) {
    final s = S.of(context);
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['message'] != null) return d['message'].toString();
      if (d is String && d.isNotEmpty) return d;
      return e.message ?? s.networkError;
    }
    return e.toString();
  }

  Future<void> _join() async {
    final s = S.of(context);
    setState(() {
      _loading = true;
      _error = null;
      _status = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final normalized = _normalize(_ctrl.text);

      if (normalized.length != 8) {
        throw Exception(s.codeMustBe8);
      }

      final res = await dio.post('/households/join-by-code', data: {
        'code': normalized,
      });

      final data = res.data is Map ? (res.data as Map) : {};
      final status = data['status']?.toString() ?? 'APPROVED';
      setState(() => _status = status);

      if (!mounted) return;

      if (status == 'PENDING') {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(s.requestSentTitle),
            content: Text(s.requestSentBody),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.joinedToast)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = _extractError(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final raw = _ctrl.text;
      final normalized = _normalize(raw);
      final pretty = _beautify(normalized);
      if (raw != pretty) {
        final sel = pretty.length;
        _ctrl.value = TextEditingValue(
          text: pretty,
          selection: TextSelection.collapsed(offset: sel),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dioProvider);
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.joinByCodeTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
              ],
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: s.codeFieldLabel(s.codeExample),
                hintText: s.codeFieldHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _join,
              icon: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(s.joinAction),
            ),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(s.statusLabel(_status!)),
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
