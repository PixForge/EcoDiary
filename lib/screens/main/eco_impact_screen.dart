import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../services/impact_calc_service.dart';
import '../../models/eco_impact.dart';
import '../../models/habit_category.dart';
import '../../helpers/localization.dart';

class EcoImpactScreen extends StatelessWidget {
  const EcoImpactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>().habits;
    final impactCalc = ImpactCalcService();

    final todayImpact = impactCalc.calculateTodayImpact(habits);
    final weekImpact = impactCalc.calculateWeekImpact(habits);
    final monthImpact = impactCalc.calculateMonthImpact(habits);
    final allImpact = impactCalc.calculateAllTimeImpact(habits);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('eco_impact'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Общий эффект
          _impactCard(
            context,
            context.tr('all_time_with_emoji'),
            allImpact,
            impactCalc,
            const Color(0xFF2E7D32),
          ),
          const SizedBox(height: 16),
          _impactCard(
            context,
            context.tr('month_with_emoji'),
            monthImpact,
            impactCalc,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _impactCard(
            context,
            context.tr('week_with_emoji'),
            weekImpact,
            impactCalc,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _impactCard(
            context,
            context.tr('today_with_emoji'),
            todayImpact,
            impactCalc,
            Colors.purple,
          ),

          const SizedBox(height: 32),

          // Визуальные эквиваленты
          _sectionHeader(context, context.tr('visual_equivalents')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _equivRow(
                    '🌳',
                    context.tr('trees_co2'),
                    impactCalc.co2ToTrees(allImpact.co2SavedKg).toStringAsFixed(1),
                  ),
                  const Divider(height: 24),
                  _equivRow(
                    '🚗',
                    context.tr('car_km_co2'),
                    impactCalc.co2ToCarKm(allImpact.co2SavedKg).toStringAsFixed(0),
                  ),
                  const Divider(height: 24),
                  _equivRow(
                    '💡',
                    context.tr('led_hours'),
                    impactCalc.energyToLedHours(allImpact.energySavedKwh).toStringAsFixed(0),
                  ),
                  const Divider(height: 24),
                  _equivRow(
                    '🛁',
                    context.tr('baths_water'),
                    impactCalc.waterToBaths(allImpact.waterSavedLiters).toStringAsFixed(1),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // По категориям
          _sectionHeader(context, context.tr('by_category')),
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
                _statItem('💧', '${impact.waterSavedLiters.toStringAsFixed(0)} l', AppLocalizations.of(context).translate('water_short')),
                _statItem('⚡', '${impact.energySavedKwh.toStringAsFixed(1)} kWh', AppLocalizations.of(context).translate('energy_short')),
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
          title: Text(
            category.localizedDisplayName(
              Localizations.localeOf(context).languageCode,
            ),
          ),
          subtitle: Text(
            '💧 ${impact.waterSavedLiters.toStringAsFixed(0)}л | ⚡ ${impact.energySavedKwh.toStringAsFixed(1)} | 🌬️ ${impact.co2SavedKg.toStringAsFixed(1)}кг',
          ),
        ),
      );
    }).toList();
  }
}
