import 'package:flutter/material.dart';
import '../models/friend_request.dart';

/// Виджет карточки заявки в друзья
class FriendRequestTile extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const FriendRequestTile({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Аватар
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.2),
              child: Text(
                request.senderDisplayName.isNotEmpty
                    ? request.senderDisplayName[0].toUpperCase()
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
                    request.senderDisplayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    request.senderEmail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Отправлена: ${_formatDate(request.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Кнопки действий
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Принять
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: onAccept,
                  color: Colors.green[700],
                  tooltip: 'Принять',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green[50],
                  ),
                ),

                // Отклонить
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDecline,
                  color: Colors.red[400],
                  tooltip: 'Отклонить',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red[50],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} мин. назад';
      }
      return '${diff.inHours} ч. назад';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
