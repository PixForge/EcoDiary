import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/social_provider.dart';
import '../../widgets/challenge_card.dart';
import 'create_challenge_screen.dart';

/// Экран командных челленджей
class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        if (socialProvider.isLoadingChallenges) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeChallenges = socialProvider.activeChallenges;

        if (activeChallenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎯', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'Нет активных челленджей',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Создайте свой челлендж и пригласите друзей',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateChallengeScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Создать челлендж'),
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
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Активные челленджи',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateChallengeScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      tooltip: 'Создать челлендж',
                    ),
                  ],
                ),
              ),
              ...activeChallenges.map((challenge) {
                final progressList = socialProvider.challengeProgress[challenge.id] ?? [];
                final myProgress = progressList.where((p) => 
                  // В реальном проекте сравнивать с UID текущего пользователя
                  true // Заглушка
                ).firstOrNull;

                return ChallengeCard(
                  challenge: challenge,
                  myProgress: myProgress,
                  onInvite: () => _showInviteDialog(context, challenge),
                  onComplete: () => _markDayCompleted(context, challenge.id),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showInviteDialog(BuildContext context, challenge) {
    // TODO: Реализовать диалог приглашения друзей
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция приглашения в разработке')),
    );
  }

  Future<void> _markDayCompleted(BuildContext context, String challengeId) async {
    try {
      final socialProvider = context.read<SocialProvider>();
      await socialProvider.markChallengeDayCompleted(challengeId: challengeId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('День отмечен! Так держать! 🎉')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}
