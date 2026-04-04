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
    );
  }

  /// Find exercise by ID from library
  static Exercise? findById(String id) {
    try {
      return library.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  static const List<Exercise> library = [
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
}
