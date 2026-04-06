import '../models/habit.dart';
import '../models/eco_impact.dart';

/// Сервис расчёта экологического эффекта
class ImpactCalcService {
  /// Рассчитать общий экологический эффект за период
  EcoImpact calculateTotalImpact(
    List<Habit> habits,
    DateTime startDate,
    DateTime endDate,
  ) {
    double totalWater = 0;
    double totalEnergy = 0;
    double totalCo2 = 0;

    for (final habit in habits) {
      int completionsInRange = 0;
      for (final entry in habit.completedDates.entries) {
        final dateStr = entry.key;
        try {
          final date = DateTime.parse(dateStr);
          if ((date.isAtSameMomentAs(startDate) || date.isAfter(startDate)) &&
              (date.isAtSameMomentAs(endDate) || date.isBefore(endDate.add(const Duration(days: 1))))) {
            completionsInRange++;
          }
        } catch (e) {
          // Пропустить некорректные даты
        }
      }

      totalWater += habit.waterSavedLiters * completionsInRange;
      totalEnergy += habit.energySavedKwh * completionsInRange;
      totalCo2 += habit.co2SavedKg * completionsInRange;
    }

    return EcoImpact(
      waterSavedLiters: totalWater,
      energySavedKwh: totalEnergy,
      co2SavedKg: totalCo2,
    );
  }

  /// Рассчитать эффект по категориям
  Map<String, EcoImpact> calculateImpactByCategory(
    List<Habit> habits,
    DateTime startDate,
    DateTime endDate,
  ) {
    final Map<String, EcoImpact> result = {};

    for (final habit in habits) {
      final category = habit.category.name;
      int completionsInRange = 0;
      for (final entry in habit.completedDates.entries) {
        final dateStr = entry.key;
        try {
          final date = DateTime.parse(dateStr);
          if ((date.isAtSameMomentAs(startDate) || date.isAfter(startDate)) &&
              (date.isAtSameMomentAs(endDate) || date.isBefore(endDate.add(const Duration(days: 1))))) {
            completionsInRange++;
          }
        } catch (e) {
          // Пропустить некорректные даты
        }
      }

      final impact = EcoImpact(
        waterSavedLiters: habit.waterSavedLiters * completionsInRange,
        energySavedKwh: habit.energySavedKwh * completionsInRange,
        co2SavedKg: habit.co2SavedKg * completionsInRange,
      );

      if (result.containsKey(category)) {
        result[category] = result[category]! + impact;
      } else {
        result[category] = impact;
      }
    }

    return result;
  }

  /// Рассчитать эффект за сегодня
  EcoImpact calculateTodayImpact(List<Habit> habits) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return calculateTotalImpact(habits, today, today);
  }

  /// Рассчитать эффект за неделю
  EcoImpact calculateWeekImpact(List<Habit> habits) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return calculateTotalImpact(habits, weekAgo, now);
  }

  /// Рассчитать эффект за месяц
  EcoImpact calculateMonthImpact(List<Habit> habits) {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return calculateTotalImpact(habits, monthAgo, now);
  }

  /// Рассчитать эффект за всё время
  EcoImpact calculateAllTimeImpact(List<Habit> habits) {
    return calculateTotalImpact(
      habits,
      DateTime(2000),
      DateTime.now().add(const Duration(days: 1)),
    );
  }

  /// Визуализация: сколько деревьев эквивалентно CO₂
  double co2ToTrees(double co2Kg) {
    // Одно дерево поглощает ~22 кг CO₂ в год
    return co2Kg / 22;
  }

  /// Визуализация: сколько км на авто эквивалентно CO₂
  double co2ToCarKm(double co2Kg) {
    // Средний автомобиль: ~0.12 кг CO₂ на км
    return co2Kg / 0.12;
  }

  /// Визуализация: сколько ламп можно питать сэкономленной энергией
  double energyToLedHours(double energyKwh) {
    // LED лампа 10W = 0.01 кВт·ч в час
    return energyKwh / 0.01;
  }

  /// Визуализация: сколько ванн можно наполнить сохранённой водой
  double waterToBaths(double waterLiters) {
    // Средняя ванна: ~150 литров
    return waterLiters / 150;
  }
}
