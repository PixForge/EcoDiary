import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';
import '../models/achievement.dart';

/// Сервис работы с Cloud Firestore
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Ссылка на коллекцию пользователей
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  /// Ссылка на коллекцию привычек пользователя
  CollectionReference<Map<String, dynamic>> _habitsCollection(String uid) {
    return _users.doc(uid).collection('habits');
  }

  /// Ссылка на документ профиля
  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) {
    return _users.doc(uid).collection('profile').doc('data');
  }

  /// Ссылка на коллекцию достижений
  CollectionReference<Map<String, dynamic>> _achievementsCollection(String uid) {
    return _users.doc(uid).collection('achievements');
  }

  // ========== ПРОФИЛЬ ==========

  /// Создать или обновить профиль
  Future<void> saveProfile(UserProfile profile) async {
    await _profileDoc(profile.uid).set(
      profile.toMap(),
      SetOptions(merge: true),
    );
  }

  /// Получить профиль пользователя
  Stream<UserProfile?> getProfileStream(String uid) {
    return _profileDoc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserProfile.fromMap(snapshot.data()!);
    });
  }

  /// Получить профиль (однократно)
  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _profileDoc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  // ========== ПРИВЫЧКИ ==========

  /// Поток всех привычек пользователя
  Stream<List<Habit>> getHabitsStream(String uid) {
    print('[Firestore] Подписка на привычки пользователя: $uid');
    return _habitsCollection(uid)
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final habits = snapshot.docs
          .map((doc) {
        final data = doc.data();
        print('[Firestore] Документ: id=${doc.id}, title=${data['title']}, isArchived=${data['isArchived']}');
        return Habit.fromMap({...data, 'id': doc.id});
      })
          .toList();
      print('[Firestore] Загружено привычек: ${habits.length}');
      return habits;
    });
  }

  /// Добавить привычку
  Future<String> addHabit(String uid, Habit habit) async {
    // Используем catalog habit ID как document ID для предотвращения дубликатов
    await _habitsCollection(uid).doc(habit.id).set(habit.toMap());
    return habit.id;
  }

  /// Обновить привычку
  Future<void> updateHabit(String uid, Habit habit) async {
    await _habitsCollection(uid).doc(habit.id).set(habit.toMap());
  }

  /// Удалить привычку
  Future<void> deleteHabit(String uid, String habitId) async {
    await _habitsCollection(uid).doc(habitId).delete();
  }

  /// Архивировать привычку
  Future<void> archiveHabit(String uid, String habitId) async {
    await _habitsCollection(uid).doc(habitId).update({'isArchived': true});
  }

  // ========== ДОСТИЖЕНИЯ ==========

  /// Получить все достижения пользователя
  Stream<List<Achievement>> getAchievementsStream(String uid) {
    return _achievementsCollection(uid).snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) =>
                Achievement.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Сохранить достижение
  Future<void> saveAchievement(String uid, Achievement achievement) async {
    await _achievementsCollection(uid)
        .doc(achievement.id)
        .set(achievement.toMap(), SetOptions(merge: true));
  }

  /// Получить все достижения (однократно)
  Future<List<Achievement>> getAchievements(String uid) async {
    final snapshot = await _achievementsCollection(uid).get();
    return snapshot.docs
        .map((doc) => Achievement.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // ========== СИНХРОНИЗАЦИЯ ==========

  /// Пакетное обновление привычек (для офлайн-синхронизации)
  Future<void> batchUpdateHabits(
    String uid,
    List<Habit> habits,
  ) async {
    final batch = _db.batch();
    for (final habit in habits) {
      final docRef = _habitsCollection(uid).doc(habit.id);
      batch.set(docRef, habit.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}
