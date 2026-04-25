import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_request.dart';
import '../models/friend.dart';
import '../models/challenge.dart';
import '../models/user_profile.dart';
import '../services/friends_service.dart';
import '../services/challenges_service.dart';

/// Провайдер для управления социальными функциями
class SocialProvider extends ChangeNotifier {
  final FriendsService _friendsService = FriendsService();
  final ChallengesService _challengesService = ChallengesService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Друзья
  List<Friend> _friends = [];
  List<FriendRequest> _incomingRequests = [];
  List<FriendRequest> _outgoingRequests = [];
  bool _isLoadingFriends = false;

  // Челленджи
  List<Challenge> _activeChallenges = [];
  List<Challenge> _createdChallenges = [];
  final Map<String, List<ChallengeParticipantProgress>> _challengeProgress = {};
  bool _isLoadingChallenges = false;

  // Таблица лидеров
  final Map<String, List<FriendLeaderboardEntry>> _leaderboards = {};
  bool _isLoadingLeaderboard = false;

  // Геттеры
  List<Friend> get friends => _friends;
  List<FriendRequest> get incomingRequests => _incomingRequests;
  List<FriendRequest> get outgoingRequests => _outgoingRequests;
  bool get isLoadingFriends => _isLoadingFriends;

  List<Challenge> get activeChallenges => _activeChallenges;
  List<Challenge> get createdChallenges => _createdChallenges;
  Map<String, List<ChallengeParticipantProgress>> get challengeProgress => _challengeProgress;
  bool get isLoadingChallenges => _isLoadingChallenges;

  Map<String, List<FriendLeaderboardEntry>> get leaderboards => _leaderboards;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;

  String? get _currentUserId => _auth.currentUser?.uid;
  String get _currentUserDisplayName => _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'User';

  // ========== ИНИЦИАЛИЗАЦИЯ ==========

  /// Подписаться на обновления друзей
  void subscribeToFriends() {
    final userId = _currentUserId;
    if (userId == null) return;

    _isLoadingFriends = true;
    notifyListeners();

    // Подписка на список друзей
    _friendsService.getFriendsStream(userId).listen((friends) {
      _friends = friends;
      _isLoadingFriends = false;
      notifyListeners();
    });

    // Подписка на входящие заявки
    _friendsService.getIncomingRequestsStream(userId).listen((requests) {
      _incomingRequests = requests;
      notifyListeners();
    });

    // Подписка на исходящие заявки
    _friendsService.getOutgoingRequestsStream(userId).listen((requests) {
      _outgoingRequests = requests;
      notifyListeners();
    });
  }

  /// Подписаться на обновления челленджей
  void subscribeToChallenges() {
    final userId = _currentUserId;
    if (userId == null) return;

    _isLoadingChallenges = true;
    notifyListeners();

    // Активные челленджи пользователя
    _challengesService.getUserChallengesStream(userId).listen((challenges) {
      _activeChallenges = challenges;
      _isLoadingChallenges = false;
      notifyListeners();

      // Подписаться на прогресс для каждого челленджа
      for (final challenge in challenges) {
        _subscribeToChallengeProgress(challenge.id);
      }
    });

    // Челленджи, созданные пользователем
    _challengesService.getCreatedChallengesStream(userId).listen((challenges) {
      _createdChallenges = challenges;
      notifyListeners();
    });
  }

  /// Подписаться на прогресс конкретного челленджа
  void _subscribeToChallengeProgress(String challengeId) {
    _challengesService.getChallengeProgressStream(challengeId).listen((progress) {
      _challengeProgress[challengeId] = progress;
      notifyListeners();
    });
  }

  // ========== ДРУЗЬЯ ==========

  /// Поиск пользователей
  Future<List<FriendSearchResult>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final profiles = await _friendsService.searchUsers(query);
    final currentUserId = _currentUserId;

    final results = <FriendSearchResult>[];
    for (final profile in profiles) {
      if (profile.uid == currentUserId) continue; // Не показывать себя

      final areFriends = await _friendsService.areFriends(currentUserId!, profile.uid);
      final hasPendingRequest = _outgoingRequests.any((r) => r.receiverId == profile.uid);

      results.add(FriendSearchResult(
        profile: profile,
        isAlreadyFriend: areFriends,
        hasPendingRequest: hasPendingRequest,
      ));
    }

    return results;
  }

  /// Отправить заявку в друзья
  Future<void> sendFriendRequest(String receiverId, String receiverEmail, String receiverDisplayName) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    await _friendsService.sendFriendRequest(
      senderId: userId,
      senderEmail: _auth.currentUser?.email ?? '',
      senderDisplayName: _currentUserDisplayName,
      receiverId: receiverId,
    );
  }

  /// Принять заявку в друзья
  Future<void> acceptFriendRequest(String requestId, String senderId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    await _friendsService.acceptFriendRequest(requestId, senderId, userId);
  }

  /// Отклонить заявку в друзья
  Future<void> declineFriendRequest(String requestId) async {
    await _friendsService.declineFriendRequest(requestId);
  }

  /// Удалить друга
  Future<void> removeFriend(String friendId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    await _friendsService.removeFriend(userId, friendId);
  }

  // ========== ЧЕЛЛЕНДЖИ ==========

  /// Создать челлендж
  Future<Challenge> createChallenge({
    required String name,
    required String description,
    required int durationDays,
    required DateTime startDate,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    return await _challengesService.createChallenge(
      name: name,
      description: description,
      creatorId: userId,
      creatorName: _currentUserDisplayName,
      durationDays: durationDays,
      startDate: startDate,
    );
  }

  /// Пригласить друга в челлендж
  Future<void> inviteToChallenge({
    required String challengeId,
    required String friendId,
    required String friendName,
  }) async {
    await _challengesService.inviteParticipant(
      challengeId: challengeId,
      participantId: friendId,
      participantName: friendName,
    );
  }

  /// Отметить день в челлендже как выполненный
  Future<void> markChallengeDayCompleted({
    required String challengeId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    await _challengesService.markDayCompleted(
      challengeId: challengeId,
      participantId: userId,
    );
  }

  /// Завершить челлендж
  Future<void> completeChallenge(String challengeId) async {
    await _challengesService.completeChallenge(challengeId);
  }

  // ========== ТАБЛИЦА ЛИДЕРОВ ==========

  /// Загрузить таблицу лидеров
  Future<void> loadLeaderboard(LeaderboardPeriod period) async {
    final userId = _currentUserId;
    if (userId == null) return;

    _isLoadingLeaderboard = true;
    notifyListeners();

    try {
      final entries = await _challengesService.getFriendsLeaderboard(
        userId: userId,
        period: period,
      );
      _leaderboards[period.name] = entries;
    } catch (e) {
      debugPrint('Ошибка загрузки таблицы лидеров: $e');
    }

    _isLoadingLeaderboard = false;
    notifyListeners();
  }

  /// Получить таблицу лидеров для периода
  List<FriendLeaderboardEntry> getLeaderboard(LeaderboardPeriod period) {
    return _leaderboards[period.name] ?? [];
  }

  // ========== ОЧИСТКА ==========

  @override
  void dispose() {
    // Подписки закроются автоматически при уничтожении стримов
    super.dispose();
  }
}

/// Результат поиска друга
class FriendSearchResult {
  final UserProfile profile;
  final bool isAlreadyFriend;
  final bool hasPendingRequest;

  FriendSearchResult({
    required this.profile,
    required this.isAlreadyFriend,
    required this.hasPendingRequest,
  });
}

