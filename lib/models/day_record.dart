/// Модель записи выполнения привычек за день
class DayRecord {
  final DateTime date;
  final int totalHabits;
  final int completedHabits;
  final List<String> completedHabitIds;

  const DayRecord({
    required this.date,
    required this.totalHabits,
    required this.completedHabits,
    this.completedHabitIds = const [],
  });

  double get completionPercent =>
      totalHabits > 0 ? (completedHabits / totalHabits) * 100 : 0;

  DayRecord copyWith({
    DateTime? date,
    int? totalHabits,
    int? completedHabits,
    List<String>? completedHabitIds,
  }) {
    return DayRecord(
      date: date ?? this.date,
      totalHabits: totalHabits ?? this.totalHabits,
      completedHabits: completedHabits ?? this.completedHabits,
      completedHabitIds: completedHabitIds ?? this.completedHabitIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date':
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'totalHabits': totalHabits,
      'completedHabits': completedHabits,
      'completedHabitIds': completedHabitIds,
    };
  }

  factory DayRecord.fromMap(Map<String, dynamic> map) {
    return DayRecord(
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      totalHabits: map['totalHabits'] as int? ?? 0,
      completedHabits: map['completedHabits'] as int? ?? 0,
      completedHabitIds:
          (map['completedHabitIds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
