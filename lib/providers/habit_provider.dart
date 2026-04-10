import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class HabitProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Habit> _habits = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Habit> get habits => List.unmodifiable(_habits);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  HabitProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    if (user != null) {
      _listenToHabits(user.uid);
    } else {
      _habits = [];
      notifyListeners();
    }
  }

  void _listenToHabits(String uid) {
    print('[HabitProvider] Начинаю слушать привычки для uid: $uid');
    _firestoreService.getHabitsStream(uid).listen(
      (habits) {
        print('[HabitProvider] Получил ${habits.length} привычек из Firestore');
        _habits = habits;
        _isLoading = false;
        notifyListeners();
        print('[HabitProvider] notifyListeners() вызван, _habits.length=${_habits.length}');
      },
      onError: (error) {
        print('[HabitProvider] Ошибка загрузки привычек: $error');
        _errorMessage = 'Ошибка загрузки привычек: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
    _isLoading = true;
    notifyListeners();
  }

  /// Получить привычки, запланированные на определённую дату
  List<Habit> getHabitsForDay(DateTime date) {
    // DateTime.weekday: 1=Monday...7=Sunday
    int dayOfWeek = date.weekday; // 1-7

    print('[HabitProvider] getHabitsForDay: date=$date, dayOfWeek=$dayOfWeek, всего _habits: ${_habits.length}');

    final filtered = _habits.where((habit) {
      final isNotArchived = !habit.isArchived;
      final isScheduled = habit.isScheduledForDay(dayOfWeek);
      print('[HabitProvider]   habit: "${habit.title}", id=${habit.id}, isArchived=${habit.isArchived}, scheduledDays=${habit.scheduledDaysOfWeek}, scheduledForDay=$isScheduled, included=${isNotArchived && isScheduled}');
      if (isNotArchived) {
        return isScheduled;
      }
      return false;
    }).toList();

    print('[HabitProvider] getHabitsForDay результат: ${filtered.length} привычек');
    return filtered;
  }

  /// Добавить привычку из каталога
  Future<bool> addHabitFromCatalog(Habit catalogHabit, {
    List<int>? scheduledDaysOfWeek,
    DateTime? reminderTime,
    bool? reminderEnabled,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'Пользователь не авторизован';
      notifyListeners();
      return false;
    }

    // Гарантируем, что scheduledDaysOfWeek — пустой список для ежедневных привычек
    final List<int> days = (scheduledDaysOfWeek == null || scheduledDaysOfWeek.isEmpty)
        ? <int>[]
        : scheduledDaysOfWeek;

    final newHabit = Habit(
      id: catalogHabit.id,
      title: catalogHabit.title,
      description: catalogHabit.description,
      category: catalogHabit.category,
      scheduledDaysOfWeek: days,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled ?? false,
      waterSavedLiters: catalogHabit.waterSavedLiters,
      energySavedKwh: catalogHabit.energySavedKwh,
      co2SavedKg: catalogHabit.co2SavedKg,
    );

    try {
      print('[HabitProvider] Добавляю привычку: ${newHabit.title} для пользователя ${user.uid}');
      final docId = await _firestoreService.addHabit(user.uid, newHabit);
      print('[HabitProvider] Привычка добавлена с docId: $docId');

      // Запланировать напоминание
      if (reminderEnabled == true && reminderTime != null) {
        try {
          await _notificationService.scheduleHabitReminder(
            id: docId.hashCode % 100000,
            title: 'Напоминание: ${newHabit.title}',
            description: 'Пора отметить выполнение привычки!',
            reminderTime: reminderTime,
          );
        } catch (notifError) {
          print('[HabitProvider] Ошибка напоминания: $notifError');
        }
      }

      return true;
    } catch (e, stackTrace) {
      print('[HabitProvider] Ошибка добавления привычки: $e');
      print('[HabitProvider] StackTrace: $stackTrace');
      _errorMessage = 'Ошибка добавления привычки: $e';
      notifyListeners();
      return false;
    }
  }

  /// Создать пользовательскую привычку
  Future<bool> addCustomHabit({
    required String title,
    required String description,
    required HabitCategory category,
    List<int>? scheduledDaysOfWeek,
    double waterSavedLiters = 0,
    double energySavedKwh = 0,
    double co2SavedKg = 0,
    DateTime? reminderTime,
    bool? reminderEnabled,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'Пользователь не авторизован';
      notifyListeners();
      return false;
    }

    // Гарантируем, что scheduledDaysOfWeek — пустой список для ежедневных привычек
    final List<int> days = (scheduledDaysOfWeek == null || scheduledDaysOfWeek.isEmpty)
        ? <int>[]
        : scheduledDaysOfWeek;

    // Генерируем уникальный ID для пользовательской привычки
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final customId = 'custom_${user.uid}_$timestamp';

    final newHabit = Habit(
      id: customId,
      title: title,
      description: description,
      category: category,
      scheduledDaysOfWeek: days,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled ?? false,
      waterSavedLiters: waterSavedLiters,
      energySavedKwh: energySavedKwh,
      co2SavedKg: co2SavedKg,
    );

    try {
      print('[HabitProvider] Создаю пользовательскую привычку: ${newHabit.title} для пользователя ${user.uid}');
      final docId = await _firestoreService.addHabit(user.uid, newHabit);
      print('[HabitProvider] Пользовательская привычка создана с docId: $docId');

      // Запланировать напоминание
      if (reminderEnabled == true && reminderTime != null) {
        try {
          await _notificationService.scheduleHabitReminder(
            id: docId.hashCode % 100000,
            title: 'Напоминание: ${newHabit.title}',
            description: 'Пора отметить выполнение привычки!',
            reminderTime: reminderTime,
          );
        } catch (notifError) {
          print('[HabitProvider] Ошибка напоминания: $notifError');
        }
      }

      return true;
    } catch (e, stackTrace) {
      print('[HabitProvider] Ошибка создания пользовательской привычки: $e');
      print('[HabitProvider] StackTrace: $stackTrace');
      _errorMessage = 'Ошибка создания привычки: $e';
      notifyListeners();
      return false;
    }
  }

  /// Отметить привычку на дату
  Future<void> toggleHabitCompletion(Habit habit, DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[HabitProvider] toggleHabitCompletion: пользователь не авторизован');
      return;
    }

    print('[HabitProvider] toggleHabitCompletion: habit="${habit.title}", date=$date, isCompleted=${habit.isCompletedOn(date)}');

    Habit updatedHabit;
    if (habit.isCompletedOn(date)) {
      updatedHabit = habit.markUncompleted(date);
      print('[HabitProvider]   -> снимаем отметку');
    } else {
      updatedHabit = habit.markCompleted(date);
      print('[HabitProvider]   -> отмечаем как выполненное');
    }
    
    print('[HabitProvider]   updatedHabit completedDates keys: ${updatedHabit.completedDates.keys.toList()}');

    try {
      await _firestoreService.updateHabit(user.uid, updatedHabit);
      print('[HabitProvider]   успешно обновлено в Firestore');
    } catch (e) {
      print('[HabitProvider]   ошибка сохранения: $e');
      _errorMessage = 'Ошибка сохранения';
      notifyListeners();
    }
  }

  /// Обновить настройки привычки
  Future<bool> updateHabitSettings(
    Habit habit, {
    List<int>? scheduledDaysOfWeek,
    DateTime? reminderTime,
    bool? reminderEnabled,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final updatedHabit = habit.copyWith(
      scheduledDaysOfWeek: scheduledDaysOfWeek,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
    );

    try {
      await _firestoreService.updateHabit(user.uid, updatedHabit);

      // Обновить напоминание
      if (reminderEnabled == true && reminderTime != null) {
        await _notificationService.scheduleHabitReminder(
          id: habit.id.hashCode % 100000,
          title: 'Напоминание: ${habit.title}',
          description: 'Пора отметить выполнение привычки!',
          reminderTime: reminderTime,
        );
      } else {
        await _notificationService.cancelHabitReminder(habit.id.hashCode % 100000);
      }

      return true;
    } catch (e) {
      _errorMessage = 'Ошибка обновления привычки';
      notifyListeners();
      return false;
    }
  }

  /// Удалить привычку
  Future<bool> deleteHabit(Habit habit) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestoreService.deleteHabit(user.uid, habit.id);
      await _notificationService.cancelHabitReminder(habit.id.hashCode % 100000);
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка удаления привычки';
      notifyListeners();
      return false;
    }
  }

  /// Получить привычку по ID
  Habit? getHabitById(String id) {
    try {
      return _habits.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Получить все категории выбранных привычек
  Set<HabitCategory> getSelectedCategories() {
    return _habits.map((h) => h.category).toSet();
  }

  /// Проверить, выбрана ли привычка из каталога
  bool isHabitSelected(String catalogId) {
    return _habits.any((h) => h.id == catalogId);
  }

  /// Получить привычки по категории
  List<Habit> getHabitsByCategory(HabitCategory category) {
    return _habits.where((h) => h.category == category).toList();
  }

  /// Общее количество выполнений
  int getTotalCompletions() {
    return _habits.fold(0, (sum, h) => sum + h.completedDates.length);
  }

  /// Самая длинная серия
  int getLongestStreak() {
    if (_habits.isEmpty) return 0;

    int maxStreak = 0;
    final now = DateTime.now();

    for (final habit in _habits) {
      final streak = habit.calculateStreakUntil(now);
      if (streak > maxStreak) {
        maxStreak = streak;
      }
    }

    return maxStreak;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
