import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge.dart';
import '../models/friend.dart';

/// Сервис управления командными челленджами
class ChallengesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Коллекция челленджей
  CollectionReference<Map<String, dynamic>> get _challenges =>
      _db.collection('challenges');

  /// Коллекция прогресса участников
  CollectionReference<Map<String, dynamic>> get _challengeProgress =>
      _db.collection('challenge_progress');

  // ========== СОЗДАНИЕ И УПРАВЛЕНИЕ ЧЕЛЛЕНДЖАМИ ==========

  /// Создать новый челлендж
  Future<Challenge> createChallenge({
    required String name,
    required String description,
    required String creatorId,
    required String creatorName,
    required int durationDays,
    required DateTime startDate,
  }) async {
    final endDate = startDate.add(Duration(days: durationDays));

    final challenge = Challenge(
      id: _challenges.doc().id,
      name: name,
      description: description,
      creatorId: creatorId,
      creatorName: creatorName,
      createdAt: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      durationDays: durationDays,
      participantIds: [creatorId], // Создатель автоматически участник
      status: ChallengeStatus.active,
    );

    await _challenges.doc(challenge.id).set(challenge.toMap());

    // Создать запись прогресса для создателя
    await _createParticipantProgress(
      challengeId: challenge.id,
      participantId: creatorId,
      participantName: creatorName,
      totalDays: durationDays,
    );

    return challenge;
  }

  /// Создать запись прогресса участника
  Future<void> _createParticipantProgress({
    required String challengeId,
    required String participantId,
    required String participantName,
    required int totalDays,
  }) async {
    final progress = ChallengeParticipantProgress(
      challengeId: challengeId,
      participantId: participantId,
      participantName: participantName,
      daysCompleted: 0,
      totalDays: totalDays,
      completedDates: [],
      lastUpdatedAt: DateTime.now(),
    );

    await _challengeProgress.doc('${challengeId}_$participantId').set(progress.toMap());
  }

  /// Пригласить участника в челлендж
  Future<void> inviteParticipant({
    required String challengeId,
    required String participantId,
    required String participantName,
  }) async {
    final challengeDoc = await _challenges.doc(challengeId).get();
    if (!challengeDoc.exists) {
      throw Exception('Челлендж не найден');
    }

    final challenge = Challenge.fromMap(challengeDoc.data()!);

    if (!challenge.canJoin) {
      throw Exception('Челлендж закрыт для новых участников');
    }

    if (challenge.participantIds.contains(participantId)) {
      throw Exception('Участник уже в челлендже');
    }

    // Добавить участника
    await _challenges.doc(challengeId).update({
      'participantIds': FieldValue.arrayUnion([participantId]),
    });

    // Создать запись прогресса
    await _createParticipantProgress(
      challengeId: challengeId,
      participantId: participantId,
      participantName: participantName,
      totalDays: challenge.durationDays,
    );
  }

  /// Получить челлендж по ID
  Stream<Challenge?> getChallengeStream(String challengeId) {
    return _challenges.doc(challengeId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return Challenge.fromMap(snapshot.data()!);
    });
  }

  /// Получить все активные челленджи пользователя
  Stream<List<Challenge>> getUserChallengesStream(String userId) {
    return _challenges
        .where('participantIds', arrayContains: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('endDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Challenge.fromMap(doc.data()))
            .toList());
  }

  /// Получить челленджи, созданные пользователем
  Stream<List<Challenge>> getCreatedChallengesStream(String userId) {
    return _challenges
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Challenge.fromMap(doc.data()))
            .toList());
  }

  // ========== ПРОГРЕСС В ЧЕЛЛЕНДЖЕ ==========

  /// Отметить день как выполненный
  Future<void> markDayCompleted({
    required String challengeId,
    required String participantId,
  }) async {
    final progressDoc = await _challengeProgress.doc('${challengeId}_$participantId').get();
    if (!progressDoc.exists) {
      throw Exception('Прогресс не найден');
    }

    final progress = ChallengeParticipantProgress.fromMap(progressDoc.data()!);
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    // Проверить, не отмечен ли уже сегодня
    final alreadyMarked = progress.completedDates.any((date) {
      final d = DateTime(date.year, date.month, date.day);
      return d == todayStart;
    });

    if (alreadyMarked) {
      throw Exception('Уже отмечено сегодня');
    }

    // Добавить дату и обновить прогресс
    final updatedDates = [...progress.completedDates, todayStart];

    await _challengeProgress.doc('${challengeId}_$participantId').update({
      'daysCompleted': updatedDates.length,
      'completedDates': updatedDates.map((d) => d.toIso8601String()).toList(),
      'lastUpdatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Получить прогресс всех участников челленджа
  Stream<List<ChallengeParticipantProgress>> getChallengeProgressStream(String challengeId) {
    return _challengeProgress
        .where('challengeId', isEqualTo: challengeId)
        .orderBy('daysCompleted', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChallengeParticipantProgress.fromMap(doc.data()))
            .toList());
  }

  /// Получить прогресс конкретного участника
  Stream<ChallengeParticipantProgress?> getParticipantProgressStream({
    required String challengeId,
    required String participantId,
  }) {
    return _challengeProgress.doc('${challengeId}_$participantId').snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return ChallengeParticipantProgress.fromMap(snapshot.data()!);
    });
  }

  // ========== ЗАВЕРШЕНИЕ ЧЕЛЛЕНДЖА ==========

  /// Завершить челлендж (автоматически по дате или вручную)
  Future<void> completeChallenge(String challengeId) async {
    await _challenges.doc(challengeId).update({
      'status': 'completed',
    });
  }

  /// Отменить челлендж
  Future<void> cancelChallenge(String challengeId) async {
    await _challenges.doc(challengeId).update({
      'status': 'cancelled',
    });
  }

  // ========== ТАБЛИЦА ЛИДЕРОВ ==========

  /// Получить рейтинг друзей по прогрессу за период
  Future<List<FriendLeaderboardEntry>> getFriendsLeaderboard({
    required String userId,
    required LeaderboardPeriod period,
  }) async {
    // Получаем список друзей
    final friendsSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .get();

    final friends = friendsSnapshot.docs
        .map((doc) => Friend.fromMap(doc.data()))
        .toList();

    // Собираем статистику для каждого друга
    final entries = <FriendLeaderboardEntry>[];

    for (final friend in friends) {
      // Получаем прогресс из stats
      int progress = 0;
      switch (period) {
        case LeaderboardPeriod.weekly:
          progress = friend.stats.weeklyProgress;
          break;
        case LeaderboardPeriod.monthly:
          progress = friend.stats.monthlyProgress;
          break;
      }

      entries.add(FriendLeaderboardEntry(
        uid: friend.uid,
        displayName: friend.displayName,
        avatarBase64: friend.avatarBase64,
        progress: progress,
        streak: friend.stats.currentStreak,
      ));
    }

    // Сортируем по прогрессу
    entries.sort((a, b) => b.progress.compareTo(a.progress));

    return entries;
  }
}

/// Запись в таблице лидеров
class FriendLeaderboardEntry {
  final String uid;
  final String displayName;
  final String avatarBase64;
  final int progress;
  final int streak;

  const FriendLeaderboardEntry({
    required this.uid,
    required this.displayName,
    this.avatarBase64 = '',
    required this.progress,
    required this.streak,
  });
}

/// Период для таблицы лидеров
enum LeaderboardPeriod {
  weekly,
  monthly,
}

extension LeaderboardPeriodExtension on LeaderboardPeriod {
  String get displayName {
    switch (this) {
      case LeaderboardPeriod.weekly:
        return 'Неделя';
      case LeaderboardPeriod.monthly:
        return 'Месяц';
    }
  }
}
