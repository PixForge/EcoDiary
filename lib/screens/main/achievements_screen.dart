import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/achievement.dart';
import '../../data/achievement_catalog.dart';
import '../../helpers/localization.dart';
import '../../widgets/achievement_share_button.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkAchievements() async {
    final habitProvider = context.read<HabitProvider>();
    final statsProvider = context.read<StatsProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) return;

    final unlocked = await statsProvider.checkAndUnlockAchievements(
      habitProvider.habits,
      user.uid,
    );

      if (unlocked.isNotEmpty && mounted) {
        // Показать первое новое достижение
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AchievementUnlockDialog(
              achievement: unlocked.first,
              languageCode: Localizations.localeOf(context).languageCode,
            ),
          );
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsProvider = context.watch<StatsProvider>();
    final lang = Localizations.localeOf(context).languageCode;
    final achievements = statsProvider.unlockedAchievements;

    // Группировать по уровням
    final grouped = <AchievementTier, List<Achievement>>{};
    for (final achievement in AchievementCatalog.allAchievements) {
      final isUnlocked = achievements.any((a) => a.id == achievement.id);
      final a = achievement.copyWith(isUnlocked: isUnlocked);
      grouped.putIfAbsent(achievement.tier, () => []);
      grouped[achievement.tier]!.add(a);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('achievements')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAchievements,
            tooltip: context.tr('achievements_check'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Прогресс
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    context.tr('your_progress'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _progressItem(
                        '🏆',
                        context.tr('unlocked'),
                        '${achievements.length}',
                      ),
                      _progressItem(
                        '📋',
                        context.tr('total'),
                        '${AchievementCatalog.allAchievements.length}',
                      ),
                      _progressItem(
                        '📊',
                        context.tr('percent'),
                        '${(AchievementCatalog.allAchievements.isEmpty ? 0 : (achievements.length / AchievementCatalog.allAchievements.length) * 100).toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: AchievementCatalog.allAchievements.isEmpty
                        ? 0
                        : achievements.length /
                            AchievementCatalog.allAchievements.length,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Достижения по уровням
          for (final tier in AchievementTier.values) ...[
            if (grouped.containsKey(tier)) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _tierColor(tier).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tier.localizedDisplayName(lang),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _tierColor(tier),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: grouped[tier]!.length,
                itemBuilder: (context, index) {
                  final achievement = grouped[tier]![index];
                  return _achievementCard(achievement, lang);
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _achievementCard(Achievement achievement, String lang) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 32,
                color: achievement.isUnlocked ? null : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AchievementCatalog.localizedTitle(achievement, lang),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: achievement.isUnlocked ? null : Colors.grey[500],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (achievement.isUnlocked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green[700],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _progressItem(String icon, String label, String value) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _tierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return Colors.brown;
      case AchievementTier.silver:
        return Colors.grey;
      case AchievementTier.gold:
        return Colors.amber;
      case AchievementTier.platinum:
        return Colors.blue;
      case AchievementTier.diamond:
        return Colors.cyan;
    }
  }
}

