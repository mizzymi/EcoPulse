// ignore_for_file: invalid_use_of_protected_member

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../api/dio.dart';

class JoinRequestsScreen extends ConsumerWidget {
  const JoinRequestsScreen({super.key, required this.householdId});
  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dio = ref.watch(dioProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes pendientes')),
      body: FutureBuilder<Response>(
        future: dio.get('/households/$householdId/join-requests',
            queryParameters: {'status': 'PENDING'}),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final list = (snap.data!.data as List).cast<Map<String, dynamic>>();
          if (list.isEmpty)
            return const Center(child: Text('No hay solicitudes'));
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = list[i];
              return ListTile(
                title: Text(r['user']?['email'] ?? r['userId']),
                subtitle:
                    Text(DateTime.parse(r['createdAt']).toLocal().toString()),
                trailing: Wrap(spacing: 6, children: [
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        await dio.post(
                            '/households/$householdId/join-requests/${r['id']}/reject');
                        (context as Element).reassemble();
                      }),
                  IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () async {
                        await dio.post(
                            '/households/$householdId/join-requests/${r['id']}/approve');
                        (context as Element).reassemble();
                      }),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
