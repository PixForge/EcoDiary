/// Модель экологического эффекта
class EcoImpact {
  final double waterSavedLiters;
  final double energySavedKwh;
  final double co2SavedKg;

  const EcoImpact({
    this.waterSavedLiters = 0,
    this.energySavedKwh = 0,
    this.co2SavedKg = 0,
  });

  EcoImpact copyWith({
    double? waterSavedLiters,
    double? energySavedKwh,
    double? co2SavedKg,
  }) {
    return EcoImpact(
      waterSavedLiters: waterSavedLiters ?? this.waterSavedLiters,
      energySavedKwh: energySavedKwh ?? this.energySavedKwh,
      co2SavedKg: co2SavedKg ?? this.co2SavedKg,
    );
  }

  EcoImpact operator +(EcoImpact other) {
    return EcoImpact(
      waterSavedLiters: waterSavedLiters + other.waterSavedLiters,
      energySavedKwh: energySavedKwh + other.energySavedKwh,
      co2SavedKg: co2SavedKg + other.co2SavedKg,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'waterSavedLiters': waterSavedLiters,
      'energySavedKwh': energySavedKwh,
      'co2SavedKg': co2SavedKg,
    };
  }

  factory EcoImpact.fromMap(Map<String, dynamic> map) {
    return EcoImpact(
      waterSavedLiters: (map['waterSavedLiters'] as num?)?.toDouble() ?? 0,
      energySavedKwh: (map['energySavedKwh'] as num?)?.toDouble() ?? 0,
      co2SavedKg: (map['co2SavedKg'] as num?)?.toDouble() ?? 0,
    );
  }
}
