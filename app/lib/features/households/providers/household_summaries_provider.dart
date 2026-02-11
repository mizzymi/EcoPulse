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

  final res = await dio.get('/households');
  final list = (res.data as List).cast<Map>();

  final ym = _ymNow();

  final futures = list.map((raw) async {
    final id = (raw['id'] ?? raw['_id']).toString();
    final name = (raw['name'] ?? 'Unnamed').toString();
    final currency = (raw['currency'] ?? 'EUR').toString();

    final mc = raw['memberCount'];
    final members =
        mc is num ? mc.toInt() : int.tryParse(mc?.toString() ?? '') ?? 0;

    double closing = 0;
    try {
      final sumRes = await dio.get(
        '/households/$id/summary',
        queryParameters: {'month': ym},
      );
      final sum = (sumRes.data as Map).cast<String, dynamic>();
      final v = sum['closingBalance'];
      closing =
          v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;
    } catch (_) {
    }

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
