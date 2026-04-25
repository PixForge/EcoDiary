import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/achievement.dart';
import '../data/achievement_catalog.dart';

/// Сервис для шеринга достижений
class SharingService {
  /// Поделиться достижением в соцсетях
  Future<void> shareAchievement({
    required Achievement achievement,
    required String languageCode,
    BuildContext? context,
  }) async {
    final title = AchievementCatalog.localizedTitle(achievement, languageCode);
    final description = AchievementCatalog.localizedDescription(achievement, languageCode);

    final text = '''
🏆 Я разблокировал достижение в Дневнике экологических привычек!

$title

$description

#ЭкоПривычки #ЗелёныйОбразЖизни
''';

    await Share.share(
      text,
      subject: 'Моё эко-достижение: $title',
    );
  }

  /// Поделиться достижением с красивой картинкой
  Future<void> shareAchievementWithImage({
    required Achievement achievement,
    required String languageCode,
    required GlobalKey imageKey,
    BuildContext? context,
  }) async {
    try {
      // Найти RenderRepaintBoundary
      final boundary = imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        // Если не удалось получить картинку,-share текстом
        await shareAchievement(
          achievement: achievement,
          languageCode: languageCode,
          context: context,
        );
        return;
      }

      // Создать изображение
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) {
        await shareAchievement(
          achievement: achievement,
          languageCode: languageCode,
          context: context,
        );
        return;
      }

      // Сохранить во временный файл
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/achievement_${achievement.id}.png').create();
      await file.writeAsBytes(pngBytes);

      // Поделиться файлом
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '''
🏆 Я разблокировал достижение в Дневнике экологических привычек!

${AchievementCatalog.localizedTitle(achievement, languageCode)}

#ЭкоПривычки #ЗелёныйОбразЖизни
''',
        subject: 'Моё эко-достижение',
      );
    } catch (e) {
      // При ошибке поделиться текстом
      await shareAchievement(
        achievement: achievement,
        languageCode: languageCode,
        context: context,
      );
    }
  }

  /// Поделиться прогрессом с другом
  Future<void> shareProgress({
    required int streak,
    required int todayProgress,
    required String languageCode,
  }) async {
    final isEn = languageCode == 'en';
    final text = isEn
        ? '''
🌱 My eco-habit progress today!

🔥 Streak: $streak days
📊 Today's progress: $todayProgress%

Join me in building sustainable habits!
#EcoHabits #SustainableLiving
'''
        : '''
🌱 Мой прогресс эко-привычек сегодня!

🔥 Серия: $streak дней
📊 Прогресс сегодня: $todayProgress%

Присоединяйтесь к формированию устойчивых привычек!
#ЭкоПривычки #ЗелёныйОбразЖизни
''';

    await Share.share(
      text,
      subject: isEn ? 'My Eco Progress' : 'Мой эко-прогресс',
    );
  }

  /// Поделиться приглашением в челлендж
  Future<void> shareChallengeInvite({
    required String challengeName,
    required int durationDays,
  }) async {
    final text = '''
🌟 Присоединяйся к моему эко-челленджу!

"$challengeName"

📅 Длительность: $durationDays дней
🎯 Цель: вместе формировать полезные привычки для планеты

Присоединяйся в приложении Дневник экологических привычек!
#ЭкоЧеллендж #ЗелёныеПривычки
''';

    await Share.share(
      text,
      subject: 'Приглашение в эко-челлендж',
    );
  }
}
