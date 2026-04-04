import 'fuel_entry.dart';

class FuelLog {
  final List<FuelEntry> entries;
  final DateTime date;

  const FuelLog({
    required this.entries,
    required this.date,
  });

  double get totalProtein => entries.fold(0, (sum, e) => sum + e.protein);
  double get totalCarbs => entries.fold(0, (sum, e) => sum + e.carbs);
  double get totalFat => entries.fold(0, (sum, e) => sum + e.fat);
  int get totalCalories => entries.fold(0, (sum, e) => sum + e.calories);

  // Default Spartan targets (can be made dynamic later)
  static const double targetProtein = 200.0;
  static const double targetCarbs = 150.0;
  static const double targetFat = 70.0;
  static const int targetCalories = 2500;
}
