import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/social_provider.dart';
import '../../services/challenges_service.dart';
import '../../helpers/localization.dart';

/// Экран таблицы лидеров среди друзей
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  LeaderboardPeriod _selectedPeriod = LeaderboardPeriod.weekly;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SocialProvider>().loadLeaderboard(_selectedPeriod);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('leaderboard')),
      ),
      body: Column(
        children: [
          // Переключатель периода
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _periodButton(
                    'Неделя',
                    LeaderboardPeriod.weekly,
                    theme,
                  ),
                ),
                Expanded(
                  child: _periodButton(
                    'Месяц',
                    LeaderboardPeriod.monthly,
                    theme,
                  ),
                ),
              ],
            ),
          ),

          // Таблица лидеров
          Expanded(
            child: Consumer<SocialProvider>(
              builder: (context, socialProvider, child) {
                if (socialProvider.isLoadingLeaderboard) {
                  return const Center(child: CircularProgressIndicator());
                }

                final entries = socialProvider.getLeaderboard(_selectedPeriod);

                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text(
                          'Нет данных',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Добавьте друзей, чтобы видеть рейтинг',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final rank = index + 1;
                    final isTopThree = rank <= 3;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Место
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isTopThree
                                    ? _getMedalColor(rank)
                                    : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  isTopThree ? _getMedalIcon(rank) : '$rank',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isTopThree ? Colors.white : Colors.black54,
                                    fontSize: isTopThree ? 18 : 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Аватар
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                              child: entry.avatarBase64.isNotEmpty
                                  ? ClipOval(
                                      child: Image.memory(
                                        _decodeBase64(entry.avatarBase64),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Text(
                                      entry.displayName.isNotEmpty
                                          ? entry.displayName[0].toUpperCase()
                                          : '👤',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        title: Text(
                          entry.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(Icons.whatshot, size: 16, color: Colors.orange[700]),
                            const SizedBox(width: 4),
                            Text('${entry.streak} дней серия'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${entry.progress}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodButton(String label, LeaderboardPeriod period, ThemeData theme) {
    final isSelected = _selectedPeriod == period;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
        context.read<SocialProvider>().loadLeaderboard(period);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Color _getMedalColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Colors.grey[200]!;
    }
  }

  String _getMedalIcon(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  Uint8List _decodeBase64(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return Uint8List(0);
    }
  }
}
