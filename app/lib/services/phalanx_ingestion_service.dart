import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/exercise.dart';
import '../models/workout_protocol.dart';

/// Phalanx Tactical Ingestion System
/// OCR + NLP pipeline for importing workout plans from various sources
/// Runs locally on device using heuristic parsing (TFLite OCR model would be used for production)
class PhalanxIngestionService {
  static final PhalanxIngestionService _instance = PhalanxIngestionService._internal();
  factory PhalanxIngestionService() => _instance;
  PhalanxIngestionService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  /// Pick image from camera or gallery for OCR
  Future<XFile?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Parse raw text input (from OCR or manual entry)
  /// Handles various formats: shorthand, full text, structured data
  IngestionResult parseWorkoutText(String rawText, {IngestionSource source = IngestionSource.manual}) {
    if (rawText.trim().isEmpty) {
      return IngestionResult.error('Empty input provided');
    }

    final lines = rawText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final parsedDays = <ParsedDay>[];
    var currentDay = <ParsedExercise>[];
    var dayIndex = 1;

    for (final line in lines) {
      final trimmed = line.trim();
      
      // Check for day headers
      if (_isDayHeader(trimmed)) {
        if (currentDay.isNotEmpty) {
          parsedDays.add(ParsedDay(
            dayNumber: dayIndex++,
            exercises: List.from(currentDay),
            focus: _extractFocus(trimmed),
          ));
          currentDay = [];
        }
        continue;
      }

      // Parse exercise entry
      final exercise = _parseExerciseLine(trimmed);
      if (exercise != null) {
        currentDay.add(exercise);
      }
    }

    // Add final day
    if (currentDay.isNotEmpty) {
      parsedDays.add(ParsedDay(
        dayNumber: dayIndex,
        exercises: currentDay,
        focus: 'Mixed',
      ));
    }

    if (parsedDays.isEmpty) {
      return IngestionResult.error('No exercises found in input');
    }

    // Build protocol from parsed days
    final protocol = _buildProtocolFromParsedDays(parsedDays);

    return IngestionResult.success(
      protocol: protocol,
      parsedDays: parsedDays,
      confidence: _calculateConfidence(parsedDays, source),
      warnings: _generateWarnings(parsedDays),
    );
  }

  /// Parse spreadsheet/CSV format
  IngestionResult parseSpreadsheet(String csvData) {
    final lines = csvData.split('\n');
    if (lines.isEmpty) {
      return IngestionResult.error('Empty CSV data');
    }

    final parsedDays = <ParsedDay>[];
    var currentDay = <ParsedExercise>[];
    var dayIndex = 1;

    for (final line in lines.skip(1)) { // Skip header
      final parts = line.split(',');
      if (parts.length < 3) continue;

      // CSV format: Day,Exercise,Sets,Reps,RPE,Rest
      final day = parts[0].trim();
      final exerciseName = parts[1].trim();
      final sets = int.tryParse(parts[2]) ?? 3;
      final reps = int.tryParse(parts[3]) ?? 10;
      final rpe = double.tryParse(parts[4]) ?? 7.0;
      final rest = int.tryParse(parts[5]) ?? 60;

      // Check for new day
      if (day.isNotEmpty && int.tryParse(day) != dayIndex) {
        if (currentDay.isNotEmpty) {
          parsedDays.add(ParsedDay(
            dayNumber: dayIndex++,
            exercises: List.from(currentDay),
          ));
          currentDay = [];
        }
      }

      final matchedExercise = _matchExerciseName(exerciseName);
      currentDay.add(ParsedExercise(
        name: exerciseName,
        matchedExercise: matchedExercise,
        sets: sets,
        reps: 10,
        rpe: rpe,
        restSeconds: rest,
        confidence: matchedExercise != null ? 0.9 : 0.5,
      ));
    }

    if (currentDay.isNotEmpty) {
      parsedDays.add(ParsedDay(
        dayNumber: dayIndex,
        exercises: currentDay,
      ));
    }

    final protocol = _buildProtocolFromParsedDays(parsedDays);
    return IngestionResult.success(
      protocol: protocol,
      parsedDays: parsedDays,
      confidence: 0.9,
    );
  }

  /// Check if line is a day/week header
  bool _isDayHeader(String line) {
    final patterns = [
      RegExp(r'^day\s*\d+', caseSensitive: false),
      RegExp(r'^week\s*\d+', caseSensitive: false),
      RegExp(r'^monday|tuesday|wednesday|thursday|friday|saturday|sunday', caseSensitive: false),
      RegExp(r'^\d+:\s*'), // "1: " format
    ];
    return patterns.any((p) => p.hasMatch(line));
  }

