import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../models/achievement.dart';
import '../services/impact_calc_service.dart';
import '../services/firestore_service.dart';
import '../data/achievement_catalog.dart';

class StatsProvider extends ChangeNotifier {
  final ImpactCalcService _impactCalc = ImpactCalcService();
  final FirestoreService _firestoreService = FirestoreService();

  List<Achievement> _unlockedAchievements = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  List<Achievement> get unlockedAchievements =>
      List.unmodifiable(_unlockedAchievements);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;

  /// Установить выбранную дату
  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  /// Перейти на предыдущий день
  void goToPreviousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    notifyListeners();
  }

  /// Перейти на следующий день
  void goToNextDay() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (_selectedDate.isBefore(tomorrow)) {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + 1,
      );
      notifyListeners();
    }
  }

  /// Процент выполнения за день
  double getDailyCompletionPercent(List<Habit> habitsForDay) {
    if (habitsForDay.isEmpty) return 0;
    final completed = habitsForDay
        .where((h) => h.isCompletedOn(_selectedDate))
        .length;
    return (completed / habitsForDay.length) * 100;
  }

  /// Процент выполнения за неделю
  double getWeeklyCompletionPercent(List<Habit> allHabits) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    int totalSlots = 0;
    int completedSlots = 0;

    for (final habit in allHabits) {
      DateTime checkDate = weekAgo;
      while (checkDate.isBefore(now) || checkDate.isAtSameMomentAs(now)) {
        if (habit.isScheduledForDay(checkDate.weekday)) {
          totalSlots++;
          if (habit.isCompletedOn(checkDate)) {
            completedSlots++;
          }
        }
        checkDate = checkDate.add(const Duration(days: 1));
      }
    }

    return totalSlots > 0 ? (completedSlots / totalSlots) * 100 : 0;
  }

  /// Процент выполнения за месяц
  double getMonthlyCompletionPercent(List<Habit> allHabits) {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));

    int totalSlots = 0;
    int completedSlots = 0;

    for (final habit in allHabits) {
      DateTime checkDate = monthAgo;
      while (checkDate.isBefore(now) || checkDate.isAtSameMomentAs(now)) {
        if (habit.isScheduledForDay(checkDate.weekday)) {
          totalSlots++;
          if (habit.isCompletedOn(checkDate)) {
            completedSlots++;
          }
        }
        checkDate = checkDate.add(const Duration(days: 1));
      }
    }

    return totalSlots > 0 ? (completedSlots / totalSlots) * 100 : 0;
  }

  /// Данные для графика за последние 7 дней
  List<Map<String, dynamic>> getWeekChartData(List<Habit> allHabits) {
    final List<Map<String, dynamic>> data = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final habitsForDay = allHabits
          .where((h) => h.isScheduledForDay(date.weekday))
          .toList();
      final completed = habitsForDay
          .where((h) => h.isCompletedOn(date))
          .length;
      final percent = habitsForDay.isNotEmpty
          ? (completed / habitsForDay.length) * 100
          : 0;

      data.add({
        'date': date,
        'percent': percent,
        'completed': completed,
        'total': habitsForDay.length,
      });
    }

    return data;
  }

  /// Данные для графика за последние 30 дней
  List<Map<String, dynamic>> getMonthChartData(List<Habit> allHabits) {
    final List<Map<String, dynamic>> data = [];
    final now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final habitsForDay = allHabits
          .where((h) => h.isScheduledForDay(date.weekday))
          .toList();
      final completed = habitsForDay
          .where((h) => h.isCompletedOn(date))
          .length;
      final percent = habitsForDay.isNotEmpty
          ? (completed / habitsForDay.length) * 100
          : 0;

      data.add({
        'date': date,
        'percent': percent,
      });
    }

    return data;
  }

  /// Статистика по категориям
  Map<String, int> getCategoryStats(List<Habit> allHabits) {
    final Map<String, int> stats = {};

    for (final habit in allHabits) {
      final category = habit.category.name;
      final completions = habit.completedDates.length;

      if (stats.containsKey(category)) {
        stats[category] = stats[category]! + completions;
      } else {
        stats[category] = completions;
      }
    }

    return stats;
  }

  /// Проверить и разблокировать достижения
  Future<List<Achievement>> checkAndUnlockAchievements(
    List<Habit> allHabits,
    String uid,
  ) async {
    final List<Achievement> newlyUnlocked = [];
    final totalCompletions = allHabits.fold<int>(
      0,
      (sum, h) => sum + h.completedDates.length,
    );
    final longestStreak = _getLongestStreak(allHabits);
    final categories = allHabits.map((h) => h.category).toSet();
    final impact = _impactCalc.calculateAllTimeImpact(allHabits);

    // Получить уже разблокированные
    final existing = await _firestoreService.getAchievements(uid);
    final existingIds = existing.map((a) => a.id).toSet();

    for (final achievement in AchievementCatalog.allAchievements) {
      if (existingIds.contains(achievement.id)) continue;

      bool shouldUnlock = false;

      switch (achievement.id) {
        case 'streak_7':
          shouldUnlock = longestStreak >= 7;
          break;
        case 'streak_30':
          shouldUnlock = longestStreak >= 30;
          break;
        case 'streak_60':
          shouldUnlock = longestStreak >= 60;
          break;
        case 'streak_100':
          shouldUnlock = longestStreak >= 100;
          break;
        case 'streak_365':
          shouldUnlock = longestStreak >= 365;
          break;
        case 'total_50':
          shouldUnlock = totalCompletions >= 50;
          break;
        case 'total_100':
          shouldUnlock = totalCompletions >= 100;
          break;
        case 'total_250':
          shouldUnlock = totalCompletions >= 250;
          break;
        case 'total_500':
          shouldUnlock = totalCompletions >= 500;
          break;
        case 'total_1000':
          shouldUnlock = totalCompletions >= 1000;
          break;
        case 'all_categories':
          shouldUnlock = categories.length >= 6;
          break;
        case 'water_100':
          shouldUnlock = impact.waterSavedLiters >= 100;
          break;
        case 'water_1000':
          shouldUnlock = impact.waterSavedLiters >= 1000;
          break;
        case 'water_10000':
          shouldUnlock = impact.waterSavedLiters >= 10000;
          break;
        case 'energy_100':
          shouldUnlock = impact.energySavedKwh >= 100;
          break;
        case 'energy_500':
          shouldUnlock = impact.energySavedKwh >= 500;
          break;
        case 'co2_50':
          shouldUnlock = impact.co2SavedKg >= 50;
          break;
        case 'co2_200':
          shouldUnlock = impact.co2SavedKg >= 200;
          break;
        case 'co2_1000':
          shouldUnlock = impact.co2SavedKg >= 1000;
          break;
        case 'first_habit':
          shouldUnlock = totalCompletions >= 1;
          break;
        case 'first_week_perfect':
          shouldUnlock = _isPerfectWeek(allHabits);
          break;
        case 'first_month_perfect':
          shouldUnlock = _isPerfectMonth(allHabits);
          break;
      }

      if (shouldUnlock) {
        final unlocked = achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        await _firestoreService.saveAchievement(uid, unlocked);
        newlyUnlocked.add(unlocked);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      _unlockedAchievements = [..._unlockedAchievements, ...newlyUnlocked];
      notifyListeners();
    }

    return newlyUnlocked;
  }

  /// Загрузить достижения
  Future<void> loadAchievements(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _unlockedAchievements = await _firestoreService.getAchievements(uid);
    } catch (e) {
      _errorMessage = 'Ошибка загрузки достижений';
    }

    _isLoading = false;
    notifyListeners();
  }

  int _getLongestStreak(List<Habit> allHabits) {
    if (allHabits.isEmpty) return 0;
    int maxStreak = 0;
    final now = DateTime.now();
    for (final habit in allHabits) {
      final streak = habit.calculateStreakUntil(now);
      if (streak > maxStreak) maxStreak = streak;
    }
    return maxStreak;
  }

  bool _isPerfectWeek(List<Habit> allHabits) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    DateTime checkDate = weekAgo;

    while (checkDate.isBefore(now)) {
      final habitsForDay =
          allHabits.where((h) => h.isScheduledForDay(checkDate.weekday)).toList();
      final completed =
          habitsForDay.where((h) => h.isCompletedOn(checkDate)).length;
      if (habitsForDay.isNotEmpty && completed < habitsForDay.length) {
        return false;
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }
    return true;
  }

  bool _isPerfectMonth(List<Habit> allHabits) {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    DateTime checkDate = monthAgo;

    while (checkDate.isBefore(now)) {
      final habitsForDay =
          allHabits.where((h) => h.isScheduledForDay(checkDate.weekday)).toList();
      final completed =
          habitsForDay.where((h) => h.isCompletedOn(checkDate)).length;
      if (habitsForDay.isNotEmpty && completed < habitsForDay.length) {
        return false;
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }
    return true;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
