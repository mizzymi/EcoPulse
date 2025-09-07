import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      final s = S.of(context);
      final msg = e.response?.data is Map &&
              (e.response!.data as Map)['message'] != null
          ? (e.response!.data as Map)['message'].toString()
          : (e.message ?? s.errorLoadingMembers);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtDate(BuildContext context, DateTime d) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).format(d.toLocal());
  }

  String _roleLabel(BuildContext context, String r) {
    final s = S.of(context);
    switch (r.toUpperCase()) {
      case 'OWNER':
        return s.roleOwner;
      case 'ADMIN':
        return s.roleAdmin;
      default:
        return s.roleMember;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final title = widget.householdName != null
        ? s.membersTitle(widget.householdName!)
        : s.membersTitleSimple;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: s.refreshTooltip,
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _members.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 48),
                        Center(child: Text(s.noMembers)),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (_, i) {
                        final m = _members[i] as Map<String, dynamic>;
                        final user = (m['user'] ?? {}) as Map<String, dynamic>;
                        final email = (user['email'] ?? '').toString();
                        final role = (m['role'] ?? '').toString();
                        final joinedAtStr = (m['joinedAt'] ?? '').toString();
                        final dt = DateTime.tryParse(joinedAtStr);

                        String avatarText = '';
                        if (email.isNotEmpty) {
                          avatarText = email.substring(0, 1).toUpperCase();
                        }

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text(avatarText)),
                            title: Text(email.isEmpty ? s.userGeneric : email),
                            subtitle: dt == null
                                ? null
                                : Text(s.sinceLabel(_fmtDate(context, dt))),
                            trailing:
                                Chip(label: Text(_roleLabel(context, role))),
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
