import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/social_provider.dart';
import '../../models/friend.dart';

/// Экран ленты друзей - просмотр прогресса друзей
class FriendsFeedScreen extends StatelessWidget {
  const FriendsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                const Text('📰', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'Лента пуста',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавьте друзей, чтобы видеть их прогресс',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Сортируем друзей по активности
        final activeFriends = friends.where((f) => 
          f.stats.todayProgress > 0 || 
          f.stats.currentStreak > 0 ||
          f.stats.recentAchievements > 0
        ).toList();

        final otherFriends = friends.where((f) => 
          f.stats.todayProgress == 0 && 
          f.stats.currentStreak == 0 &&
          f.stats.recentAchievements == 0
        ).toList();

        return RefreshIndicator(
          onRefresh: () async {
            // Обновление произойдёт автоматически через стрим
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Заголовок
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Прогресс друзей',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Активные друзья
              if (activeFriends.isNotEmpty) ...[
                ...activeFriends.map((friend) => _FriendFeedCard(
                  friend: friend,
                  theme: theme,
                )),
                const SizedBox(height: 16),
              ],

              // Остальные друзья
              if (otherFriends.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Другие друзья',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ...otherFriends.map((friend) => _FriendFeedCard(
                  friend: friend,
                  theme: theme,
                  showMinimal: true,
                )),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FriendFeedCard extends StatelessWidget {
  final Friend friend;
  final ThemeData theme;
  final bool showMinimal;

  const _FriendFeedCard({
    required this.friend,
    required this.theme,
    this.showMinimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с аватаром
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                  child: friend.avatarBase64.isNotEmpty
                      ? ClipOval(
                          child: Image.memory(
                            _decodeBase64(friend.avatarBase64),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          friend.displayName.isNotEmpty
                              ? friend.displayName[0].toUpperCase()
                              : '👤',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getLastActiveText(friend.stats.lastActiveAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (!showMinimal) ...[
              // Прогресс сегодня
              _buildProgressSection(
                context,
                '📊 Сегодня',
                friend.stats.todayProgress,
                Colors.green,
              ),

              const SizedBox(height: 12),

              // Серия
              _buildProgressSection(
                context,
                '🔥 Текущая серия',
                friend.stats.currentStreak > 0 
                    ? (friend.stats.currentStreak * 10).clamp(0, 100) 
                    : 0,
                Colors.orange,
                valueText: '${friend.stats.currentStreak} дн.',
              ),

              const SizedBox(height: 12),

              // Достижения
              if (friend.stats.recentAchievements > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Новые достижения',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[900],
                              ),
                            ),
                            Text(
                              '${friend.stats.recentAchievements} разблокировано',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Прогресс за неделю
              _buildProgressSection(
                context,
                '📈 За неделю',
                friend.stats.weeklyProgress,
                Colors.blue,
              ),
            ] else ...[
              // Минимальный вид
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat('🔥', '${friend.stats.currentStreak}', 'дней'),
                  _miniStat('📊', '${friend.stats.todayProgress}%', 'сегодня'),
                  _miniStat('📈', '${friend.stats.weeklyProgress}%', 'неделя'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    String label,
    int progress,
    MaterialColor color, {
    String? valueText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              valueText ?? '$progress%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _miniStat(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getLastActiveText(DateTime? lastActiveAt) {
    if (lastActiveAt == null) return 'Был(а) давно';
    
    final diff = DateTime.now().difference(lastActiveAt);
    
    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
    if (diff.inHours < 24) return '${diff.inHours} ч. назад';
    if (diff.inDays < 7) return '${diff.inDays} дн. назад';
    
    return '${lastActiveAt.day}.${lastActiveAt.month}.${lastActiveAt.year}';
  }

  Uint8List _decodeBase64(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return Uint8List(0);
    }
  }
}
