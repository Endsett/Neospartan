import 'user_profile.dart';

enum ExerciseCategory {
  plyometric,
  isometric,
  combat,
  strength,
  mobility,
  sprint,
}

class Exercise {
  final String id;
  final String name;
  final ExerciseCategory category;
  final String youtubeId;
  final String targetMetaphor;
  final String instructions;
  final int intensityLevel; // 1-10
  final List<String> primaryMuscles;
  final Map<String, int> jointStress; // joint -> stress level 1-10
  final List<TrainingGoal> idealGoals;
  final FitnessLevel minFitnessLevel;
  final FitnessLevel maxFitnessLevel;
  final List<String> workoutTags;
  final String? createdByUserId; // null for global exercises

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.youtubeId,
    required this.targetMetaphor,
    required this.instructions,
    this.intensityLevel = 5,
    this.primaryMuscles = const [],
    this.jointStress = const {},
    this.idealGoals = const [],
    this.minFitnessLevel = FitnessLevel.beginner,
    this.maxFitnessLevel = FitnessLevel.advanced,
    this.workoutTags = const [],
    this.createdByUserId,
  });

  /// Serialize to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.index,
      'youtubeId': youtubeId,
      'targetMetaphor': targetMetaphor,
      'instructions': instructions,
      'intensityLevel': intensityLevel,
      'primaryMuscles': primaryMuscles,
      'jointStress': jointStress,
      'idealGoals': idealGoals.map((g) => g.index).toList(),
      'minFitnessLevel': minFitnessLevel.index,
      'maxFitnessLevel': maxFitnessLevel.index,
      'workoutTags': workoutTags,
      'createdByUserId': createdByUserId,
    };
  }

  /// Deserialize from Map
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      category: ExerciseCategory.values[map['category'] as int],
      youtubeId: map['youtubeId'] as String,
      targetMetaphor: map['targetMetaphor'] as String,
      instructions: map['instructions'] as String,
      intensityLevel: map['intensityLevel'] as int? ?? 5,
      primaryMuscles:
          (map['primaryMuscles'] as List<dynamic>?)?.cast<String>() ?? const [],
      jointStress:
          (map['jointStress'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          const {},
      idealGoals:
          (map['idealGoals'] as List<dynamic>?)
              ?.map((g) => TrainingGoal.values[g as int])
              .toList() ??
          const [],
      minFitnessLevel: FitnessLevel.values[map['minFitnessLevel'] as int? ?? 0],
      maxFitnessLevel: FitnessLevel.values[map['maxFitnessLevel'] as int? ?? 2],
      workoutTags:
          (map['workoutTags'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdByUserId: map['createdByUserId'] as String?,
    );
  }

  /// Deserialize from Supabase database row
  factory Exercise.fromSupabase(Map<String, dynamic> map) {
    final rawCategory = map['category'] as String?;
    final rawMinLevel = map['min_fitness_level'] as String?;
    final rawMaxLevel = map['max_fitness_level'] as String?;
    final rawGoals = map['ideal_goals'] as List<dynamic>?;

    return Exercise(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Exercise',
      category: ExerciseCategory.values.firstWhere(
        (e) => e.name == rawCategory,
        orElse: () => ExerciseCategory.strength,
      ),
      youtubeId: map['youtube_id'] as String? ?? '',
      targetMetaphor: map['target_metaphor'] as String? ?? '',
      instructions: map['instructions'] as String? ?? '',
      intensityLevel: map['intensity_level'] as int? ?? 5,
      primaryMuscles:
          (map['primary_muscles'] as List<dynamic>?)?.cast<String>() ??
          const [],
      jointStress:
          (map['joint_stress'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          const {},
      idealGoals:
          rawGoals
              ?.map(
                (g) => TrainingGoal.values.firstWhere(
                  (tg) => tg.name == g,
                  orElse: () => TrainingGoal.generalCombat,
                ),
              )
              .toList() ??
          const [],
      minFitnessLevel: FitnessLevel.values.firstWhere(
        (e) => e.name == rawMinLevel,
        orElse: () => FitnessLevel.beginner,
      ),
      maxFitnessLevel: FitnessLevel.values.firstWhere(
        (e) => e.name == rawMaxLevel,
        orElse: () => FitnessLevel.advanced,
      ),
      workoutTags:
          (map['workout_tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdByUserId: map['created_by_user_id'] as String?,
    );
  }

  /// Serialize to Supabase database format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'youtube_id': youtubeId,
      'target_metaphor': targetMetaphor,
      'instructions': instructions,
      'intensity_level': intensityLevel,
      'primary_muscles': primaryMuscles,
      'joint_stress': jointStress,
      'ideal_goals': idealGoals.map((g) => g.name).toList(),
      'min_fitness_level': minFitnessLevel.name,
      'max_fitness_level': maxFitnessLevel.name,
      'workout_tags': workoutTags,
      'created_by_user_id': createdByUserId,
    };
  }

  /// Find exercise by ID from library
  static Exercise? findById(String id) {
    try {
      return library.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Exercise> forUserProfile(
    UserProfile profile, {
    String? workoutType,
    int limit = 120,
  }) {
    final normalizedWorkoutType = workoutType?.toLowerCase();
    final limitations =
        profile.injuriesOrLimitations?.map((e) => e.toLowerCase()).toList() ??
        const [];

    final filtered = library.where((exercise) {
      final fitsGoal =
          exercise.idealGoals.isEmpty ||
          exercise.idealGoals.contains(profile.trainingGoal);
      final fitsLevel =
          profile.fitnessLevel.index >= exercise.minFitnessLevel.index &&
          profile.fitnessLevel.index <= exercise.maxFitnessLevel.index;
      final fitsWorkoutType =
          normalizedWorkoutType == null ||
          normalizedWorkoutType.isEmpty ||
          exercise.workoutTags.any(
            (tag) => normalizedWorkoutType.contains(tag.toLowerCase()),
          );

      final conflictsWithLimitation = limitations.any((limitation) {
        return exercise.primaryMuscles.any(
              (muscle) => muscle.toLowerCase().contains(limitation),
            ) ||
            exercise.jointStress.keys.any(
              (joint) => joint.toLowerCase().contains(limitation),
            ) ||
            exercise.instructions.toLowerCase().contains(limitation);
      });

      return fitsGoal &&
          fitsLevel &&
          fitsWorkoutType &&
          !conflictsWithLimitation;
    }).toList();

    if (filtered.isEmpty) {
      return library.take(limit).toList();
    }

    filtered.sort((a, b) => a.intensityLevel.compareTo(b.intensityLevel));
    return filtered.take(limit).toList();
  }

  static final List<Exercise> library = [
    ..._coreLibrary,
    ..._buildExpandedLibrary(),
  ];

  static List<Exercise> _buildExpandedLibrary() {
    final generated = <Exercise>[];
    final goals = TrainingGoal.values;
    var idCounter = 100;

    for (final goal in goals) {
      for (final template in _exerciseTemplates) {
        generated.add(
          Exercise(
            id: 'ex_${idCounter++}',
            name: '${template.baseName} · ${_goalSuffix(goal)}',
            category: template.category,
            youtubeId: template.youtubeId,
            targetMetaphor: template.targetMetaphor,
            instructions: template.instructions,
            intensityLevel: template.intensity,
            primaryMuscles: template.primaryMuscles,
            jointStress: template.jointStress,
            idealGoals: [goal],
            minFitnessLevel: template.minFitnessLevel,
            maxFitnessLevel: template.maxFitnessLevel,
            workoutTags: template.workoutTags,
          ),
        );
      }

      final sportTemplates = _sportSpecificTemplates[goal] ?? const [];
      for (final template in sportTemplates) {
        generated.add(
          Exercise(
            id: 'ex_${idCounter++}',
            name: '${template.baseName} · ${_goalSuffix(goal)}',
            category: template.category,
            youtubeId: template.youtubeId,
            targetMetaphor: template.targetMetaphor,
            instructions: template.instructions,
            intensityLevel: template.intensity,
            primaryMuscles: template.primaryMuscles,
            jointStress: template.jointStress,
            idealGoals: [goal],
            minFitnessLevel: template.minFitnessLevel,
            maxFitnessLevel: template.maxFitnessLevel,
            workoutTags: template.workoutTags,
          ),
        );
      }
    }

    return generated;
  }

  static String _goalSuffix(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.mma:
        return 'MMA';
      case TrainingGoal.boxing:
        return 'BOXING';
      case TrainingGoal.muayThai:
        return 'MUAY THAI';
      case TrainingGoal.wrestling:
        return 'WRESTLING';
      case TrainingGoal.bjj:
        return 'BJJ';
      case TrainingGoal.generalCombat:
        return 'COMBAT';
      case TrainingGoal.strength:
        return 'STRENGTH';
      case TrainingGoal.conditioning:
        return 'CONDITIONING';
    }
  }

  static const List<Exercise> _coreLibrary = [
    // PLYOMETRIC - Explosive Power
    Exercise(
      id: "ex_001",
      name: "LEONIDAS LUNGES",
      category: ExerciseCategory.strength,
      youtubeId: "QOVaHwknd2w",
      targetMetaphor: "The Shield of Archidamus",
      instructions:
          "Weighted lunges with a vertical posture. Keep your core tight like a phalanx.",
      intensityLevel: 7,
      primaryMuscles: ["quads", "glutes", "hamstrings"],
      jointStress: {"knees": 6, "hips": 5},
    ),
    Exercise(
      id: "ex_002",
      name: "PHALANX PUSH-UPS",
      category: ExerciseCategory.plyometric,
      youtubeId: "IODxDxX7oi4",
      targetMetaphor: "Unbreakable Wall",
      instructions: "Explosive push-ups with a narrow hand placement.",
      intensityLevel: 8,
      primaryMuscles: ["chest", "triceps", "shoulders"],
      jointStress: {"wrists": 6, "shoulders": 7, "elbows": 5},
    ),
    Exercise(
      id: "ex_003",
      name: "STOIC PLANK",
      category: ExerciseCategory.isometric,
      youtubeId: "pSHjTRCQxIw",
      targetMetaphor: "The Pillars of Hercules",
      instructions:
          "Low plank held with absolute stillness. Focus on the breath.",
      intensityLevel: 6,
      primaryMuscles: ["core", "shoulders"],
      jointStress: {"shoulders": 4, "lower_back": 5},
    ),
    Exercise(
      id: "ex_004",
      name: "STADION SPRINTS",
      category: ExerciseCategory.sprint,
      youtubeId: "m_Z9yKkU2N8",
      targetMetaphor: "Swift as Hermes",
      instructions:
          "30-second max effort sprints followed by 60-second recovery.",
      intensityLevel: 10,
      primaryMuscles: ["legs", "core"],
      jointStress: {"knees": 7, "ankles": 6, "hips": 5},
    ),
    Exercise(
      id: "ex_005",
      name: "HELLENIC DEADLIFTS",
      category: ExerciseCategory.strength,
      youtubeId: "ytGaGIn6SjE",
      targetMetaphor: "The Weight of the World",
      instructions:
          "Conventional deadlifts focusing on posterior chain engagement.",
      intensityLevel: 9,
      primaryMuscles: ["hamstrings", "glutes", "back", "traps"],
      jointStress: {"lower_back": 8, "knees": 5},
    ),
    Exercise(
      id: "ex_006",
      name: "THERMOPYLAE THRUSTERS",
      category: ExerciseCategory.plyometric,
      youtubeId: "rZ_9GzNUP_M",
      targetMetaphor: "Defy the Odds",
      instructions: "Full squat into overhead press. Maximum explosive power.",
      intensityLevel: 9,
      primaryMuscles: ["quads", "glutes", "shoulders", "traps"],
      jointStress: {"knees": 8, "shoulders": 7, "hips": 6},
    ),
    Exercise(
      id: "ex_007",
      name: "PLIO SPARTAN BURPEE",
      category: ExerciseCategory.plyometric,
      youtubeId: "L61p2B9M2wo",
      targetMetaphor: "Rise from the Ash",
      instructions: "Explosive burpee with tuck jump. Triple extension focus.",
      intensityLevel: 10,
      primaryMuscles: ["full_body"],
      jointStress: {"knees": 9, "wrists": 6, "ankles": 7},
    ),
    Exercise(
      id: "ex_008",
      name: "BOX JUMP ASCENSION",
      category: ExerciseCategory.plyometric,
      youtubeId: "xFfhlTjNJL8",
      targetMetaphor: "Mount Olympus",
      instructions: "Explosive box jumps focusing on soft landings.",
      intensityLevel: 9,
      primaryMuscles: ["quads", "glutes", "calves"],
      jointStress: {"knees": 8, "ankles": 7},
    ),
    // ISOMETRIC - Endurance & Stability
    Exercise(
      id: "ex_009",
      name: "IRON ISO SHADOWBOX",
      category: ExerciseCategory.isometric,
      youtubeId: "WpYm78WJ2U0",
      targetMetaphor: "Unmoving Spear",
      instructions:
          "Hold boxing guard position with light weights. Isometric shoulder endurance.",
      intensityLevel: 7,
      primaryMuscles: ["shoulders", "traps", "core"],
      jointStress: {"shoulders": 6, "wrists": 4},
    ),
    Exercise(
      id: "ex_010",
      name: "WALL SIT AEGIS",
      category: ExerciseCategory.isometric,
      youtubeId: "y-wV4et0t0o",
      targetMetaphor: "The Shield Wall",
      instructions: "Wall sit with weights held at shoulder height.",
      intensityLevel: 7,
      primaryMuscles: ["quads", "shoulders"],
      jointStress: {"knees": 6},
    ),
    Exercise(
      id: "ex_011",
      name: "L-SIT HANG",
      category: ExerciseCategory.isometric,
      youtubeId: "IUZ25V9s6zw",
      targetMetaphor: "Suspend in Void",
      instructions: "L-sit position on parallettes or floor. Core compression.",
      intensityLevel: 8,
      primaryMuscles: ["core", "hip_flexors", "triceps"],
      jointStress: {"wrists": 6, "shoulders": 5},
    ),
    // COMBAT - Fighting Specific
    Exercise(
      id: "ex_012",
      name: "ROTATIONAL MED BALL SLAM",
      category: ExerciseCategory.combat,
      youtubeId: "XJzBLNE_1Q0",
      targetMetaphor: "The Spear Throw",
      instructions:
          "Explosive rotational med ball slams. Hip drive through core.",
      intensityLevel: 9,
      primaryMuscles: ["core", "obliques", "shoulders"],
      jointStress: {"spine": 6, "shoulders": 6},
    ),
    Exercise(
      id: "ex_013",
      name: "BATTLE ROPE TITAN",
      category: ExerciseCategory.combat,
      youtubeId: "A5ZeaEElWjY",
      targetMetaphor: "Wrath of Poseidon",
      instructions: "Alternating battle rope waves with squat stance.",
      intensityLevel: 8,
      primaryMuscles: ["shoulders", "core", "legs"],
      jointStress: {"shoulders": 7},
    ),
    Exercise(
      id: "ex_014",
      name: "SLED PUSH PHALANX",
      category: ExerciseCategory.combat,
      youtubeId: "pASwB0fmoOM",
      targetMetaphor: "Drive the Line",
      instructions: "Heavy sled push for distance. Low stance, driving legs.",
      intensityLevel: 9,
      primaryMuscles: ["legs", "core", "upper_back"],
      jointStress: {"knees": 7, "hips": 6},
    ),
    // MOBILITY - Recovery
    Exercise(
      id: "ex_015",
      name: "90/90 HIP SWITCH",
      category: ExerciseCategory.mobility,
      youtubeId: "C9Jv7hD6kpw",
      targetMetaphor: "The Flexible Shield",
      instructions: "Hip mobility drill for internal/external rotation.",
      intensityLevel: 3,
      primaryMuscles: ["hips"],
      jointStress: {"hips": 2},
    ),
    Exercise(
      id: "ex_016",
      name: "THORACIC BRIDGE FLOW",
      category: ExerciseCategory.mobility,
      youtubeId: "CQNJvoCqzrs",
      targetMetaphor: "The Archer's Extension",
      instructions: "Spine mobility flow through thoracic extension.",
      intensityLevel: 4,
      primaryMuscles: ["spine", "shoulders"],
      jointStress: {"spine": 3, "shoulders": 3},
    ),
    // STRENGTH - Power Foundation
    Exercise(
      id: "ex_017",
      name: "KETTLEBELL SWING WARHAMMER",
      category: ExerciseCategory.strength,
      youtubeId: "YSxHifyI6s8",
      targetMetaphor: "Crush the Enemy",
      instructions: "Russian kettlebell swings with powerful hip extension.",
      intensityLevel: 8,
      primaryMuscles: ["posterior_chain", "core"],
      jointStress: {"lower_back": 6, "shoulders": 5},
    ),
    Exercise(
      id: "ex_018",
      name: "PULL-UP ASCENT",
      category: ExerciseCategory.strength,
      youtubeId: "eGo4IYlbE5g",
      targetMetaphor: "Scale the Walls",
      instructions: "Strict pull-ups, full range of motion, controlled tempo.",
      intensityLevel: 8,
      primaryMuscles: ["lats", "biceps", "core"],
      jointStress: {"shoulders": 6, "elbows": 5},
    ),
    // SPRINT - Alactic Power
    Exercise(
      id: "ex_019",
      name: "HILL SPRINT CONQUEST",
      category: ExerciseCategory.sprint,
      youtubeId: "wS4OsJ4ytP0",
      targetMetaphor: "Seize the High Ground",
      instructions: "Max effort hill sprints. Walk down recovery.",
      intensityLevel: 10,
      primaryMuscles: ["legs", "glutes"],
      jointStress: {"knees": 8, "ankles": 6},
    ),
    Exercise(
      id: "ex_020",
      name: "PROWLER SPRINT",
      category: ExerciseCategory.sprint,
      youtubeId: "qfQyB1JeJrI",
      targetMetaphor: "The Chariot Charge",
      instructions: "Loaded prowler sprint for 20-40m.",
      intensityLevel: 9,
      primaryMuscles: ["legs", "core"],
      jointStress: {"knees": 7, "hips": 6},
    ),
  ];

  static const List<_ExerciseTemplate> _exerciseTemplates = [
    _ExerciseTemplate(
      baseName: 'RING PULL DRIVE',
      category: ExerciseCategory.strength,
      youtubeId: 'YQXnOuQqKYc',
      targetMetaphor: 'Anchor and Row',
      instructions: 'Explosive ring rows with strict scapular control.',
      intensity: 7,
      primaryMuscles: ['upper_back', 'biceps', 'core'],
      jointStress: {'shoulders': 5, 'elbows': 4},
      workoutTags: ['strength', 'pull', 'upper body'],
      minFitnessLevel: FitnessLevel.beginner,
      maxFitnessLevel: FitnessLevel.advanced,
    ),
    _ExerciseTemplate(
      baseName: 'SINGLE-LEG POWER STEP',
      category: ExerciseCategory.plyometric,
      youtubeId: 'fXx2M0Bv8wE',
      targetMetaphor: 'One Foot in the Arena',
      instructions: 'Drive through one leg onto box, controlled descent.',
      intensity: 8,
      primaryMuscles: ['quads', 'glutes', 'calves'],
      jointStress: {'knees': 6, 'ankles': 5},
      workoutTags: ['power', 'lower body', 'conditioning'],
      minFitnessLevel: FitnessLevel.intermediate,
      maxFitnessLevel: FitnessLevel.advanced,
    ),
    _ExerciseTemplate(
      baseName: 'CAGE PRESS LADDER',
      category: ExerciseCategory.combat,
      youtubeId: 'R7n5f4f2f1s',
      targetMetaphor: 'Break the Guard',
      instructions: 'Alternating band punches against resistance intervals.',
      intensity: 8,
      primaryMuscles: ['shoulders', 'triceps', 'core'],
      jointStress: {'shoulders': 6, 'wrists': 4},
      workoutTags: ['striking', 'conditioning', 'combat'],
      minFitnessLevel: FitnessLevel.beginner,
      maxFitnessLevel: FitnessLevel.advanced,
    ),
    _ExerciseTemplate(
      baseName: 'GROUND CHAIN FLOW',
      category: ExerciseCategory.mobility,
      youtubeId: 'w0M2M3hZ9nI',
      targetMetaphor: 'Move Like Water',
      instructions:
          'Continuous ground transitions for thoracic and hip mobility.',
      intensity: 4,
      primaryMuscles: ['hips', 'spine', 'core'],
      jointStress: {'hips': 2, 'spine': 2},
      workoutTags: ['mobility', 'recovery', 'active recovery'],
      minFitnessLevel: FitnessLevel.beginner,
      maxFitnessLevel: FitnessLevel.advanced,
    ),
    _ExerciseTemplate(
      baseName: 'ASSAULT BIKE SURGE',
      category: ExerciseCategory.sprint,
      youtubeId: 'L5m8wN6sR9g',
      targetMetaphor: 'Storm the Gate',
      instructions: '15-second maximal efforts with 45-second easy cadence.',
      intensity: 9,
      primaryMuscles: ['legs', 'lungs', 'core'],
      jointStress: {'knees': 5, 'hips': 5},
      workoutTags: ['conditioning', 'intervals', 'endurance'],
      minFitnessLevel: FitnessLevel.beginner,
      maxFitnessLevel: FitnessLevel.advanced,
    ),
    _ExerciseTemplate(
      baseName: 'FARMER CARRY MARCH',
      category: ExerciseCategory.strength,
      youtubeId: 'sVvYx1J9s2M',
      targetMetaphor: 'Carry the Bronze',
      instructions: 'Heavy carries with controlled breathing and posture.',
      intensity: 7,
      primaryMuscles: ['grip', 'traps', 'core'],
      jointStress: {'lower_back': 5, 'shoulders': 5},
      workoutTags: ['strength', 'core', 'grip'],
      minFitnessLevel: FitnessLevel.beginner,
      maxFitnessLevel: FitnessLevel.advanced,
    ),
    _ExerciseTemplate(
      baseName: 'PUMMEL CONDITIONING ROUND',
      category: ExerciseCategory.combat,
      youtubeId: 'g0L3P4n9QhQ',
      targetMetaphor: 'Own the Clinch',
      instructions: 'Continuous pummeling with level changes in timed rounds.',
      intensity: 8,
      primaryMuscles: ['shoulders', 'back', 'core'],
      jointStress: {'shoulders': 6, 'neck': 5},
      workoutTags: ['wrestling', 'combat', 'conditioning'],
      minFitnessLevel: FitnessLevel.intermediate,
      maxFitnessLevel: FitnessLevel.advanced,
    ),
    _ExerciseTemplate(
      baseName: 'GUARD RETENTION CIRCUIT',
      category: ExerciseCategory.isometric,
      youtubeId: 'v9fM5D1k3Pw',
      targetMetaphor: 'Build the Fortress',
      instructions: 'Hip escapes, frames, and isometric guard holds.',
      intensity: 6,
      primaryMuscles: ['core', 'hip_flexors', 'glutes'],
      jointStress: {'hips': 4, 'lower_back': 4},
      workoutTags: ['bjj', 'core', 'grappling'],
      minFitnessLevel: FitnessLevel.beginner,
      maxFitnessLevel: FitnessLevel.advanced,
    ),
    _ExerciseTemplate(
      baseName: 'SLED DRAG RETREAT',
      category: ExerciseCategory.strength,
      youtubeId: 'z2R8V5nJ4kT',
      targetMetaphor: 'Hold the Line',
      instructions:
          'Backward sled drags for knee resilience and quad strength.',
      intensity: 7,
      primaryMuscles: ['quads', 'tibialis', 'glutes'],
      jointStress: {'knees': 5},
      workoutTags: ['strength', 'rehab', 'lower body'],
      minFitnessLevel: FitnessLevel.beginner,
      maxFitnessLevel: FitnessLevel.advanced,
    ),
    _ExerciseTemplate(
      baseName: 'BREATH-LOCK PLANK SERIES',
      category: ExerciseCategory.isometric,
      youtubeId: 'd2N5qQ3kL0a',
      targetMetaphor: 'Calm Under Siege',
      instructions: 'Plank intervals with breath cadence discipline.',
      intensity: 5,
      primaryMuscles: ['core', 'transverse_abdominis'],
      jointStress: {'shoulders': 3, 'lower_back': 3},
      workoutTags: ['recovery', 'core', 'mindset'],
      minFitnessLevel: FitnessLevel.beginner,
      maxFitnessLevel: FitnessLevel.advanced,
    ),
    _ExerciseTemplate(
      baseName: 'SHADOW SPRAWL INTERVAL',
      category: ExerciseCategory.combat,
      youtubeId: 'u4X8pF7d1mB',
      targetMetaphor: 'Defend the Legs',
      instructions: 'Fast sprawls blended with shadow striking combinations.',
      intensity: 9,
      primaryMuscles: ['full_body', 'core', 'shoulders'],
      jointStress: {'wrists': 5, 'knees': 6, 'hips': 5},
      workoutTags: ['mma', 'conditioning', 'combat'],
      minFitnessLevel: FitnessLevel.intermediate,
      maxFitnessLevel: FitnessLevel.advanced,
    ),
    _ExerciseTemplate(
      baseName: 'AEROBIC BASE SHUTTLE',
      category: ExerciseCategory.sprint,
      youtubeId: 'N5L8jA3wV2s',
      targetMetaphor: 'March Without Break',
      instructions: 'Tempo shuttle runs for extended work capacity.',
      intensity: 6,
      primaryMuscles: ['legs', 'lungs'],
      jointStress: {'knees': 5, 'ankles': 4},
      workoutTags: ['conditioning', 'endurance', 'active recovery'],
      minFitnessLevel: FitnessLevel.beginner,
      maxFitnessLevel: FitnessLevel.advanced,
    ),
    _ExerciseTemplate(
      baseName: 'LANDMINE ROTATION PRESS',
      category: ExerciseCategory.strength,
      youtubeId: 'k3P6rR1mH9d',
      targetMetaphor: 'Twist and Strike',
      instructions: 'Rotational landmine press for transfer to striking power.',
      intensity: 7,
      primaryMuscles: ['obliques', 'shoulders', 'glutes'],
      jointStress: {'spine': 5, 'shoulders': 5},
      workoutTags: ['power', 'combat', 'strength'],
      minFitnessLevel: FitnessLevel.intermediate,
      maxFitnessLevel: FitnessLevel.advanced,
    ),
    _ExerciseTemplate(
      baseName: 'COSSACK MOBILITY REACH',
      category: ExerciseCategory.mobility,
      youtubeId: 'Q9m0Zf7uN3v',
      targetMetaphor: 'Wide Stance Wisdom',
      instructions: 'Lateral mobility with deep groin and ankle loading.',
      intensity: 4,
      primaryMuscles: ['adductors', 'hips', 'ankles'],
      jointStress: {'hips': 3, 'knees': 3, 'ankles': 3},
      workoutTags: ['mobility', 'warmup', 'recovery'],
      minFitnessLevel: FitnessLevel.beginner,
      maxFitnessLevel: FitnessLevel.advanced,
    ),
  ];

  static final Map<TrainingGoal, List<_ExerciseTemplate>>
  _sportSpecificTemplates = {
    TrainingGoal.mma: const [
      _ExerciseTemplate(
        baseName: 'CAGE SCRAMBLE SERIES',
        category: ExerciseCategory.combat,
        youtubeId: 'Ff0mSa7nTqg',
        targetMetaphor: 'Own the Transition',
        instructions: 'Sprawl-to-stand scrambles with explosive transitions.',
        intensity: 9,
        primaryMuscles: ['full_body', 'core', 'hips'],
        jointStress: {'wrists': 5, 'knees': 6, 'hips': 6},
        workoutTags: ['mma', 'grappling', 'conditioning'],
        minFitnessLevel: FitnessLevel.intermediate,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
      _ExerciseTemplate(
        baseName: 'WALL-WORK KNEE DRIVE',
        category: ExerciseCategory.combat,
        youtubeId: 'Qk2aM9hU7fA',
        targetMetaphor: 'Pressure and Break',
        instructions:
            'Clinch wall pressure rounds with alternating knee drives.',
        intensity: 8,
        primaryMuscles: ['core', 'glutes', 'hip_flexors'],
        jointStress: {'hips': 5, 'knees': 5},
        workoutTags: ['mma', 'clinch', 'striking'],
        minFitnessLevel: FitnessLevel.beginner,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
    ],
    TrainingGoal.boxing: const [
      _ExerciseTemplate(
        baseName: 'SLIP-LINE COUNTER ROUND',
        category: ExerciseCategory.combat,
        youtubeId: 'h9pP2z5Y7E0',
        targetMetaphor: 'See and Strike',
        instructions: 'Slip-line movement into fast 2-3 punch counter entries.',
        intensity: 7,
        primaryMuscles: ['shoulders', 'core', 'calves'],
        jointStress: {'ankles': 4, 'shoulders': 5},
        workoutTags: ['boxing', 'striking', 'footwork'],
        minFitnessLevel: FitnessLevel.beginner,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
      _ExerciseTemplate(
        baseName: 'BAG VOLUME FINISHER',
        category: ExerciseCategory.sprint,
        youtubeId: 'R2X7f6cL4pM',
        targetMetaphor: 'Last Bell Dominance',
        instructions: '30-second heavy bag punch bursts with 30-second rest.',
        intensity: 9,
        primaryMuscles: ['shoulders', 'triceps', 'core'],
        jointStress: {'wrists': 5, 'shoulders': 7},
        workoutTags: ['boxing', 'conditioning', 'striking'],
        minFitnessLevel: FitnessLevel.intermediate,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
    ],
    TrainingGoal.muayThai: const [
      _ExerciseTemplate(
        baseName: 'TEEP REBOUND DRILL',
        category: ExerciseCategory.combat,
        youtubeId: 'J8qzX3Yg2uE',
        targetMetaphor: 'Keep the Gate',
        instructions:
            'Front-kick recoil speed rounds with balance hold finish.',
        intensity: 8,
        primaryMuscles: ['quads', 'hip_flexors', 'core'],
        jointStress: {'hips': 5, 'knees': 5, 'ankles': 4},
        workoutTags: ['muay thai', 'striking', 'balance'],
        minFitnessLevel: FitnessLevel.beginner,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
      _ExerciseTemplate(
        baseName: 'CLINCH PULL AND TURN',
        category: ExerciseCategory.combat,
        youtubeId: 'n2vS6L8cQ0k',
        targetMetaphor: 'Break Their Frame',
        instructions: 'Partner or band-resisted clinch pull-turn repetitions.',
        intensity: 8,
        primaryMuscles: ['upper_back', 'forearms', 'core'],
        jointStress: {'neck': 5, 'shoulders': 6},
        workoutTags: ['muay thai', 'clinch', 'grip'],
        minFitnessLevel: FitnessLevel.intermediate,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
    ],
    TrainingGoal.wrestling: const [
      _ExerciseTemplate(
        baseName: 'SHOT-RESHOOT CHAIN',
        category: ExerciseCategory.combat,
        youtubeId: 'u0aN8Q9mL5f',
        targetMetaphor: 'Relentless Entries',
        instructions: 'Penetration step to re-shot chains in timed intervals.',
        intensity: 9,
        primaryMuscles: ['quads', 'glutes', 'core'],
        jointStress: {'knees': 7, 'hips': 6},
        workoutTags: ['wrestling', 'takedown', 'conditioning'],
        minFitnessLevel: FitnessLevel.intermediate,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
      _ExerciseTemplate(
        baseName: 'BRIDGE AND GRANBY FLOW',
        category: ExerciseCategory.mobility,
        youtubeId: 'W8fQ2o9hZ4r',
        targetMetaphor: 'Escape Under Fire',
        instructions:
            'Bridge variations and granby rolls for positional escapes.',
        intensity: 6,
        primaryMuscles: ['neck', 'core', 'hips'],
        jointStress: {'neck': 6, 'spine': 4},
        workoutTags: ['wrestling', 'mobility', 'recovery'],
        minFitnessLevel: FitnessLevel.beginner,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
    ],
    TrainingGoal.bjj: const [
      _ExerciseTemplate(
        baseName: 'OPEN GUARD PUMMEL ROUND',
        category: ExerciseCategory.combat,
        youtubeId: 'p7L4nQ1vZ3k',
        targetMetaphor: 'Control the Distance',
        instructions:
            'Leg pummeling and guard retention rounds for hip dexterity.',
        intensity: 7,
        primaryMuscles: ['hip_flexors', 'core', 'adductors'],
        jointStress: {'hips': 5, 'lower_back': 4},
        workoutTags: ['bjj', 'guard', 'grappling'],
        minFitnessLevel: FitnessLevel.beginner,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
      _ExerciseTemplate(
        baseName: 'ISOMETRIC SQUEEZE SERIES',
        category: ExerciseCategory.isometric,
        youtubeId: 'b3Qk7R1xN6p',
        targetMetaphor: 'Slow Pressure Wins',
        instructions:
            'Adductor and core squeeze holds mirroring positional control.',
        intensity: 6,
        primaryMuscles: ['adductors', 'core', 'glutes'],
        jointStress: {'hips': 4, 'knees': 3},
        workoutTags: ['bjj', 'isometric', 'control'],
        minFitnessLevel: FitnessLevel.beginner,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
    ],
    TrainingGoal.generalCombat: const [
      _ExerciseTemplate(
        baseName: 'MIXED ROUND ENGINE',
        category: ExerciseCategory.combat,
        youtubeId: 'm8K2jS6qH0d',
        targetMetaphor: 'Adapt and Advance',
        instructions:
            'Alternating striking, clinch, and sprawls in mixed rounds.',
        intensity: 8,
        primaryMuscles: ['full_body', 'core', 'shoulders'],
        jointStress: {'knees': 6, 'wrists': 5, 'shoulders': 6},
        workoutTags: ['combat', 'conditioning', 'mixed'],
        minFitnessLevel: FitnessLevel.beginner,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
      _ExerciseTemplate(
        baseName: 'COMBAT FOOTWORK GRID',
        category: ExerciseCategory.sprint,
        youtubeId: 't6X3rL1pQ8b',
        targetMetaphor: 'Own the Space',
        instructions: 'Reactive footwork matrix with directional speed bursts.',
        intensity: 7,
        primaryMuscles: ['calves', 'core', 'hips'],
        jointStress: {'ankles': 5, 'knees': 5},
        workoutTags: ['combat', 'footwork', 'agility'],
        minFitnessLevel: FitnessLevel.beginner,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
    ],
    TrainingGoal.strength: const [
      _ExerciseTemplate(
        baseName: 'FRONT SQUAT TEMPO',
        category: ExerciseCategory.strength,
        youtubeId: 'o9X2kN4gB7e',
        targetMetaphor: 'Build the Pillars',
        instructions:
            'Controlled tempo front squats emphasizing trunk rigidity.',
        intensity: 8,
        primaryMuscles: ['quads', 'core', 'upper_back'],
        jointStress: {'knees': 6, 'lower_back': 5},
        workoutTags: ['strength', 'lower body', 'power'],
        minFitnessLevel: FitnessLevel.beginner,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
      _ExerciseTemplate(
        baseName: 'HEAVY ROW CLUSTER',
        category: ExerciseCategory.strength,
        youtubeId: 'r4N7mQ2sL1f',
        targetMetaphor: 'Pull the World',
        instructions:
            'Cluster sets of heavy rows for upper-back strength reserve.',
        intensity: 8,
        primaryMuscles: ['lats', 'rhomboids', 'biceps'],
        jointStress: {'elbows': 5, 'shoulders': 5},
        workoutTags: ['strength', 'upper body', 'pull'],
        minFitnessLevel: FitnessLevel.intermediate,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
    ],
    TrainingGoal.conditioning: const [
      _ExerciseTemplate(
        baseName: 'THRESHOLD INTERVAL CIRCUIT',
        category: ExerciseCategory.sprint,
        youtubeId: 'x5D2pK7qM9a',
        targetMetaphor: 'Stay in the Fire',
        instructions:
            'Sustainable high-output intervals with short controlled rests.',
        intensity: 8,
        primaryMuscles: ['legs', 'lungs', 'core'],
        jointStress: {'knees': 5, 'ankles': 4},
        workoutTags: ['conditioning', 'endurance', 'intervals'],
        minFitnessLevel: FitnessLevel.beginner,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
      _ExerciseTemplate(
        baseName: 'RECOVERY AEROBIC FLUSH',
        category: ExerciseCategory.mobility,
        youtubeId: 'c7L9hQ3nV1z',
        targetMetaphor: 'Recover to Dominate',
        instructions:
            'Low-impact cyclical work with mobility flow between bouts.',
        intensity: 4,
        primaryMuscles: ['legs', 'hips', 'spine'],
        jointStress: {'knees': 2, 'hips': 2},
        workoutTags: ['conditioning', 'recovery', 'active recovery'],
        minFitnessLevel: FitnessLevel.beginner,
        maxFitnessLevel: FitnessLevel.advanced,
      ),
    ],
  };
}

class _ExerciseTemplate {
  final String baseName;
  final ExerciseCategory category;
  final String youtubeId;
  final String targetMetaphor;
  final String instructions;
  final int intensity;
  final List<String> primaryMuscles;
  final Map<String, int> jointStress;
  final List<String> workoutTags;
  final FitnessLevel minFitnessLevel;
  final FitnessLevel maxFitnessLevel;

  const _ExerciseTemplate({
    required this.baseName,
    required this.category,
    required this.youtubeId,
    required this.targetMetaphor,
    required this.instructions,
    required this.intensity,
    required this.primaryMuscles,
    required this.jointStress,
    required this.workoutTags,
    required this.minFitnessLevel,
    required this.maxFitnessLevel,
  });
}
