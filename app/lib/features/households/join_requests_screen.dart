import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../api/dio.dart';

class JoinRequestsScreen extends ConsumerStatefulWidget {
  const JoinRequestsScreen({super.key, required this.householdId});
  final String householdId;

  @override
  ConsumerState<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends ConsumerState<JoinRequestsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final dio = ref.read(dioProvider);
    final res = await dio.get(
      '/households/${widget.householdId}/join-requests',
      queryParameters: {'status': 'PENDING'},
    );
    final data = res.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const [];
  }

  String _fmtDateLocalized(BuildContext context, String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      final locale = Localizations.localeOf(context).toString();
      return DateFormat.yMd(locale).add_Hm().format(d);
    } catch (_) {
      return iso;
    }
  }

  Future<void> _decide({
    required String reqId,
    required bool approve,
  }) async {
    final dio = ref.read(dioProvider);
    final s = S.of(context);
    try {
      await dio.post(
        '/households/${widget.householdId}/join-requests/$reqId/${approve ? 'approve' : 'reject'}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(approve ? s.requestApproved : s.requestRejected)),
      );
      setState(() => _future = _fetch());
    } on DioException catch (e) {
      final msg = e.response?.data is Map &&
              (e.response!.data as Map)['message'] != null
          ? (e.response!.data as Map)['message'].toString()
          : (e.message ?? s.networkError);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dioProvider);
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.joinRequestsTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _future = _fetch());
          await _future;
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                  child: Text(s.errorWithMessage(snap.error.toString())));
            }
            final list = snap.data ?? const [];
            if (list.isEmpty) {
              return Center(child: Text(s.noJoinRequests));
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = list[i];
                final email =
                    (r['user']?['email'] ?? r['userId'] ?? '').toString();
                final createdAt =
                    _fmtDateLocalized(context, r['createdAt']?.toString());

                return ListTile(
                  leading:
                      const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text(email),
                  subtitle: Text(createdAt),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: s.reject,
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            _decide(reqId: r['id'].toString(), approve: false),
                      ),
                      IconButton(
                        tooltip: s.approve,
                        icon: const Icon(Icons.check),
                        onPressed: () =>
                            _decide(reqId: r['id'].toString(), approve: true),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
