/// Модель командного челленджа
class Challenge {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final List<String> participantIds;
  final ChallengeStatus status;

  const Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    this.participantIds = const [],
    this.status = ChallengeStatus.active,
  });

  Challenge copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    String? creatorName,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    List<String>? participantIds,
    ChallengeStatus? status,
  }) {
    return Challenge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      participantIds: participantIds ?? this.participantIds,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'durationDays': durationDays,
      'participantIds': participantIds,
      'status': status.name,
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      creatorId: map['creatorId'] as String,
      creatorName: map['creatorName'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : DateTime.now(),
      durationDays: map['durationDays'] as int? ?? 7,
      participantIds: (map['participantIds'] as List<dynamic>?)?.cast<String>() ?? [],
      status: ChallengeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ChallengeStatus.active,
      ),
    );
  }

  /// Проверка, активен ли ещё челлендж
  bool get isActive {
    return status == ChallengeStatus.active && DateTime.now().isBefore(endDate);
  }

  /// Количество участников
  int get participantCount => participantIds.length;

  /// Максимальное количество участников
  static const int maxParticipants = 5;

  /// Можно ли ещё добавить участников
  bool get canJoin => participantCount < maxParticipants && isActive;
}

/// Статус челленджа
enum ChallengeStatus {
  active,     // Активен
  completed,  // Завершён
  cancelled,  // Отменён
}

/// Прогресс участника в челлендже
class ChallengeParticipantProgress {
  final String challengeId;
  final String participantId;
  final String participantName;
  final int daysCompleted;
  final int totalDays;
  final List<DateTime> completedDates;
  final DateTime lastUpdatedAt;

  const ChallengeParticipantProgress({
    required this.challengeId,
    required this.participantId,
    required this.participantName,
    required this.daysCompleted,
    required this.totalDays,
    this.completedDates = const [],
    required this.lastUpdatedAt,
  });

  ChallengeParticipantProgress copyWith({
    String? challengeId,
    String? participantId,
    String? participantName,
    int? daysCompleted,
    int? totalDays,
    List<DateTime>? completedDates,
    DateTime? lastUpdatedAt,
  }) {
    return ChallengeParticipantProgress(
      challengeId: challengeId ?? this.challengeId,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      daysCompleted: daysCompleted ?? this.daysCompleted,
      totalDays: totalDays ?? this.totalDays,
      completedDates: completedDates ?? this.completedDates,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'participantId': participantId,
      'participantName': participantName,
      'daysCompleted': daysCompleted,
      'totalDays': totalDays,
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  factory ChallengeParticipantProgress.fromMap(Map<String, dynamic> map) {
    return ChallengeParticipantProgress(
      challengeId: map['challengeId'] as String,
      participantId: map['participantId'] as String,
      participantName: map['participantName'] as String? ?? '',
      daysCompleted: map['daysCompleted'] as int? ?? 0,
      totalDays: map['totalDays'] as int? ?? 0,
      completedDates: (map['completedDates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
      lastUpdatedAt: map['lastUpdatedAt'] != null
          ? DateTime.parse(map['lastUpdatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Процент выполнения
  int get progressPercent => totalDays > 0 ? (daysCompleted * 100 ~/ totalDays) : 0;
}
