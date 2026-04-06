import '../models/achievement.dart';

/// Каталог всех достижений
class AchievementCatalog {
  static const List<Achievement> allAchievements = [
    // === СЕРИИ (Streak) ===
    Achievement(
      id: 'streak_7',
      title: 'Неделя силы воли',
      description: '7 дней подряд выполнения привычек',
      icon: '🔥',
      tier: AchievementTier.bronze,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Месяц дисциплины',
      description: '30 дней подряд выполнения привычек',
      icon: '🔥',
      tier: AchievementTier.silver,
    ),
    Achievement(
      id: 'streak_60',
      title: 'Двойной марафон',
      description: '60 дней подряд выполнения привычек',
      icon: '🔥',
      tier: AchievementTier.gold,
    ),
    Achievement(
      id: 'streak_100',
      title: 'Эко-легенда',
      description: '100 дней подряд выполнения привычек',
      icon: '👑',
      tier: AchievementTier.platinum,
    ),
    Achievement(
      id: 'streak_365',
      title: 'Год зелёных привычек',
      description: '365 дней подряд — целый год!',
      icon: '💎',
      tier: AchievementTier.diamond,
    ),

    // === КОЛИЧЕСТВО ВЫПОЛНЕНИЙ ===
    Achievement(
      id: 'total_50',
      title: 'Начинающий эколог',
      description: '50 выполненных привычек',
      icon: '🌱',
      tier: AchievementTier.bronze,
    ),
    Achievement(
      id: 'total_100',
      title: 'Активный защитник',
      description: '100 выполненных привычек',
      icon: '🌿',
      tier: AchievementTier.silver,
    ),
    Achievement(
      id: 'total_250',
      title: 'Опытный эколог',
      description: '250 выполненных привычек',
      icon: '🌳',
      tier: AchievementTier.gold,
    ),
    Achievement(
      id: 'total_500',
      title: 'Мастер экологии',
      description: '500 выполненных привычек',
      icon: '🏆',
      tier: AchievementTier.platinum,
    ),
    Achievement(
      id: 'total_1000',
      title: 'Грандмастер планеты',
      description: '1000 выполненных привычек',
      icon: '🌍',
      tier: AchievementTier.diamond,
    ),

    // === ВСЕ КАТЕГОРИИ ===
    Achievement(
      id: 'all_categories',
      title: 'Универсальный эколог',
      description: 'Выполнены привычки из всех категорий',
      icon: '🎯',
      tier: AchievementTier.gold,
    ),

    // === ЭКОЛОГИЧЕСКИЙ ЭФФЕКТ ===
    Achievement(
      id: 'water_100',
      title: 'Спаситель воды',
      description: 'Сохранено 100 литров воды',
      icon: '💧',
      tier: AchievementTier.bronze,
    ),
    Achievement(
      id: 'water_1000',
      title: 'Хранитель океанов',
      description: 'Сохранено 1000 литров воды',
      icon: '🌊',
      tier: AchievementTier.silver,
    ),
    Achievement(
      id: 'water_10000',
      title: 'Водный страж',
      description: 'Сохранено 10 000 литров воды',
      icon: '🐋',
      tier: AchievementTier.gold,
    ),
    Achievement(
      id: 'energy_100',
      title: 'Энергосберегатель',
      description: 'Сэкономлено 100 кВт·ч энергии',
      icon: '⚡',
      tier: AchievementTier.bronze,
    ),
    Achievement(
      id: 'energy_500',
      title: 'Энергомастер',
      description: 'Сэкономлено 500 кВт·ч энергии',
      icon: '🔋',
      tier: AchievementTier.silver,
    ),
    Achievement(
      id: 'co2_50',
      title: 'Борец с CO₂',
      description: 'Предотвращён выброс 50 кг CO₂',
      icon: '🌬️',
      tier: AchievementTier.bronze,
    ),
    Achievement(
      id: 'co2_200',
      title: 'Чистое небо',
      description: 'Предотвращён выброс 200 кг CO₂',
      icon: '☁️',
      tier: AchievementTier.silver,
    ),
    Achievement(
      id: 'co2_1000',
      title: 'Защитник атмосферы',
      description: 'Предотвращён выброс 1000 кг CO₂',
      icon: '🛡️',
      tier: AchievementTier.gold,
    ),

    // === СПЕЦИАЛЬНЫЕ ===
    Achievement(
      id: 'first_habit',
      title: 'Первый шаг',
      description: 'Отметить свою первую привычку',
      icon: '🚀',
      tier: AchievementTier.bronze,
    ),
    Achievement(
      id: 'first_week_perfect',
      title: 'Идеальная неделя',
      description: '100% выполнение всех привычек за неделю',
      icon: '⭐',
      tier: AchievementTier.silver,
    ),
    Achievement(
      id: 'first_month_perfect',
      title: 'Идеальный месяц',
      description: '100% выполнение всех привычек за месяц',
      icon: '🌟',
      tier: AchievementTier.platinum,
    ),
    Achievement(
      id: 'early_bird',
      title: 'Жаворонок',
      description: 'Отметить 10 привычек до 8 утра',
      icon: '🐦',
      tier: AchievementTier.bronze,
    ),
    Achievement(
      id: 'night_owl',
      title: 'Сова',
      description: 'Отметить 10 привычек после 22:00',
      icon: '🦉',
      tier: AchievementTier.bronze,
    ),
  ];
}