  /// Extract focus from day header
  String _extractFocus(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('push')) return 'Push';
    if (lower.contains('pull')) return 'Pull';
    if (lower.contains('leg') || lower.contains('lower')) return 'Lower Body';
    if (lower.contains('upper')) return 'Upper Body';
    if (lower.contains('full') || lower.contains('total')) return 'Full Body';
    if (lower.contains('cardio') || lower.contains('condition')) return 'Conditioning';
    if (lower.contains('rest') || lower.contains('recovery')) return 'Recovery';
    return 'Mixed';
  }

  /// Parse a single exercise line
  ParsedExercise? _parseExerciseLine(String line) {
    // Try various formats
    
    // Format 1: "Exercise Name: 3x10 @8 RPE (60s rest)"
    final format1 = RegExp(r'^([^:]+):\s*(\d+)\s*x\s*(\d+)\s*@?\s*(\d+(?:\.\d+)?)?\s*(?:RPE|rpe)?\s*(?:\((\d+)s?\s*rest\))?$');
    var match = format1.firstMatch(line);
    if (match != null) {
      final name = match.group(1)!.trim();
      final sets = int.tryParse(match.group(2)!) ?? 3;
      final reps = int.tryParse(match.group(3)!) ?? 10;
      final rpe = double.tryParse(match.group(4) ?? '7') ?? 7.0;
      final rest = int.tryParse(match.group(5) ?? '60') ?? 60;
      final matched = _matchExerciseName(name);
      
      return ParsedExercise(
        name: name,
        matchedExercise: matched,
        sets: sets,
        reps: reps,
        rpe: rpe,
        restSeconds: rest,
        confidence: matched != null ? 0.95 : 0.6,
      );
    }

    // Format 2: "3 sets of 10 reps Squats"
    final format2 = RegExp(r'^(\d+)\s*(?:sets?|x)\s*(?:of\s*)?(\d+)\s*(?:reps?)?\s*(.+)$', caseSensitive: false);
    match = format2.firstMatch(line);
    if (match != null) {
      final sets = int.tryParse(match.group(1)!) ?? 3;
      final reps = int.tryParse(match.group(2)!) ?? 10;
      final name = match.group(3)!.trim();
      final matched = _matchExerciseName(name);
      
      return ParsedExercise(
        name: name,
        matchedExercise: matched,
        sets: sets,
        reps: reps,
        rpe: 7.0,
        restSeconds: 60,
        confidence: matched != null ? 0.9 : 0.5,
      );
    }

    // Format 3: "Squats 3x10"
    final format3 = RegExp(r'^(.+?)\s+(\d+)\s*x\s*(\d+)$');
    match = format3.firstMatch(line);
    if (match != null) {
      final name = match.group(1)!.trim();
      final sets = int.tryParse(match.group(2)!) ?? 3;
      final reps = int.tryParse(match.group(3)!) ?? 10;
      final matched = _matchExerciseName(name);
      
      return ParsedExercise(
        name: name,
        matchedExercise: matched,
        sets: sets,
        reps: reps,
        rpe: 7.0,
        restSeconds: 60,
        confidence: matched != null ? 0.85 : 0.4,
      );
    }

    // Format 4: Spartan shorthand - "3x10 LUNGES"
    final format4 = RegExp(r'^(\d+)\s*x\s*(\d+)\s*(.+)$', caseSensitive: false);
    match = format4.firstMatch(line);
    if (match != null) {
      final sets = int.tryParse(match.group(1)!) ?? 3;
      final reps = int.tryParse(match.group(2)!) ?? 10;
      final name = match.group(3)!.trim();
      final matched = _matchExerciseName(name);
      
      return ParsedExercise(
        name: name,
        matchedExercise: matched,
        sets: sets,
        reps: reps,
        rpe: 7.0,
        restSeconds: 60,
        confidence: matched != null ? 0.8 : 0.3,
      );
    }

    // If no pattern matched, try to extract exercise name only
    final matched = _matchExerciseName(line);
    if (matched != null) {
      return ParsedExercise(
        name: line,
        matchedExercise: matched,
        sets: 3,
        reps: 10,
        rpe: 7.0,
        restSeconds: 60,
        confidence: 0.7,
      );
    }

    return null;
  }

  /// Match text to exercise in library using fuzzy matching
  Exercise? _matchExerciseName(String text) {
    final lower = text.toLowerCase().trim();
    
    // Direct match
    for (final exercise in Exercise.library) {
      if (exercise.name.toLowerCase() == lower) {
        return exercise;
      }
    }
    
    // Contains match
    for (final exercise in Exercise.library) {
      if (exercise.name.toLowerCase().contains(lower) || 
          lower.contains(exercise.name.toLowerCase())) {
        return exercise;
      }
    }
    
    // Keyword matching
    final keywords = {
      'squat': 'ex_002', // Thrusters as squat variant
      'lunge': 'ex_001',
      'deadlift': 'ex_010',
      'pushup': 'ex_001', // Phalanx push-ups
      'push-up': 'ex_001',
      'plank': 'ex_005',
      'sprint': 'ex_013',
      'burpee': 'ex_003',
      'pullup': 'ex_012',
      'pull-up': 'ex_012',
      'shadowbox': 'ex_006',
      'shadow': 'ex_006',
    };
    
    for (final entry in keywords.entries) {
      if (lower.contains(entry.key)) {
        return Exercise.library.firstWhere(
          (e) => e.id == entry.value,
          orElse: () => Exercise.library.first,
        );
      }
    }
    
    return null;
  }

  /// Build protocol from parsed days
  WorkoutProtocol _buildProtocolFromParsedDays(List<ParsedDay> days) {
    // Use first day as template for single-day protocol
    // Multi-day plans would create week-long protocols
    final firstDay = days.first;
    
    final entries = firstDay.exercises.map((e) {
      return ProtocolEntry(
        exercise: e.matchedExercise ?? Exercise.library.first,
        sets: e.sets,
        reps: e.reps,
        intensityRPE: e.rpe,
        restSeconds: e.restSeconds,
      );
    }).toList();

    return WorkoutProtocol(
      title: 'IMPORTED: ${firstDay.focus} PROTOCOL',
      subtitle: 'Phalanx Import | ${days.length} days | Confidence: ${(days.first.exercises.fold(0.0, (sum, e) => sum + e.confidence) / firstDay.exercises.length * 100).round()}%',
      tier: ProtocolTier.ready,
      entries: entries,
      estimatedDurationMinutes: entries.length * 8,
      mindsetPrompt: 'This protocol was forged from your own records. Execute with precision.',
    );
  }

  /// Calculate overall confidence score
  double _calculateConfidence(List<ParsedDay> days, IngestionSource source) {
    if (days.isEmpty) return 0.0;
    
    final exerciseConfidences = days.expand((d) => d.exercises).map((e) => e.confidence);
    final avgConfidence = exerciseConfidences.reduce((a, b) => a + b) / exerciseConfidences.length;
    
    // Adjust for source quality
    final sourceMultiplier = {
      IngestionSource.structured: 1.0,
      IngestionSource.csv: 0.95,
      IngestionSource.ocr: 0.7,
      IngestionSource.manual: 0.9,
    }[source] ?? 0.8;
    
    return (avgConfidence * sourceMultiplier).clamp(0.0, 1.0);
  }

  /// Generate warnings for low-confidence matches
  List<String> _generateWarnings(List<ParsedDay> days) {
    final warnings = <String>[];
    
    final unmatched = days.expand((d) => d.exercises).where((e) => e.matchedExercise == null).toList();
    if (unmatched.isNotEmpty) {
      warnings.add('${unmatched.length} exercises could not be matched to library');
    }
    
    final lowConfidence = days.expand((d) => d.exercises).where((e) => e.confidence < 0.5).toList();
    if (lowConfidence.isNotEmpty) {
      warnings.add('${lowConfidence.length} exercises parsed with low confidence - verify details');
    }
    
    return warnings;
  }
}

