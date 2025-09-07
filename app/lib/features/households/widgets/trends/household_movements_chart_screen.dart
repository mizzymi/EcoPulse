import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../api/dio.dart';

enum Bucket { day, week, month }

class HouseholdMovementsChartScreen extends ConsumerStatefulWidget {
  final String householdId;
  final String? householdName;
  const HouseholdMovementsChartScreen({
    super.key,
    required this.householdId,
    this.householdName,
  });

  @override
  ConsumerState<HouseholdMovementsChartScreen> createState() =>
      _HouseholdMovementsChartScreenState();
}

class _HouseholdMovementsChartScreenState
    extends ConsumerState<HouseholdMovementsChartScreen> {
  bool _loading = true;
  String? _error;

  // Entradas crudas
  late List<_Entry> _entries = [];

  // Datos agregados por bucket
  late List<_BucketAgg> _agg = [];

  Bucket _bucket = Bucket.month;

  @override
  void initState() {
    super.initState();
    _loadAllEntries();
  }

  String _fmtNumber(BuildContext context, double v) {
    final locale = Localizations.localeOf(context).toString();
    final f = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    return f.format(v);
  }

  Future<void> _loadAllEntries() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final dio = ref.read(dioProvider);
    try {
      final res = await dio.get(
        '/households/${widget.householdId}/entries',
        queryParameters: {
          'from': DateTime(2000, 1, 1).toIso8601String(),
          'to': DateTime.now().toIso8601String(),
          'limit': 10000,
        },
      );
      final list = (res.data as List).map((e) {
        final dt = DateTime.tryParse(e['occursAt']?.toString() ?? '');
        final amt = _asDouble(e['amount']);
        final type = (e['type'] ?? '').toString().toUpperCase();
        return _Entry(
          when: (dt ?? DateTime.now()).toLocal(),
          amount: amt,
          isIncome: type == 'INCOME',
        );
      }).toList();

      list.sort((a, b) => a.when.compareTo(b.when));
      _entries = list;

      _rebuildAgg();
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data is Map &&
                (e.response!.data as Map)['message'] != null
            ? (e.response!.data as Map)['message'].toString()
            : (e.message ?? S.of(context).loadMovementsFailed);
      });
    } catch (_) {
      setState(() => _error = S.of(context).unexpectedError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static double _asDouble(dynamic x) {
    if (x is num) return x.toDouble();
    return double.tryParse(x?.toString() ?? '0') ?? 0;
  }

  void _rebuildAgg() {
    final map = <String, _BucketAgg>{};

    String keyOf(DateTime d) {
      switch (_bucket) {
        case Bucket.day:
          return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        case Bucket.week:
          final week = _isoWeek(d);
          return '${d.year}-W${week.toString().padLeft(2, '0')}';
        case Bucket.month:
          return '${d.year}-${d.month.toString().padLeft(2, '0')}';
      }
    }

    DateTime startOfKey(String key) {
      if (_bucket == Bucket.day) {
        final p = key.split('-');
        return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      } else if (_bucket == Bucket.month) {
        final p = key.split('-');
        return DateTime(int.parse(p[0]), int.parse(p[1]), 1);
      } else {
        final p = key.split('-W');
        final year = int.parse(p[0]);
        final week = int.parse(p[1]);
        return _firstDateOfIsoWeek(week, year);
      }
    }

    for (final e in _entries) {
      final k = keyOf(e.when);
      final agg =
          map.putIfAbsent(k, () => _BucketAgg(key: k, when: startOfKey(k)));
      if (e.isIncome) {
        agg.income += e.amount;
      } else {
        agg.expense += e.amount;
      }
    }

    final out = map.values.toList()..sort((a, b) => a.when.compareTo(b.when));

    double running = 0;
    for (final a in out) {
      a.net = a.income - a.expense;
      running += a.net;
      a.cumulative = running;
    }

    setState(() => _agg = out);
  }

  int _isoWeek(DateTime date) {
    final thursday = date.add(Duration(days: (3 - ((date.weekday + 6) % 7))));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final diff = thursday.difference(firstThursday);
    return 1 + (diff.inDays / 7).floor();
  }

  DateTime _firstDateOfIsoWeek(int week, int year) {
    final jan4 = DateTime(year, 1, 4);
    final jan4Weekday = (jan4.weekday + 6) % 7; // 0=lun
    final mondayWeek1 = jan4.subtract(Duration(days: jan4Weekday));
    return mondayWeek1.add(Duration(days: (week - 1) * 7));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final title = s.cumulativeTitle(widget.householdName ?? s.householdGeneric);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<Bucket>(
            tooltip: s.groupByTooltip,
            icon: const Icon(Icons.calendar_view_month),
            onSelected: (b) {
              setState(() => _bucket = b);
              _rebuildAgg();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: Bucket.day, child: Text(s.groupByDay)),
              PopupMenuItem(value: Bucket.week, child: Text(s.groupByWeek)),
              PopupMenuItem(value: Bucket.month, child: Text(s.groupByMonth)),
            ],
          ),
          IconButton(
            tooltip: s.refreshTooltip,
            onPressed: _loadAllEntries,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : _entries.isEmpty
                  ? Center(child: Text(s.noMovementsToChart))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _LegendDot(label: s.legendCumulativeBalance),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(child: _buildCumulativeLine(context)),
                          const SizedBox(height: 8),
                          Text(
                            s.periodsEntriesLabel(_agg.length, _entries.length),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildCumulativeLine(BuildContext context) {
    final s = S.of(context);
    final spots = <FlSpot>[];
    for (var i = 0; i < _agg.length; i++) {
      spots.add(FlSpot(i.toDouble(), _agg[i].cumulative));
    }

    final allY = spots.map((s) => s.y).toList();
    final minY = allY.isEmpty ? 0 : allY.reduce((a, b) => a < b ? a : b);
    final maxY = allY.isEmpty ? 0 : allY.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() * 0.1;
    final lo = (minY - pad);
    final hi = (maxY + pad);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: _agg.isEmpty ? 0 : (_agg.length - 1).toDouble(),
        minY: lo == hi ? lo - 1 : lo,
        maxY: lo == hi ? hi + 1 : hi,
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            spots: spots,
          ),
        ],
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.4),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (ts) {
              return ts
                  .map((t) {
                    final i = t.x.toInt();
                    if (i < 0 || i >= _agg.length) return null;
                    final a = _agg[i];
                    final label = _labelFor(context, a.when);
                    final amount = _fmtNumber(context, a.cumulative);
                    return LineTooltipItem(
                      '$label\n${s.balanceLabel(amount)}',
                      Theme.of(context).textTheme.bodyMedium!,
                    );
                  })
                  .whereType<LineTooltipItem>()
                  .toList();
            },
          ),
        ),
      ),
    );
  }

  String _labelFor(BuildContext context, DateTime d) {
    final locale = Localizations.localeOf(context).toString();
    switch (_bucket) {
      case Bucket.day:
        return DateFormat.Md(locale).format(d);
      case Bucket.week:
        final w = _isoWeek(d);
        // “W34/25”
        return 'W${w.toString().padLeft(2, '0')}/${(d.year % 100).toString().padLeft(2, '0')}';
      case Bucket.month:
        return DateFormat.yMMM(locale).format(d);
    }
  }
}

/* ======== Tipos internos ======== */

class _Entry {
  final DateTime when;
  final double amount;
  final bool isIncome;
  _Entry({required this.when, required this.amount, required this.isIncome});
}

class _BucketAgg {
  final String key;
  final DateTime when;
  double income = 0;
  double expense = 0;
  double net = 0;
  double cumulative = 0;

  _BucketAgg({required this.key, required this.when});
}

class _LegendDot extends StatelessWidget {
  final String label;
  const _LegendDot({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
