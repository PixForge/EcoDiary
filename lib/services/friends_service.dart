import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_request.dart';
import '../models/friend.dart';
import '../models/user_profile.dart';

/// Сервис управления друзьями
class FriendsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Коллекция пользователей
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  /// Коллекция заявок в друзья
  CollectionReference<Map<String, dynamic>> get _friendRequests =>
      _db.collection('friend_requests');

  /// Коллекция друзей (для каждого пользователя отдельная подколлекция)
  CollectionReference<Map<String, dynamic>> _friendsCollection(String uid) {
    return _users.doc(uid).collection('friends');
  }

  // ========== ПОИСК ПОЛЬЗОВАТЕЛЕЙ ==========

  /// Поиск пользователей по email или displayName
  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase().trim();

    // Поиск по email (точное совпадение)
    final emailQuery = await _users
        .where('email', isEqualTo: lowerQuery)
        .limit(10)
        .get();

    // Поиск по displayName (через startAt/endAt для partial match)
    final displayNameQuery = await _users
        .orderBy('displayName')
        .startAt([lowerQuery])
        .endAt([lowerQuery + '\uf8ff'])
        .limit(10)
        .get();

    final results = <UserProfile>{};

    for (final doc in emailQuery.docs) {
      final data = doc.data();
      if (data['uid'] != null) {
        results.add(UserProfile.fromMap({
          ...data,
          'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
        }));
      }
    }

    for (final doc in displayNameQuery.docs) {
      final data = doc.data();
      if (data['uid'] != null) {
        results.add(UserProfile.fromMap({
          ...data,
          'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
        }));
      }
    }

    return results.toList();
  }

  /// Получить профиль пользователя по UID
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).collection('profile').doc('data').get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  // ========== ЗАЯВКИ В ДРУЗЬЯ ==========

  /// Отправить заявку в друзья
  Future<void> sendFriendRequest({
    required String senderId,
    required String senderEmail,
    required String senderDisplayName,
    required String receiverId,
  }) async {
    // Проверка: уже есть ли заявка
    final existingRequest = await _friendRequests
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception('Заявка уже отправлена');
    }

    // Проверка: уже друзья ли
    final alreadyFriends = await _friendsCollection(senderId).doc(receiverId).get();
    if (alreadyFriends.exists) {
      throw Exception('Вы уже друзья');
    }

    final request = FriendRequest(
      id: _friendRequests.doc().id,
      senderId: senderId,
      senderEmail: senderEmail,
      senderDisplayName: senderDisplayName,
      receiverId: receiverId,
      createdAt: DateTime.now(),
      status: FriendRequestStatus.pending,
    );

    await _friendRequests.doc(request.id).set(request.toMap());
  }

  /// Получить входящие заявки
  Stream<List<FriendRequest>> getIncomingRequestsStream(String userId) {
    return _friendRequests
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromMap(doc.data()))
            .toList());
  }

  /// Получить исходящие заявки
  Stream<List<FriendRequest>> getOutgoingRequestsStream(String userId) {
    return _friendRequests
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromMap(doc.data()))
            .toList());
  }

  /// Принять заявку в друзья
  Future<void> acceptFriendRequest(String requestId, String senderId, String receiverId) async {
    final batch = _db.batch();

    // Обновить статус заявки
    batch.update(_friendRequests.doc(requestId), {'status': 'accepted'});

    // Добавить друга обоим пользователям
    final now = DateTime.now().toIso8601String();

    // Получить данные отправителя
    final senderProfile = await getUserProfile(senderId);
    final receiverProfile = await getUserProfile(receiverId);

    if (senderProfile != null && receiverProfile != null) {
      // Добавить отправителя в друзья получателю
      batch.set(_friendsCollection(receiverId).doc(senderId), {
        'uid': senderId,
        'email': senderProfile.email,
        'displayName': senderProfile.displayName,
        'avatarBase64': senderProfile.avatarBase64,
        'friendsSince': now,
        'stats': {
          'currentStreak': 0,
          'todayProgress': 0,
          'weeklyProgress': 0,
          'monthlyProgress': 0,
          'recentAchievements': 0,
          'lastActiveAt': now,
        },
      });

      // Добавить получателя в друзья отправителю
      batch.set(_friendsCollection(senderId).doc(receiverId), {
        'uid': receiverId,
        'email': receiverProfile.email,
        'displayName': receiverProfile.displayName,
        'avatarBase64': receiverProfile.avatarBase64,
        'friendsSince': now,
        'stats': {
          'currentStreak': 0,
          'todayProgress': 0,
          'weeklyProgress': 0,
          'monthlyProgress': 0,
          'recentAchievements': 0,
          'lastActiveAt': now,
        },
      });
    }

    await batch.commit();
  }

  /// Отклонить заявку в друзья
  Future<void> declineFriendRequest(String requestId) async {
    await _friendRequests.doc(requestId).update({'status': 'declined'});
  }

  /// Удалить друга
  Future<void> removeFriend(String userId, String friendId) async {
    final batch = _db.batch();

    // Удалить из обоих списков друзей
    batch.delete(_friendsCollection(userId).doc(friendId));
    batch.delete(_friendsCollection(friendId).doc(userId));

    await batch.commit();
  }

  // ========== СПИСОК ДРУЗЕЙ ==========

  /// Получить список друзей пользователя
  Stream<List<Friend>> getFriendsStream(String userId) {
    return _friendsCollection(userId).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Friend.fromMap(doc.data()))
        .toList());
  }

  /// Получить количество друзей
  Future<int> getFriendsCount(String userId) async {
    final snapshot = await _friendsCollection(userId).count().get();
    return snapshot.count ?? 0;
  }

  /// Проверить, являются ли пользователи друзьями
  Future<bool> areFriends(String userId1, String userId2) async {
    final doc = await _friendsCollection(userId1).doc(userId2).get();
    return doc.exists;
  }

  // ========== СТАТИСТИКА ДРУЗЕЙ ==========

  /// Обновить статистику друга (вызывается при изменении прогресса)
  Future<void> updateFriendStats({
    required String userId,
    required String friendId,
    required FriendStats stats,
  }) async {
    await _friendsCollection(userId).doc(friendId).update({
      'stats': stats.toMap(),
    });
  }

  /// Получить статистику всех друзей для ленты
  Future<List<Friend>> getFriendsWithStats(String userId) async {
    final snapshot = await _friendsCollection(userId).get();
    return snapshot.docs
        .map((doc) => Friend.fromMap(doc.data()))
        .toList();
  }

  // ========== СИНХРОНИЗАЦИЯ ПРОФИЛЯ ==========

  /// Обновить данные профиля у всех друзей пользователя
  Future<void> syncProfileWithFriends({
    required String userId,
    required String displayName,
    required String avatarBase64,
  }) async {
    try {
      // Получить всех друзей текущего пользователя
      // У каждого друга в коллекции friends хранится запись о текущем пользователе
      final friendsSnapshot = await _users
          .doc(userId)
          .collection('friends')
          .get();

      if (friendsSnapshot.docs.isEmpty) {
        print('[FriendsService] У пользователя нет друзей, синхронизация не требуется');
        return;
      }

      final batch = _db.batch();
      var operationsCount = 0;

      // Для каждого друга обновить данные о текущем пользователе
      for (final friendDoc in friendsSnapshot.docs) {
        final friendId = friendDoc.id;
        
        // Обновляем запись о текущем пользователе в коллекции друга
        batch.update(_friendsCollection(friendId).doc(userId), {
          'displayName': displayName,
          'avatarBase64': avatarBase64,
        });
        operationsCount++;
      }

      if (operationsCount > 0) {
        await batch.commit();
        print('[FriendsService] Синхронизирован профиль у $operationsCount друзей');
      }
    } catch (e) {
      print('[FriendsService] Ошибка синхронизации профиля: $e');
      // Не выбрасываем ошибку, чтобы не прерывать основной поток сохранения
    }
  }
}