/// Ingestion source type
enum IngestionSource {
  ocr,
  manual,
  csv,
  structured,
}

/// Ingestion result
class IngestionResult {
  final bool success;
  final String? errorMessage;
  final WorkoutProtocol? protocol;
  final List<ParsedDay>? parsedDays;
  final double? confidence;
  final List<String>? warnings;

  IngestionResult._({
    required this.success,
    this.errorMessage,
    this.protocol,
    this.parsedDays,
    this.confidence,
    this.warnings,
  });

  factory IngestionResult.success({
    required WorkoutProtocol protocol,
    required List<ParsedDay> parsedDays,
    required double confidence,
    List<String>? warnings,
  }) {
    return IngestionResult._(
      success: true,
      protocol: protocol,
      parsedDays: parsedDays,
      confidence: confidence,
      warnings: warnings,
    );
  }

  factory IngestionResult.error(String message) {
    return IngestionResult._(
      success: false,
      errorMessage: message,
    );
  }
}

/// Parsed day from ingestion
class ParsedDay {
  final int dayNumber;
  final List<ParsedExercise> exercises;
  final String focus;

  ParsedDay({
    required this.dayNumber,
    required this.exercises,
    this.focus = 'Mixed',
  });
}

/// Parsed exercise from ingestion
class ParsedExercise {
  final String name;
  final Exercise? matchedExercise;
  final int sets;
  final int reps;
  final double rpe;
  final int restSeconds;
  final double confidence;

  ParsedExercise({
    required this.name,
    this.matchedExercise,
    required this.sets,
    required this.reps,
    required this.rpe,
    required this.restSeconds,
    required this.confidence,
  });
}
