/// Biometrics Model
class Biometrics {
  final DateTime date;
  final double weight; // kg
  final double bodyFat; // percentage
  final double muscleMass; // kg
  final double? waistCircumference; // cm
  final double? chestCircumference; // cm
  final double? armCircumference; // cm
  final double? thighCircumference; // cm
  final int? hrv; // Heart Rate Variability
  final int? rhr; // Resting Heart Rate
  final double? sleepHours; // Sleep duration
  final int? sleepQuality; // 1-10 scale
  final String userId;

  Biometrics({
    required this.date,
    required this.weight,
    required this.bodyFat,
    required this.muscleMass,
    this.waistCircumference,
    this.chestCircumference,
    this.armCircumference,
    this.thighCircumference,
    this.hrv,
    this.rhr,
    this.sleepHours,
    this.sleepQuality,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'weight': weight,
      'body_fat': bodyFat,
      'muscle_mass': muscleMass,
      'waist_circumference': waistCircumference,
      'chest_circumference': chestCircumference,
      'arm_circumference': armCircumference,
      'thigh_circumference': thighCircumference,
      'hrv': hrv,
      'rhr': rhr,
      'sleep_hours': sleepHours,
      'sleep_quality': sleepQuality,
      'user_id': userId,
    };
  }

  factory Biometrics.fromMap(Map<String, dynamic> map) {
    return Biometrics(
      date: DateTime.parse(map['date']),
      weight: map['weight']?.toDouble() ?? 0.0,
      bodyFat: map['body_fat']?.toDouble() ?? 0.0,
      muscleMass: map['muscle_mass']?.toDouble() ?? 0.0,
      waistCircumference: map['waist_circumference']?.toDouble(),
      chestCircumference: map['chest_circumference']?.toDouble(),
      armCircumference: map['arm_circumference']?.toDouble(),
      thighCircumference: map['thigh_circumference']?.toDouble(),
      hrv: map['hrv']?.toInt(),
      rhr: map['rhr']?.toInt(),
      sleepHours: map['sleep_hours']?.toDouble(),
      sleepQuality: map['sleep_quality']?.toInt(),
      userId: map['user_id'] ?? '',
    );
  }
}

/// Types of biometric measurements
enum BiometricType {
  weight,
  bodyFat,
  muscleMass,
  hrv,
  waist,
  chest,
  arm,
  thigh,
}
