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

  String localizedDisplayName(String languageCode) {
    final isEn = languageCode == 'en';
    switch (this) {
      case HabitCategory.waterSaving:
        return isEn ? 'Water saving' : 'Экономия воды';
      case HabitCategory.energySaving:
        return isEn ? 'Energy saving' : 'Экономия энергии';
      case HabitCategory.wasteManagement:
        return isEn ? 'Waste management' : 'Обращение с отходами';
      case HabitCategory.ecoTransport:
        return isEn ? 'Eco transport' : 'Экологичный транспорт';
      case HabitCategory.ecoConsumption:
        return isEn ? 'Eco consumption' : 'Экологичное потребление';
      case HabitCategory.natureCare:
        return isEn ? 'Nature care' : 'Забота о природе';
    }
  }
}
