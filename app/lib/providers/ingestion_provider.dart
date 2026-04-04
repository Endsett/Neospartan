import 'package:flutter/material.dart';
import '../models/fuel_entry.dart';
import '../models/fuel_log.dart';
import '../services/laconic_parser_service.dart';

class IngestionProvider with ChangeNotifier {
  final List<FuelEntry> _todayEntries = [];
  final LaconicParserService _parser = LaconicParserService();

  List<FuelEntry> get todayEntries => List.unmodifiable(_todayEntries);

  FuelLog get todayLog => FuelLog(
    entries: _todayEntries,
    date: DateTime.now(),
  );

  bool logFuel(String input) {
    final entry = _parser.parse(input);
    if (entry != null) {
      _todayEntries.insert(0, entry);
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeEntry(String id) {
    _todayEntries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void clearToday() {
    _todayEntries.clear();
    notifyListeners();
  }
}
