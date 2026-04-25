import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/social_provider.dart';
import '../../widgets/friend_tile.dart';
import '../../widgets/friend_request_tile.dart';
import 'friends_feed_screen.dart';
import 'leaderboard_screen.dart';
import 'challenges_screen.dart';
import '../../helpers/localization.dart';

/// Экран управления друзьями
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<FriendSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Подписаться на обновления
    Future.microtask(() {
      final socialProvider = context.read<SocialProvider>();
      socialProvider.subscribeToFriends();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final socialProvider = context.read<SocialProvider>();
      final results = await socialProvider.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка поиска: $e')),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(FriendSearchResult result) async {
    try {
      final socialProvider = context.read<SocialProvider>();
      await socialProvider.sendFriendRequest(
        result.profile.uid,
        result.profile.email,
        result.profile.displayName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заявка отправлена')),
        );
        setState(() {
          _searchResults = [];
          _searchController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _acceptRequest(String requestId, String senderId) async {
    try {
      final socialProvider = context.read<SocialProvider>();
      await socialProvider.acceptFriendRequest(requestId, senderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Друг добавлен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      final socialProvider = context.read<SocialProvider>();
      await socialProvider.declineFriendRequest(requestId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _removeFriend(String friendId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить друга?'),
        content: const Text('Вы уверены, что хотите удалить этого друга?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final socialProvider = context.read<SocialProvider>();
        await socialProvider.removeFriend(friendId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Друг удалён')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('friends')),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaderboardScreen(),
                ),
              );
            },
            tooltip: 'Таблица лидеров',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Друзья'),
            Tab(icon: Icon(Icons.mail_outline), text: 'Заявки'),
            Tab(icon: Icon(Icons.show_chart), text: 'Лента'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Челленджи'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(theme),
          _buildRequestsTab(theme),
          const FriendsFeedScreen(),
          const ChallengesScreen(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddFriendDialog(theme),
              icon: const Icon(Icons.person_add),
              label: const Text('Добавить'),
              backgroundColor: const Color(0xFF2E7D32),
            )
          : null,
    );
  }

  Widget _buildFriendsTab(ThemeData theme) {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        if (socialProvider.isLoadingFriends) {
          return const Center(child: CircularProgressIndicator());
        }

        final friends = socialProvider.friends;

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🌱', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'У вас пока нет друзей',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавьте друзей, чтобы видеть их прогресс\nи участвовать в челленджах',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showAddFriendDialog(theme),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Найти друзей'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Обновление произойдёт автоматически через стрим
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return FriendTile(
                friend: friend,
                onRemove: () => _removeFriend(friend.uid),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab(ThemeData theme) {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        final incomingRequests = socialProvider.incomingRequests;
        final outgoingRequests = socialProvider.outgoingRequests;

        if (incomingRequests.isEmpty && outgoingRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📭', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'Нет заявок',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Заявки в друзья появятся здесь',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (incomingRequests.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Входящие (${incomingRequests.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              ...incomingRequests.map((request) => FriendRequestTile(
                request: request,
                onAccept: () => _acceptRequest(request.id, request.senderId),
                onDecline: () => _declineRequest(request.id),
              )),
            ],
            if (outgoingRequests.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  'Исходящие (${outgoingRequests.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              ...outgoingRequests.map((request) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                    child: Text(
                      request.receiverId[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  title: Text(request.receiverId),
                  subtitle: const Text('Ожидает подтверждения'),
                  trailing: const Icon(Icons.access_time, color: Colors.orange),
                ),
              )),
            ],
          ],
        );
      },
    );
  }

  void _showAddFriendDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить друга'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Email или имя',
                hintText: 'Введите email или никнейм',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const CircularProgressIndicator()
            else if (_searchResults.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          result.profile.displayName.isNotEmpty
                              ? result.profile.displayName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(result.profile.displayName),
                      subtitle: Text(result.profile.email),
                      trailing: result.isAlreadyFriend
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : result.hasPendingRequest
                              ? const Icon(Icons.access_time, color: Colors.orange)
                              : ElevatedButton(
                                  onPressed: () => _sendFriendRequest(result),
                                  child: const Text('Добавить'),
                                ),
                    );
                  },
                ),
              )
            else
              Text(
                _searchController.text.isEmpty
                    ? 'Введите email или имя для поиска'
                    : 'Ничего не найдено',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
