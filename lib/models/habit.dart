import 'habit_category.dart';

/// Модель экологической привычки
class Habit {
  final String id;
  final String title;
  final String description;
  final HabitCategory category;
  final List<int> scheduledDaysOfWeek; // 1=Mon..7=Sun, пустой = ежедневно
  final DateTime? reminderTime; // время напоминания (часы и минуты)
  final bool reminderEnabled;
  final double waterSavedLiters; // литров воды сохранено за выполнение
  final double energySavedKwh; // кВт·ч сэкономлено за выполнение
  final double co2SavedKg; // кг CO₂ не попало в атмосферу
  final Map<String, List<String>> completedDates; // "YYYY-MM-DD": ["timestamp"]
  final DateTime createdAt;
  final bool isArchived;

  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.scheduledDaysOfWeek = const [],
    this.reminderTime,
    this.reminderEnabled = false,
    this.waterSavedLiters = 0,
    this.energySavedKwh = 0,
    this.co2SavedKg = 0,
    this.completedDates = const {},
    DateTime? createdAt,
    this.isArchived = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Проверить, запланирована ли привычка на определённый день недели
  bool isScheduledForDay(int dayOfWeek) {
    if (scheduledDaysOfWeek.isEmpty) return true; // ежедневно
    return scheduledDaysOfWeek.contains(dayOfWeek);
  }

  /// Отметить выполнение на указанную дату
  Habit markCompleted(DateTime date) {
    final key = _dateKey(date);
    final updated = Map<String, List<String>>.from(completedDates);
    final existing = updated[key] ?? [];
    if (!existing.contains(key)) {
      updated[key] = [DateTime.now().toIso8601String()];
    }
    return copyWith(completedDates: updated);
  }

  /// Отменить выполнение на указанную дату
  Habit markUncompleted(DateTime date) {
    final key = _dateKey(date);
    final updated = Map<String, List<String>>.from(completedDates);
    updated.remove(key);
    return copyWith(completedDates: updated);
  }

  /// Проверить, выполнена ли привычка на указанную дату
  bool isCompletedOn(DateTime date) {
    return completedDates.containsKey(_dateKey(date));
  }

  /// Получить количество выполнений привычки
  int get totalCompletions => completedDates.length;

  /// Рассчитать серию дней подряд до указанной даты
  int calculateStreakUntil(DateTime date) {
    int streak = 0;
    DateTime checkDate = date;

    while (true) {
      final key = _dateKey(checkDate);
      if (completedDates.containsKey(key)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    HabitCategory? category,
    List<int>? scheduledDaysOfWeek,
    DateTime? reminderTime,
    bool? reminderEnabled,
    double? waterSavedLiters,
    double? energySavedKwh,
    double? co2SavedKg,
    Map<String, List<String>>? completedDates,
    DateTime? createdAt,
    bool? isArchived,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      scheduledDaysOfWeek: scheduledDaysOfWeek ?? this.scheduledDaysOfWeek,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      waterSavedLiters: waterSavedLiters ?? this.waterSavedLiters,
      energySavedKwh: energySavedKwh ?? this.energySavedKwh,
      co2SavedKg: co2SavedKg ?? this.co2SavedKg,
      completedDates: completedDates ?? this.completedDates,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'scheduledDaysOfWeek': scheduledDaysOfWeek,
      'reminderTime': reminderTime != null
          ? {'hour': reminderTime!.hour, 'minute': reminderTime!.minute}
          : null,
      'reminderEnabled': reminderEnabled,
      'waterSavedLiters': waterSavedLiters,
      'energySavedKwh': energySavedKwh,
      'co2SavedKg': co2SavedKg,
      'completedDates': completedDates,
      'createdAt': createdAt.toIso8601String(),
      'isArchived': isArchived,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    DateTime? reminderTime;
    if (map['reminderTime'] != null) {
      reminderTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        map['reminderTime']['hour'] as int,
        map['reminderTime']['minute'] as int,
      );
    }
    // Гарантируем, что scheduledDaysOfWeek никогда не будет null
    final rawScheduledDays = map['scheduledDaysOfWeek'];
    List<int> scheduledDays = [];
    if (rawScheduledDays != null && rawScheduledDays is List) {
      scheduledDays = rawScheduledDays.cast<int>();
    }
    
    return Habit(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: HabitCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => HabitCategory.waterSaving,
      ),
      scheduledDaysOfWeek: scheduledDays,
      reminderTime: reminderTime,
      reminderEnabled: _toBool(map['reminderEnabled']) ?? false,
      waterSavedLiters: (map['waterSavedLiters'] as num?)?.toDouble() ?? 0,
      energySavedKwh: (map['energySavedKwh'] as num?)?.toDouble() ?? 0,
      co2SavedKg: (map['co2SavedKg'] as num?)?.toDouble() ?? 0,
      completedDates: _toMapStringList(map['completedDates']),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      isArchived: _toBool(map['isArchived']) ?? false,
    );
  }

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is num) return value != 0;
    return false;
  }

  static Map<String, List<String>> _toMapStringList(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return value.map((k, v) {
        if (v is List) {
          return MapEntry(k.toString(), v.cast<String>());
        }
        return MapEntry(k.toString(), <String>[]);
      });
    }
    return {};
  }
}
