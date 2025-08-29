import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../api/dio.dart';
import 'household_detail_screen.dart';

class MyHouseholdsScreen extends ConsumerStatefulWidget {
  const MyHouseholdsScreen({super.key});

  @override
  ConsumerState<MyHouseholdsScreen> createState() => _MyHouseholdsScreenState();
}

class _MyHouseholdsScreenState extends ConsumerState<MyHouseholdsScreen> {
  bool _loading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);
    try {
      final res = await dio.get('/households');
      setState(() => _items = (res.data as List).toList());
    } on DioException catch (e) {
      final msg = e.response?.data is Map &&
              (e.response!.data as Map)['message'] != null
          ? (e.response!.data as Map)['message'].toString()
          : (e.message ?? 'Error al cargar');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _roleColor(String role, BuildContext ctx) {
    switch (role) {
      case 'OWNER':
        return Colors.teal;
      case 'ADMIN':
        return Theme.of(ctx).colorScheme.primary;
      default:
        return Theme.of(ctx).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis casas'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Aún no perteneces a ninguna casa.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final h = _items[i] as Map<String, dynamic>;
                    final role = (h['role'] ?? '').toString();
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.home)),
                        title: Text(h['name']?.toString() ?? 'Casa'),
                        subtitle: Text('Moneda: ${h['currency'] ?? 'EUR'}'),
                        trailing: Chip(
                          label: Text(role),
                          backgroundColor:
                              _roleColor(role, context).withOpacity(0.12),
                          side: BorderSide(color: _roleColor(role, context)),
                          labelStyle:
                              TextStyle(color: _roleColor(role, context)),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HouseholdDetailScreen(
                                householdId: h['id'].toString(),
                                householdName: h['name']?.toString(),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
