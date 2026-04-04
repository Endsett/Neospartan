import '../models/fuel_entry.dart';

class LaconicParserService {
  static final LaconicParserService _instance = LaconicParserService._internal();
  factory LaconicParserService() => _instance;
  LaconicParserService._internal();

  // Spartan Dictionary (values per 100g or per unit)
  static const Map<String, Map<String, dynamic>> _dictionary = {
    'chicken': {'p': 31.0, 'c': 0.0, 'f': 3.6, 'cal': 165, 'unit': 'g'},
    'beef': {'p': 26.0, 'c': 0.0, 'f': 15.0, 'cal': 250, 'unit': 'g'},
    'egg': {'p': 6.0, 'c': 0.6, 'f': 5.0, 'cal': 70, 'unit': 'u'},
    'whey': {'p': 24.0, 'c': 3.0, 'f': 1.5, 'cal': 120, 'unit': 'u'}, // per scoop
    'oats': {'p': 13.0, 'c': 66.0, 'f': 7.0, 'cal': 389, 'unit': 'g'},
    'rice': {'p': 2.7, 'c': 28.0, 'f': 0.3, 'cal': 130, 'unit': 'g'},
    'water': {'p': 0.0, 'c': 0.0, 'f': 0.0, 'cal': 0, 'unit': 'ml'},
  };

  // Shorthand aliases
  static const Map<String, String> _aliases = {
    'e': 'egg',
    's': 'whey',
    'w': 'water',
    'c': 'chicken',
    'b': 'beef',
    'o': 'oats',
    'r': 'rice',
  };

  FuelEntry? parse(String input) {
    if (input.isEmpty) return null;

    final query = input.toLowerCase().trim();
    
    // Regex to match: [quantity][unit]? [item] OR [item] [quantity][unit]?
    // Matches: "100g chicken", "2e", "chicken 100", "1s whey"
    final regex = RegExp(r'^(\d+\.?\d*)([a-z]*)\s*([a-z]+)$|^([a-z]+)\s*(\d+\.?\d*)([a-z]*)$');
    final match = regex.firstMatch(query);

    if (match == null) return null;

    double intensity = 0;
    String itemKey = "";

    if (match.group(1) != null) {
      intensity = double.tryParse(match.group(1)!) ?? 0;
      itemKey = match.group(3)!;
    } else {
      intensity = double.tryParse(match.group(5)!) ?? 0;
      itemKey = match.group(4)!;
    }

    // Resolve aliases
    final resolvedKey = _aliases[itemKey] ?? itemKey;
    final food = _dictionary[resolvedKey];

    if (food == null) return null;

    // Calculate macros
    double p = 0, c = 0, f = 0;
    int cal = 0;

    if (food['unit'] == 'g') {
      double factor = intensity / 100.0;
      p = food['p'] * factor;
      c = food['c'] * factor;
      f = food['f'] * factor;
      cal = (food['cal'] * factor).toInt();
    } else {
      // per unit (egg, scoop)
      p = food['p'] * intensity;
      c = food['c'] * intensity;
      f = food['f'] * intensity;
      cal = (food['cal'] * intensity).toInt();
    }

    return FuelEntry(
      id: "fuel_${DateTime.now().millisecondsSinceEpoch}",
      itemName: resolvedKey.toUpperCase(),
      protein: p,
      carbs: c,
      fat: f,
      calories: cal,
      timestamp: DateTime.now(),
    );
  }
}
