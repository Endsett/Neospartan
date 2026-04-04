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
      userId: map['user_id'] ?? '',
    );
  }
}
