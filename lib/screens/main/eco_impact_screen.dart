import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../services/impact_calc_service.dart';
import '../../models/eco_impact.dart';
import '../../models/habit_category.dart';

class EcoImpactScreen extends StatelessWidget {
  const EcoImpactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habits = context.watch<HabitProvider>().habits;
    final impactCalc = ImpactCalcService();

    final todayImpact = impactCalc.calculateTodayImpact(habits);
    final weekImpact = impactCalc.calculateWeekImpact(habits);
    final monthImpact = impactCalc.calculateMonthImpact(habits);
    final allImpact = impactCalc.calculateAllTimeImpact(habits);

    return Scaffold(
      appBar: AppBar(title: const Text('Экологический эффект')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Общий эффект
          _impactCard(
            context,
            '🌍 За всё время',
            allImpact,
            impactCalc,
            const Color(0xFF2E7D32),
          ),
          const SizedBox(height: 16),
          _impactCard(
            context,
            '📅 За месяц',
            monthImpact,
            impactCalc,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _impactCard(
            context,
            '📊 За неделю',
            weekImpact,
            impactCalc,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _impactCard(
            context,
            '☀️ Сегодня',
            todayImpact,
            impactCalc,
            Colors.purple,
          ),

          const SizedBox(height: 32),

          // Визуальные эквиваленты
          _sectionHeader(context, 'Визуальные эквиваленты'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _equivRow(
                    '🌳',
                    'Деревьев (поглощение CO₂)',
                    impactCalc.co2ToTrees(allImpact.co2SavedKg).toStringAsFixed(1),
                  ),
                  const Divider(height: 24),
                  _equivRow(
                    '🚗',
                    'Км на авто (эквивалент CO₂)',
                    impactCalc.co2ToCarKm(allImpact.co2SavedKg).toStringAsFixed(0),
                  ),
                  const Divider(height: 24),
                  _equivRow(
                    '💡',
                    'Часов работы LED-лампы',
                    impactCalc.energyToLedHours(allImpact.energySavedKwh).toStringAsFixed(0),
                  ),
                  const Divider(height: 24),
                  _equivRow(
                    '🛁',
                    'Ванн (эквивалент воды)',
                    impactCalc.waterToBaths(allImpact.waterSavedLiters).toStringAsFixed(1),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // По категориям
          _sectionHeader(context, 'По категориям'),
          ..._buildCategoryImpact(context, habits, impactCalc),
        ],
      ),
    );
  }

  Widget _impactCard(
    BuildContext context,
    String title,
    EcoImpact impact,
    ImpactCalcService calc,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('💧', '${impact.waterSavedLiters.toStringAsFixed(0)} л', 'Воды'),
                _statItem('⚡', '${impact.energySavedKwh.toStringAsFixed(1)} кВт·ч', 'Энергии'),
                _statItem('🌬️', '${impact.co2SavedKg.toStringAsFixed(1)} кг', 'CO₂'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _equivRow(String icon, String label, String value) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
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

  List<Widget> _buildCategoryImpact(
    BuildContext context,
    dynamic habits,
    ImpactCalcService calc,
  ) {
    final categoryImpact = calc.calculateImpactByCategory(
      habits,
      DateTime(2000),
      DateTime.now().add(const Duration(days: 1)),
    );

    return categoryImpact.entries.map((entry) {
      final category = HabitCategory.values.firstWhere(
        (c) => c.name == entry.key,
      );
      final impact = entry.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Text(category.icon, style: const TextStyle(fontSize: 24)),
          title: Text(category.displayName),
          subtitle: Text(
            '💧 ${impact.waterSavedLiters.toStringAsFixed(0)}л | ⚡ ${impact.energySavedKwh.toStringAsFixed(1)} | 🌬️ ${impact.co2SavedKg.toStringAsFixed(1)}кг',
          ),
        ),
      );
    }).toList();
  }
}
