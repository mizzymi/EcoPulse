import 'package:ecopulse/l10n/l10n.dart';
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
          : S.of(context).errorLoading;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _roleLabel(BuildContext ctx, String role) {
    switch (role) {
      case 'OWNER':
        return S.of(ctx).roleOwner;
      case 'ADMIN':
        return S.of(ctx).roleAdmin;
      default:
        return S.of(ctx).roleMember;
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
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myHouseholdsTitle),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(s.noHouseholdsMessage))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final h = _items[i] as Map<String, dynamic>;
                    final roleRaw = (h['role'] ?? '').toString();
                    final role = _roleLabel(context, roleRaw);
                    final name = h['name']?.toString() ?? s.unnamedAccount;

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.home)),
                        title: Text(name),
                        subtitle: Text(
                          s.currencyLabel((h['currency'] ?? 'EUR').toString()),
                        ),
                        trailing: Chip(
                          label: Text(role),
                          backgroundColor:
                              _roleColor(roleRaw, context).withOpacity(0.12),
                          side: BorderSide(color: _roleColor(roleRaw, context)),
                          labelStyle:
                              TextStyle(color: _roleColor(roleRaw, context)),
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
