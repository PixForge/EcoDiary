import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/friend.dart';

/// Виджет карточки друга для списка
class FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showStats;

  const FriendTile({
    super.key,
    required this.friend,
    this.onTap,
    this.onRemove,
    this.showStats = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Аватар
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                child: friend.avatarBase64.isNotEmpty
                    ? ClipOval(
                        child: Image.memory(
                          Base64Decoder().convert(friend.avatarBase64),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        friend.displayName.isNotEmpty
                            ? friend.displayName[0].toUpperCase()
                            : '👤',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      friend.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showStats) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statChip('🔥', '${friend.stats.currentStreak}', 'дней'),
                          const SizedBox(width: 8),
                          _statChip('📊', '${friend.stats.todayProgress}%', 'сегодня'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Кнопка удаления
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.person_remove_outlined),
                  onPressed: onRemove,
                  color: Colors.red[400],
                  tooltip: 'Удалить из друзей',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}

