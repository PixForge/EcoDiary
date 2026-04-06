/// Категории экологических привычек
enum HabitCategory {
  waterSaving,       // Экономия воды
  energySaving,      // Экономия энергии
  wasteManagement,   // Обращение с отходами
  ecoTransport,      // Экологичный транспорт
  ecoConsumption,    // Экологичное потребление
  natureCare,        // Забота о природе
}

extension HabitCategoryExtension on HabitCategory {
  String get displayName {
    switch (this) {
      case HabitCategory.waterSaving:
        return 'Экономия воды';
      case HabitCategory.energySaving:
        return 'Экономия энергии';
      case HabitCategory.wasteManagement:
        return 'Обращение с отходами';
      case HabitCategory.ecoTransport:
        return 'Экологичный транспорт';
      case HabitCategory.ecoConsumption:
        return 'Экологичное потребление';
      case HabitCategory.natureCare:
        return 'Забота о природе';
    }
  }

  String get icon {
    switch (this) {
      case HabitCategory.waterSaving:
        return '💧';
      case HabitCategory.energySaving:
        return '⚡';
      case HabitCategory.wasteManagement:
        return '♻️';
      case HabitCategory.ecoTransport:
        return '🚲';
      case HabitCategory.ecoConsumption:
        return '🛒';
      case HabitCategory.natureCare:
        return '🌿';
    }
  }
}
