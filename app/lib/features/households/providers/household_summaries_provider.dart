import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopulse/api/dio.dart';

class HouseholdPreview {
  final String id;
  final String name;
  final String currency;
  final int memberCount;
  final double closingBalance;

  HouseholdPreview({
    required this.id,
    required this.name,
    required this.currency,
    required this.memberCount,
    required this.closingBalance,
  });
}

String _ymNow() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
}

final householdPreviewsProvider =
    FutureProvider<List<HouseholdPreview>>((ref) async {
  final dio = ref.read(dioProvider);

  // 1) Lista básica de casas
  final res = await dio.get('/households');
  final list = (res.data as List).cast<Map>();

  final ym = _ymNow();

  // 2) Para cada casa: summary (closingBalance) + miembros reales
  final futures = list.map((raw) async {
    final id = (raw['id'] ?? raw['_id']).toString();
    final name = (raw['name'] ?? 'Unnamed').toString();
    final currency = (raw['currency'] ?? 'EUR').toString();

    // --- miembros reales ---
    int members = 1;
    try {
      final mRes = await dio.get('/households/$id/members');
      final ms = (mRes.data as List);
      members = ms.length;
    } catch (_) {
      // si falla, mantenemos fallback
    }

    // --- saldo real del mes actual ---
    double closing = 0;
    try {
      final sumRes = await dio
          .get('/households/$id/summary', queryParameters: {'month': ym});
      final sum = (sumRes.data as Map).cast<String, dynamic>();
      final v = sum['closingBalance'];
      closing =
          v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;
    } catch (_) {}

    return HouseholdPreview(
      id: id,
      name: name,
      currency: currency,
      memberCount: members,
      closingBalance: closing,
    );
  }).toList();

  return Future.wait(futures);
});
