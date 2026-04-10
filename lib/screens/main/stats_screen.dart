import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/habit_provider.dart';
import '../../providers/stats_provider.dart';
import '../../models/habit_category.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitProvider = context.watch<HabitProvider>();
    final allHabits = habitProvider.habits;

    if (allHabits.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Статистика')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Добавьте привычки, чтобы увидеть статистику',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final weekData = context.watch<StatsProvider>().getWeekChartData(allHabits);
    final monthData = context.watch<StatsProvider>().getMonthChartData(allHabits);
    final weekPercent = context.watch<StatsProvider>().getWeeklyCompletionPercent(allHabits);
    final monthPercent = context.watch<StatsProvider>().getMonthlyCompletionPercent(allHabits);
    final totalCompletions = habitProvider.getTotalCompletions();
    final longestStreak = habitProvider.getLongestStreak();
    final categoryStats = context.watch<StatsProvider>().getCategoryStats(allHabits);

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Карточки метрик
          Row(
            children: [
              _metricCard(context, '📊', 'Неделя', '${weekPercent.toStringAsFixed(0)}%', Colors.blue),
              const SizedBox(width: 12),
              _metricCard(context, '📅', 'Месяц', '${monthPercent.toStringAsFixed(0)}%', Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricCard(context, '✅', 'Всего', '$totalCompletions', Colors.green),
              const SizedBox(width: 12),
              _metricCard(context, '🔥', 'Серия', '$longestStreak дн.', Colors.red),
            ],
          ),

          const SizedBox(height: 24),

          // График за неделю
          _sectionHeader(context, 'Выполнение за неделю'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < weekData.length) {
                              final date = weekData[index]['date'] as DateTime;
                              return Text(
                                DateFormat('E', 'ru').format(date),
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: weekData.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), e.value['percent'] as double);
                        }).toList(),
                        isCurved: false,
                        color: Colors.green,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: 100,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // График за месяц
          _sectionHeader(context, 'Выполнение за месяц'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index % 7 == 0 && index < monthData.length) {
                              final date = monthData[index]['date'] as DateTime;
                              return Text(
                                '${date.day}',
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: monthData.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), e.value['percent'] as double);
                        }).toList(),
                        isCurved: false,
                        color: Colors.blue,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: 100,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Категории
          _sectionHeader(context, 'По категориям'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: categoryStats.entries.map((entry) {
                  final category = HabitCategory.values.firstWhere(
                    (c) => c.name == entry.key,
                  );
                  final maxVal = categoryStats.values.isEmpty
                      ? 1
                      : categoryStats.values.reduce((a, b) => a > b ? a : b);
                  final percent = maxVal > 0 ? (entry.value / maxVal) * 100 : 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(category.icon),
                            const SizedBox(width: 8),
                            Text(
                              category.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${entry.value}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _metricCard(BuildContext context, String icon, String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
