/// Модель друга
class Friend {
  final String uid;
  final String email;
  final String displayName;
  final String avatarBase64;
  final DateTime friendsSince;
  final FriendStats stats;

  const Friend({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarBase64 = '',
    required this.friendsSince,
    required this.stats,
  });

  Friend copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? avatarBase64,
    DateTime? friendsSince,
    FriendStats? stats,
  }) {
    return Friend(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      friendsSince: friendsSince ?? this.friendsSince,
      stats: stats ?? this.stats,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'avatarBase64': avatarBase64,
      'friendsSince': friendsSince.toIso8601String(),
      'stats': stats.toMap(),
    };
  }

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String? ?? '',
      avatarBase64: map['avatarBase64'] as String? ?? '',
      friendsSince: map['friendsSince'] != null
          ? DateTime.parse(map['friendsSince'] as String)
          : DateTime.now(),
      stats: map['stats'] != null
          ? FriendStats.fromMap(map['stats'] as Map<String, dynamic>)
          : const FriendStats(),
    );
  }
}

/// Статистика друга для ленты
class FriendStats {
  final int currentStreak;      // Текущая серия дней
  final int todayProgress;      // Процент выполнения сегодня (0-100)
  final int weeklyProgress;     // Процент выполнения за неделю (0-100)
  final int monthlyProgress;    // Процент выполнения за месяц (0-100)
  final int recentAchievements; // Количество новых достижений
  final DateTime? lastActiveAt; // Последняя активность

  const FriendStats({
    this.currentStreak = 0,
    this.todayProgress = 0,
    this.weeklyProgress = 0,
    this.monthlyProgress = 0,
    this.recentAchievements = 0,
    this.lastActiveAt,
  });

  FriendStats copyWith({
    int? currentStreak,
    int? todayProgress,
    int? weeklyProgress,
    int? monthlyProgress,
    int? recentAchievements,
    DateTime? lastActiveAt,
  }) {
    return FriendStats(
      currentStreak: currentStreak ?? this.currentStreak,
      todayProgress: todayProgress ?? this.todayProgress,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      monthlyProgress: monthlyProgress ?? this.monthlyProgress,
      recentAchievements: recentAchievements ?? this.recentAchievements,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'todayProgress': todayProgress,
      'weeklyProgress': weeklyProgress,
      'monthlyProgress': monthlyProgress,
      'recentAchievements': recentAchievements,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }

  factory FriendStats.fromMap(Map<String, dynamic> map) {
    return FriendStats(
      currentStreak: map['currentStreak'] as int? ?? 0,
      todayProgress: map['todayProgress'] as int? ?? 0,
      weeklyProgress: map['weeklyProgress'] as int? ?? 0,
      monthlyProgress: map['monthlyProgress'] as int? ?? 0,
      recentAchievements: map['recentAchievements'] as int? ?? 0,
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.parse(map['lastActiveAt'] as String)
          : null,
    );
  }
}
