class FuelEntry {
  final String id;
  final String itemName;
  final double protein;
  final double carbs;
  final double fat;
  final int calories;
  final DateTime timestamp;

  const FuelEntry({
    required this.id,
    required this.itemName,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'calories': calories,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
