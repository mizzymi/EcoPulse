import 'dart:async';

import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../api/dio.dart';
import '../join_requests_screen.dart';

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
  bool _loadingInFlight = false;

  List<dynamic> _members = [];

  String? _myRole; // OWNER | ADMIN | MEMBER
  bool get _canManage => _myRole == 'OWNER' || _myRole == 'ADMIN';

  final CancelToken _cancelToken = CancelToken();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    if (!_cancelToken.isCancelled) _cancelToken.cancel('disposed');
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final topPad = MediaQuery.of(context).padding.top;
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
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

  /// ✅ Supports BOTH API shapes:
  /// 1) Old: [ {userId, role, joinedAt, user{...}, isMe?}, ... ]
  /// 2) New: { myRole: "OWNER", members: [ ... ] }
  (List<dynamic> members, String? myRole) _parseMembersResponse(dynamic data) {
    // New format: Map with members + myRole
    if (data is Map) {
      final myRole = (data['myRole'] ?? '').toString().toUpperCase();
      final rawMembers = data['members'];
      if (rawMembers is List) {
        return (rawMembers.toList(), myRole.isEmpty ? null : myRole);
      }
    }

    // Old format: List directly
    if (data is List) {
      final list = data.toList();

      // Try detect myRole via isMe
      String? myRole;
      for (final it in list) {
        if (it is Map && it['isMe'] == true) {
          myRole = (it['role'] ?? '').toString().toUpperCase();
          break;
        }
      }
      return (list, myRole);
    }

    return (<dynamic>[], null);
  }

  Future<void> _load() async {
    if (_loadingInFlight) return;
    _loadingInFlight = true;

    if (mounted) setState(() => _loading = true);

    final dio = ref.read(dioProvider);
    final s = S.of(context);

    try {
      final res = await dio.get(
        '/households/${widget.householdId}/members',
        cancelToken: _cancelToken,
        options: Options(
          // ✅ avoid “loading forever”
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final parsed = _parseMembersResponse(res.data);
      final list = parsed.$1;
      final myRole = parsed.$2;

      if (!mounted) return;
      setState(() {
        _members = list;
        _myRole = myRole; // may be null if backend doesn't send it
      });
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;

      final apiMsg = _extractApiMessage(e.response?.data);
      final msg =
          apiMsg.isNotEmpty ? apiMsg : (e.message ?? s.errorLoadingMembers);
      if (mounted) _toast(msg);
    } on TimeoutException {
      // If anything is still running, cancel it
      if (!_cancelToken.isCancelled) _cancelToken.cancel('timeout');
      if (mounted) _toast(s.errorLoadingMembers);
    } catch (_) {
      if (mounted) _toast(s.errorLoadingMembers);
    } finally {
      _loadingInFlight = false;
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

  bool _canKickTarget(String targetRole) {
    final r = targetRole.toUpperCase();
    if (r == 'OWNER') return false;
    if (_myRole == 'OWNER') return true;
    if (_myRole == 'ADMIN') return r == 'MEMBER';
    return false;
  }

  bool _canEditTarget(String targetRole) {
    final r = targetRole.toUpperCase();
    if (_myRole == 'OWNER') return r != 'OWNER';
    if (_myRole == 'ADMIN') return r == 'MEMBER';
    return false;
  }

  Future<void> _changeRole(String userId, String newRole) async {
    final dio = ref.read(dioProvider);
    final s = S.of(context);

    try {
      await dio.patch(
        '/households/${widget.householdId}/members/$userId',
        data: {'role': newRole},
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      _toast(s.savedToast);
      await _load();
    } on DioException catch (e) {
      final apiMsg = _extractApiMessage(e.response?.data);
      _toast(apiMsg.isNotEmpty ? apiMsg : (e.message ?? s.authErrorGeneric));
    }
  }

  Future<void> _removeMember(String userId) async {
    final dio = ref.read(dioProvider);
    final s = S.of(context);

    try {
      await dio.delete(
        '/households/${widget.householdId}/members/$userId',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      _toast(s.removedToast);
      await _load();
    } on DioException catch (e) {
      final apiMsg = _extractApiMessage(e.response?.data);
      _toast(apiMsg.isNotEmpty ? apiMsg : (e.message ?? s.authErrorGeneric));
    }
  }

  Future<void> _openManageSheet(Map<String, dynamic> m) async {
    final s = S.of(context);

    final userId = (m['userId'] ?? '').toString();
    final role = (m['role'] ?? '').toString().toUpperCase();
    final user = (m['user'] ?? {}) as Map<String, dynamic>;
    final email = (user['email'] ?? '').toString();

    if (userId.isEmpty) return;

    if (!_canManage) {
      _toast(s.notAllowed);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final canKick = _canKickTarget(role);
        final canEdit = _canEditTarget(role);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email.isEmpty ? s.userGeneric : email,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text('${s.roleLabel}: ${_roleLabel(context, role)}'),
                const SizedBox(height: 16),
                if (canEdit && _myRole == 'OWNER') ...[
                  Text(
                    s.changeRoleTitle,
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: Text(s.roleAdmin),
                    onTap: role == 'ADMIN'
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await _changeRole(userId, 'ADMIN');
                          },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(s.roleMember),
                    onTap: role == 'MEMBER'
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await _changeRole(userId, 'MEMBER');
                          },
                  ),
                  const Divider(height: 24),
                ],
                ListTile(
                  leading: Icon(Icons.remove_circle_outline,
                      color: canKick ? Colors.red : Colors.grey),
                  title: Text(
                    s.kickMemberCta,
                    style: TextStyle(color: canKick ? Colors.red : Colors.grey),
                  ),
                  onTap: !canKick
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: ctx,
                            builder: (_) => AlertDialog(
                              title: Text(s.confirmKickTitle),
                              content: Text(
                                s.confirmKickBody(
                                  email.isEmpty ? s.userGeneric : email,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(s.cancel),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(s.kickAction),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            Navigator.pop(ctx);
                            await _removeMember(userId);
                          }
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final title = widget.householdName != null
        ? s.membersTitle(widget.householdName!)
        : s.membersTitleSimple;

    final canShowManage = _myRole != null && _canManage;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: s.refreshTooltip,
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: s.pendingRequestsTooltip,
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      JoinRequestsScreen(householdId: widget.householdId),
                ),
              );
            },
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

                        final avatarText =
                            email.isNotEmpty ? email[0].toUpperCase() : '?';

                        final roleUpper = role.toUpperCase();

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text(avatarText)),
                            title: Text(email.isEmpty ? s.userGeneric : email),
                            subtitle: dt == null
                                ? null
                                : Text(s.sinceLabel(_fmtDate(context, dt))),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                    label:
                                        Text(_roleLabel(context, roleUpper))),
                                if (canShowManage && roleUpper != 'OWNER') ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: s.manageMemberTooltip,
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () => _openManageSheet(m),
                                  ),
                                ],
                              ],
                            ),
                            onTap: canShowManage
                                ? () => _openManageSheet(m)
                                : null,
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
