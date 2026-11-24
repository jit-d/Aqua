import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/statistics_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/statistic_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final firstDay = context.read<SettingsProvider>().firstDayOfWeek;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<StatisticsProvider>().load(firstDayOfWeek: firstDay);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StatisticsProvider>();
    if (sp.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final maxY = _maxY(sp.week);

    return RefreshIndicator(
      onRefresh: sp.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Week navigation
          Row(
            children: [
              IconButton(
                onPressed: sp.previousWeek,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${AppDateUtils.formatDate(sp.weekStart)} – '
                    '${AppDateUtils.formatDate(sp.weekStart.add(const Duration(days: 6)))}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                onPressed: sp.isCurrentWeek ? null : sp.nextWeek,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
              child: SizedBox(
                height: 220,
                child: sp.weekTotal == 0
                    ? const Center(child: Text('No data this week yet'))
                    : BarChart(_buildChart(context, sp.week, maxY)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Summary cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: [
              StatisticCard(
                label: 'Weekly total',
                value: '${sp.weekTotal} ml',
                icon: Icons.water_drop,
              ),
              StatisticCard(
                label: 'Daily average',
                value: '${sp.dailyAverage.round()} ml',
                icon: Icons.show_chart,
                color: const Color(0xFF2EAD75),
              ),
              StatisticCard(
                label: 'Goals completed',
                value: '${sp.completedDays} / 7',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF2EAD75),
              ),
              StatisticCard(
                label: 'Completion',
                value: '${(sp.completionRate * 100).round()}%',
                icon: Icons.percent,
                color: const Color(0xFF1565C0),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Best / lowest
          if (sp.bestDay != null && sp.weekTotal > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Highlights',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _row(context, 'Best day',
                        '${DateFormat('EEE, MMM d').format(sp.bestDay!.date)} • ${sp.bestDay!.totalMl} ml'),
                    const SizedBox(height: 6),
                    _row(context, 'Lowest day',
                        '${DateFormat('EEE, MMM d').format(sp.lowestDay!.date)} • ${sp.lowestDay!.totalMl} ml'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) {
    return Row(
      children: [
        Expanded(
            child: Text(k,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant))),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  double _maxY(List<DayStat> week) {
    final peak = week.fold<int>(0, (m, d) => d.totalMl > m ? d.totalMl : m);
    final goalPeak = week.fold<int>(0, (m, d) => d.goalMl > m ? d.goalMl : m);
    final v = (peak > goalPeak ? peak : goalPeak).toDouble();
    return v <= 0 ? 500 : (v * 1.2).ceilToDouble();
  }

  BarChartData _buildChart(
      BuildContext context, List<DayStat> week, double maxY) {
    final scheme = Theme.of(context).colorScheme;
    final avgGoal = week.fold<int>(0, (s, d) => s + d.goalMl) ~/ week.length;

    return BarChartData(
      maxY: maxY,
      minY: 0,
      alignment: BarChartAlignment.spaceAround,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (v) =>
            FlLine(color: scheme.outlineVariant, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: maxY / 4,
            getTitlesWidget: (v, meta) => Text(
              v.toInt().toString(),
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (v, meta) {
              final i = v.toInt();
              if (i < 0 || i >= week.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  DateFormat('E').format(week[i].date),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
            '${rod.toY.toInt()} ml',
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(
          y: avgGoal.toDouble(),
          color: const Color(0xFF2EAD75),
          strokeWidth: 1.5,
          dashArray: [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF2EAD75)),
            labelResolver: (_) => 'Goal',
          ),
        ),
      ]),
      barGroups: List.generate(week.length, (i) {
        final d = week[i];
        final isToday = AppDateUtils.toLocalDateKey(d.date) ==
            AppDateUtils.toLocalDateKey(DateTime.now());
        final color = d.goalMet
            ? const Color(0xFF2EAD75)
            : (isToday ? scheme.primary : scheme.primary.withValues(alpha: 0.65));
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: d.totalMl.toDouble(),
              color: color,
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        );
      }),
    );
  }
}