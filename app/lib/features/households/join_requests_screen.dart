import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _decide({
    required String reqId,
    required bool approve,
  }) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.post(
        '/households/${widget.householdId}/join-requests/$reqId/${approve ? 'approve' : 'reject'}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(approve ? 'Solicitud aprobada' : 'Solicitud rechazada')),
      );
      setState(() => _future = _fetch());
    } on DioException catch (e) {
      final msg = e.response?.data is Map &&
              (e.response!.data as Map)['message'] != null
          ? (e.response!.data as Map)['message'].toString()
          : (e.message ?? 'Error de red');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dioProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes pendientes')),
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
              return Center(child: Text('Error: ${snap.error}'));
            }
            final list = snap.data ?? const [];
            if (list.isEmpty) {
              return const Center(child: Text('No hay solicitudes'));
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = list[i];
                final email =
                    (r['user']?['email'] ?? r['userId'] ?? '').toString();
                final createdAt = _fmtDate(r['createdAt']?.toString());

                return ListTile(
                  leading:
                      const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text(email),
                  subtitle: Text(createdAt),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Rechazar',
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            _decide(reqId: r['id'].toString(), approve: false),
                      ),
                      IconButton(
                        tooltip: 'Aprobar',
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
