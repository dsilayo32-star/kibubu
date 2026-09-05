import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/export_helper.dart';
import '../utils/helpers.dart';
import '../utils/stats.dart';
import '../widgets/common_widgets.dart';
import 'goal_pages.dart';

/// Ukurasa wa muhtasari: jumla, wiki hii, mwezi huu na grafu za maendeleo.
class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final week = summarize(savingsHistory, weekStart(now), now);
    final month = summarize(savingsHistory, monthStart(now), now);
    final allTime = summarize(
      savingsHistory,
      DateTime.fromMillisecondsSinceEpoch(0),
      now,
    );
    final weekly = last7DaysTotals(savingsHistory, now);
    final monthly = last6MonthsTotals(savingsHistory, now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MUHTASARI 📊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Kusafirisha / Shiriki Ripoti',
            onPressed: () {
              final entries = ExportHelper.collectAllEntries(
                goalsList: goals,
                currentGoalName: goalName,
                currentHistory: savingsHistory,
              );
              final csv = ExportHelper.generateCsv(entries);
              final text = ExportHelper.generateTextSummary(
                userName: fullName,
                goalsList: goals,
                entries: entries,
                now: now,
              );
              ExportHelper.showExportDialog(
                context,
                title: 'Kusafirisha Ripoti 📊',
                csvData: csv,
                textSummary: text,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle('MALENGO YAKO (${goals.length})'),
            const SizedBox(height: 10),
            _goalsOverview(context),
            const SizedBox(height: 24),
            GradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'JUMLA KUU',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    money(allTime.net),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deposits: ${money(allTime.deposits)} • '
                    'Withdrawals: ${money(allTime.withdrawals)} • '
                    'Siku ${allTime.daysSaved} za kuweka',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Wiki hii',
                    amount: week.net,
                    icon: Icons.calendar_view_week,
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'Mwezi huu',
                    amount: month.net,
                    icon: Icons.calendar_month,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Wastani/siku (mwezi)',
                    amount: month.averagePerActiveDay,
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'Siku tulizoweka (mwezi)',
                    amount: month.daysSaved.toDouble(),
                    icon: Icons.event_available,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle('WIKI HII (siku 7)'),
            const SizedBox(height: 12),
            _BarChartCard(
              bars: weekly
                  .map(
                    (d) =>
                        (label: '${d.day.day}/${d.day.month}', value: d.total),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            const SectionTitle('MIEZI 6 ILIYOPITA'),
            const SizedBox(height: 12),
            _BarChartCard(
              bars: monthly
                  .map(
                    (m) => (label: _monthName(m.month.month), value: m.total),
                  )
                  .toList(),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Orodha ya kadi za malengo yote (jina, maendeleo, kilichobaki).
  Widget _goalsOverview(BuildContext context) {
    if (goals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Hakuna malengo yaliyosajiriwa bado.'),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < goals.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _goalOverviewCard(context, goals[i], i),
          ),
      ],
    );
  }

  Widget _goalOverviewCard(BuildContext context, Goal goal, int index) {
    final target = goal.target;
    final saved = goal.saved;
    final progress = goal.progress;
    final remaining = goal.remaining;
    final done = goal.completed;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          activeGoalIndex = index;
          loadGoalRecord(goal);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoalDetailScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.lightGreen,
                    child: Icon(Icons.flag, color: AppColors.green, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      goal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (done)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.green,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: AppColors.lightGreen,
                  valueColor: const AlwaysStoppedAnimation(AppColors.green),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${money(saved)} / ${money(target)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  Text(
                    done ? 'Imekamilika ✅' : 'Kilichobaki: ${money(remaining)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mac',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String _monthName(int month) => _months[month - 1];
}

/// Card yenye grafu ya nguzo (bar chart).
class _BarChartCard extends StatelessWidget {
  const _BarChartCard({required this.bars});

  final List<({String label, double value})> bars;

  double get _maxValue =>
      bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    final max = _maxValue <= 0 ? 1.0 : _maxValue * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: max,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= bars.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          bars[index].label,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < bars.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: bars[i].value,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                        color: bars[i].value > 0
                            ? AppColors.green
                            : AppColors.lightGreen,
                      ),
                    ],
                  ),
              ],
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                        money(rod.toY),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
