import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../api/dio.dart';

class HouseholdMembersScreen extends ConsumerStatefulWidget {
  final String householdId;
  final String? householdName;
  const HouseholdMembersScreen({
    super.key,
    required this.householdId,
    this.householdName,
  });

  @override
  ConsumerState<HouseholdMembersScreen> createState() =>
      _HouseholdMembersScreenState();
}

class _HouseholdMembersScreenState
    extends ConsumerState<HouseholdMembersScreen> {
  bool _loading = true;
  List<dynamic> _members = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);
    try {
      final res = await dio.get(
        '/households/${widget.householdId}/members',
      );
      setState(() => _members = (res.data as List).toList());
    } on DioException catch (e) {
      final msg = e.response?.data is Map &&
              (e.response!.data as Map)['message'] != null
          ? (e.response!.data as Map)['message'].toString()
          : (e.message ?? 'No se pudieron cargar los miembros');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _roleLabel(String r) {
    switch ((r).toUpperCase()) {
      case 'OWNER':
        return 'Propietario';
      case 'ADMIN':
        return 'Admin';
      default:
        return 'Miembro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Miembros${widget.householdName != null ? ' — ${widget.householdName}' : ''}';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemBuilder: (_, i) {
                  final m = _members[i] as Map<String, dynamic>;
                  final user = (m['user'] ?? {}) as Map<String, dynamic>;
                  final email = (user['email'] ?? '').toString();
                  final role = (m['role'] ?? '').toString();
                  final joinedAtStr = (m['joinedAt'] ?? '').toString();
                  final dt = DateTime.tryParse(joinedAtStr);
                  final joined = dt != null
                      ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'
                      : null;

                  String avatarText = '';
                  if (email.isNotEmpty) {
                    avatarText = email.substring(0, 1).toUpperCase();
                  }

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(avatarText)),
                      title: Text(email.isEmpty ? 'Usuario' : email),
                      subtitle: joined == null
                          ? null
                          : Text('Desde: $joined'),
                      trailing: Chip(
                        label: Text(_roleLabel(role)),
                      ),
                      // En el futuro: onTap -> ver perfil, cambiar rol, etc.
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: _members.length,
              ),
            ),
    );
  }
}
