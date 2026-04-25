import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/sharing_service.dart';
import '../../models/achievement.dart';
import '../../data/achievement_catalog.dart';
import '../../helpers/localization.dart';

/// Кнопка для шеринга достижения
class AchievementShareButton extends StatelessWidget {
  final Achievement achievement;
  final String languageCode;

  const AchievementShareButton({
    super.key,
    required this.achievement,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final sharingService = context.read<SharingService>();

    return IconButton(
      icon: const Icon(Icons.share),
      onPressed: () async {
        await sharingService.shareAchievement(
          achievement: achievement,
          languageCode: languageCode,
          context: context,
        );
      },
      tooltip: context.tr('share'),
      color: const Color(0xFF2E7D32),
    );
  }
}

/// Диалог разблокировки достижения с кнопкой шеринга
class AchievementUnlockDialog extends StatefulWidget {
  final Achievement achievement;
  final String languageCode;

  const AchievementUnlockDialog({
    super.key,
    required this.achievement,
    required this.languageCode,
  });

  @override
  State<AchievementUnlockDialog> createState() => _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<AchievementUnlockDialog> {
  final GlobalKey _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final sharingService = context.read<SharingService>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Карточка достижения для шеринга
            RepaintBoundary(
              key: _imageKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2E7D32),
                      const Color(0xFF66BB6A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.achievement.icon,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AchievementCatalog.localizedTitle(widget.achievement, widget.languageCode),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.achievement.tier.localizedDisplayName(widget.languageCode),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              AppLocalizations.of(context).translate('new_achievement'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AchievementCatalog.localizedTitle(widget.achievement, widget.languageCode),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AchievementCatalog.localizedDescription(widget.achievement, widget.languageCode),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Поделиться
                OutlinedButton.icon(
                  onPressed: () async {
                    await sharingService.shareAchievement(
                      achievement: widget.achievement,
                      languageCode: widget.languageCode,
                      context: context,
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Поделиться'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                  ),
                ),

                // ОК
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(AppLocalizations.of(context).translate('great')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
