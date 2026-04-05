/// Workout template system for structured workout generation
/// Templates define the structure, AI fills in the specific exercises

library workout_template;

import '../models/sport_category.dart' hide ExerciseCategory;
import '../models/equipment_type.dart';
import '../models/movement_pattern.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../data/combat_exercise_library.dart';

/// A complete workout template for a specific training focus
class WorkoutTemplate {
  final String id;
  final String name;
  final String description;
  final SportCategory primarySport;
  final TrainingFocus trainingFocus;
  final Duration targetDuration;
  final List<TemplateBlock> blocks;
  final List<EquipmentType> requiredEquipment;
  final List<EquipmentType> optionalEquipment;
  final FitnessLevel minFitnessLevel;
  final FitnessLevel maxFitnessLevel;
  final int recommendedWeeklyFrequency;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.primarySport,
    required this.trainingFocus,
    required this.targetDuration,
    required this.blocks,
    this.requiredEquipment = const [],
    this.optionalEquipment = const [],
    this.minFitnessLevel = FitnessLevel.beginner,
    this.maxFitnessLevel = FitnessLevel.advanced,
    this.recommendedWeeklyFrequency = 2,
  });

  /// Total target duration across all blocks
  Duration get totalTargetDuration {
    return blocks.fold<Duration>(
      Duration.zero,
      (sum, block) => sum + block.targetDuration,
    );
  }

  /// Check if user has required equipment
  bool hasRequiredEquipment(List<EquipmentType> available) {
    return requiredEquipment.every((req) => available.contains(req));
  }

  /// Get missing equipment
  List<EquipmentType> getMissingEquipment(List<EquipmentType> available) {
    return requiredEquipment.where((req) => !available.contains(req)).toList();
  }

  /// Calculate difficulty score (1-10)
  int get difficultyScore {
    final levelScore = (minFitnessLevel.index + maxFitnessLevel.index) * 2;
    final blockScore = blocks.length * 2;
    final equipmentScore = requiredEquipment.length;
    return ((levelScore + blockScore + equipmentScore) / 2).round().clamp(
      1,
      10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'primary_sport': primarySport.name,
      'training_focus': trainingFocus.name,
      'target_duration_minutes': targetDuration.inMinutes,
      'blocks': blocks.map((b) => b.toMap()).toList(),
      'required_equipment': requiredEquipment.map((e) => e.name).toList(),
      'optional_equipment': optionalEquipment.map((e) => e.name).toList(),
      'min_level': minFitnessLevel.index,
      'max_level': maxFitnessLevel.index,
      'weekly_frequency': recommendedWeeklyFrequency,
    };
  }
}

/// A block within a workout template (e.g., warmup, main work, finisher)
class TemplateBlock {
  final String id;
  final String name;
  final BlockType type;
  final String description;
  final Duration targetDuration;
  final List<ExerciseSlot> exerciseSlots;
  final String focusDescription;
  final int? targetRpe;

  const TemplateBlock({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.targetDuration,
    required this.exerciseSlots,
    required this.focusDescription,
    this.targetRpe,
  });

  /// Target number of exercises in this block
  int get exerciseCount => exerciseSlots.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'description': description,
      'target_duration_seconds': targetDuration.inSeconds,
      'exercise_slots': exerciseSlots.map((s) => s.toMap()).toList(),
      'focus_description': focusDescription,
      'target_rpe': targetRpe,
    };
  }
}

/// Types of workout blocks
enum BlockType {
  warmup,
  activation,
  skillWork,
  mainWork,
  strength,
  conditioning,
  plyometrics,
  combatSpecific,
  finisher,
  cooldown,
  mobility,
  recovery,
}

/// A slot to be filled with an exercise from the library
class ExerciseSlot {
  final String id;
  final String description;
  final List<ExerciseCategory> preferredCategories;
  final List<MovementPattern> requiredPatterns;
  final List<SportCategory> preferredSports;
  final int minIntensity;
  final int maxIntensity;
  final int targetSets;
  final String targetReps; // e.g., "8-12" or "30s"
  final int targetRpe;
  final int restSeconds;
  final List<EquipmentType> requiredEquipment;
  final bool isOptional;

  const ExerciseSlot({
    required this.id,
    required this.description,
    this.preferredCategories = const [],
    this.requiredPatterns = const [],
    this.preferredSports = const [],
    this.minIntensity = 1,
    this.maxIntensity = 10,
    this.targetSets = 3,
    this.targetReps = '8-12',
    this.targetRpe = 7,
    this.restSeconds = 60,
    this.requiredEquipment = const [],
    this.isOptional = false,
  });

  /// Check if an exercise fits this slot
  bool fitsExercise(CombatExercise exercise) {
    // Check intensity range
    if (exercise.intensityLevel < minIntensity ||
        exercise.intensityLevel > maxIntensity) {
      return false;
    }

    // Check category preference (if specified)
    if (preferredCategories.isNotEmpty &&
        !preferredCategories.contains(exercise.category)) {
      return false;
    }

    // Check movement pattern requirement (if specified)
    if (requiredPatterns.isNotEmpty &&
        !exercise.movementPatterns.any((p) => requiredPatterns.contains(p))) {
      return false;
    }

    // Check sport preference (if specified)
    if (preferredSports.isNotEmpty &&
        !exercise.sports.any((s) => preferredSports.contains(s))) {
      return false;
    }

    // Check equipment requirement
    if (requiredEquipment.isNotEmpty &&
        !exercise.equipment.any((e) => requiredEquipment.contains(e))) {
      return false;
    }

    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'preferred_categories': preferredCategories.map((c) => c.name).toList(),
      'required_patterns': requiredPatterns.map((p) => p.name).toList(),
      'preferred_sports': preferredSports.map((s) => s.name).toList(),
      'min_intensity': minIntensity,
      'max_intensity': maxIntensity,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_rpe': targetRpe,
      'rest_seconds': restSeconds,
      'required_equipment': requiredEquipment.map((e) => e.name).toList(),
      'is_optional': isOptional,
    };
  }
}

/// Pre-built workout templates for combat sports
class CombatWorkoutTemplates {
  /// MMA Conditioning Template
  static WorkoutTemplate get mmaConditioning => WorkoutTemplate(
    id: 'mma_cond_001',
    name: 'MMA Fight Conditioning',
    description: 'High-intensity conditioning session mimicking MMA fight pace',
    primarySport: SportCategory.mma,
    trainingFocus: TrainingFocus.powerEndurance,
    targetDuration: const Duration(minutes: 60),
    blocks: [
      // Warmup
      TemplateBlock(
        id: 'warmup',
        name: 'Fight Prep Warmup',
        type: BlockType.warmup,
        description: 'Dynamic movement preparation',
        targetDuration: const Duration(minutes: 10),
        focusDescription: 'Increase body temperature and mobility',
        targetRpe: 5,
        exerciseSlots: [
          ExerciseSlot(
            id: 'w1',
            description: 'Shadow movement flow',
            preferredCategories: [ExerciseCategory.mobility],
            targetSets: 1,
            targetReps: '3 min',
            targetRpe: 4,
            restSeconds: 0,
          ),
          ExerciseSlot(
            id: 'w2',
            description: 'Dynamic stretching',
            preferredCategories: [ExerciseCategory.mobility],
            targetSets: 1,
            targetReps: '5 min',
            targetRpe: 3,
            restSeconds: 0,
          ),
        ],
      ),
      // Main Work - Round 1: Striking
      TemplateBlock(
        id: 'striking',
        name: 'Striking Power',
        type: BlockType.combatSpecific,
        description: 'Explosive striking combinations',
        targetDuration: const Duration(minutes: 15),
        focusDescription: 'Max power output on heavy bag',
        targetRpe: 8,
        exerciseSlots: [
          ExerciseSlot(
            id: 's1',
            description: 'Heavy bag power rounds',
            preferredCategories: [ExerciseCategory.combat],
            preferredSports: [SportCategory.mma, SportCategory.boxing],
            requiredPatterns: [MovementPattern.punch, MovementPattern.kick],
            minIntensity: 7,
            targetSets: 5,
            targetReps: '3 min rounds',
            targetRpe: 8,
            restSeconds: 60,
            requiredEquipment: [EquipmentType.heavyBag],
          ),
        ],
      ),
      // Round 2: Wrestling
      TemplateBlock(
        id: 'wrestling',
        name: 'Grappling Endurance',
        type: BlockType.combatSpecific,
        description: 'Takedown and control endurance',
        targetDuration: const Duration(minutes: 15),
        focusDescription: 'Maintain technique under fatigue',
        targetRpe: 8,
        exerciseSlots: [
          ExerciseSlot(
            id: 'gr1',
            description: 'Shot chain drill',
            preferredCategories: [ExerciseCategory.combat],
            preferredSports: [SportCategory.mma, SportCategory.wrestling],
            requiredPatterns: [MovementPattern.shoot, MovementPattern.sprawl],
            minIntensity: 7,
            targetSets: 5,
            targetReps: '1 min on/off',
            targetRpe: 8,
            restSeconds: 60,
          ),
        ],
      ),
      // Round 3: Conditioning
      TemplateBlock(
        id: 'conditioning',
        name: 'Fight Pace Conditioning',
        type: BlockType.conditioning,
        description: 'Match the demands of a fight',
        targetDuration: const Duration(minutes: 12),
        focusDescription: 'Sustained high output',
        targetRpe: 9,
        exerciseSlots: [
          ExerciseSlot(
            id: 'c1',
            description: 'Combat complex circuit',
            preferredCategories: [
              ExerciseCategory.plyometric,
              ExerciseCategory.sprint,
            ],
            minIntensity: 8,
            targetSets: 3,
            targetReps: '4 min rounds',
            targetRpe: 9,
            restSeconds: 120,
          ),
        ],
      ),
      // Finisher
      TemplateBlock(
        id: 'finisher',
        name: 'Empty the Tank',
        type: BlockType.finisher,
        description: 'Final push to simulate championship rounds',
        targetDuration: const Duration(minutes: 5),
        focusDescription: 'Maximum effort - leave nothing',
        targetRpe: 10,
        exerciseSlots: [
          ExerciseSlot(
            id: 'f1',
            description: 'Max effort finisher',
            preferredCategories: [
              ExerciseCategory.sprint,
              ExerciseCategory.plyometric,
            ],
            minIntensity: 9,
            targetSets: 1,
            targetReps: '5 min',
            targetRpe: 10,
            restSeconds: 0,
          ),
        ],
      ),
      // Cooldown
      TemplateBlock(
        id: 'cooldown',
        name: 'Recovery Flow',
        type: BlockType.cooldown,
        description: 'Bring heart rate down and begin recovery',
        targetDuration: const Duration(minutes: 5),
        focusDescription: 'Active recovery and stretching',
        targetRpe: 3,
        exerciseSlots: [
          ExerciseSlot(
            id: 'cd1',
            description: 'Mobility and breathing',
            preferredCategories: [ExerciseCategory.mobility],
            targetSets: 1,
            targetReps: '5 min',
            targetRpe: 2,
            restSeconds: 0,
          ),
        ],
      ),
    ],
    requiredEquipment: [EquipmentType.heavyBag],
    optionalEquipment: [EquipmentType.medicineBall, EquipmentType.plyoBox],
    recommendedWeeklyFrequency: 2,
  );

  /// Boxing Power Template
  static WorkoutTemplate get boxingPower => WorkoutTemplate(
    id: 'box_pwr_001',
    name: 'Boxing Power Development',
    description: 'Build knockout power through explosive training',
    primarySport: SportCategory.boxing,
    trainingFocus: TrainingFocus.explosivePower,
    targetDuration: const Duration(minutes: 45),
    blocks: [
      TemplateBlock(
        id: 'activation',
        name: 'Neural Activation',
        type: BlockType.activation,
        description: 'Wake up the nervous system',
        targetDuration: const Duration(minutes: 8),
        focusDescription: 'Explosive primer movements',
        targetRpe: 6,
        exerciseSlots: [
          ExerciseSlot(
            id: 'a1',
            description: 'Plyometric activation',
            preferredCategories: [ExerciseCategory.plyometric],
            targetSets: 3,
            targetReps: '5 reps',
            targetRpe: 6,
            restSeconds: 60,
          ),
        ],
      ),
      TemplateBlock(
        id: 'power',
        name: 'Power Development',
        type: BlockType.strength,
        description: 'Build punching power',
        targetDuration: const Duration(minutes: 25),
        focusDescription: 'Heavy compound movements',
        targetRpe: 8,
        exerciseSlots: [
          ExerciseSlot(
            id: 'p1',
            description: 'Rotational power exercise',
            preferredCategories: [
              ExerciseCategory.strength,
              ExerciseCategory.plyometric,
            ],
            requiredPatterns: [MovementPattern.rotation],
            minIntensity: 7,
            targetSets: 5,
            targetReps: '3-5 reps',
            targetRpe: 8,
            restSeconds: 120,
          ),
          ExerciseSlot(
            id: 'p2',
            description: 'Posterior chain power',
            preferredCategories: [ExerciseCategory.strength],
            minIntensity: 7,
            targetSets: 4,
            targetReps: '5 reps',
            targetRpe: 8,
            restSeconds: 120,
          ),
        ],
      ),
      TemplateBlock(
        id: 'speed',
        name: 'Speed Work',
        type: BlockType.skillWork,
        description: 'Apply power to punching',
        targetDuration: const Duration(minutes: 10),
        focusDescription: 'Explosive bag work',
        targetRpe: 9,
        exerciseSlots: [
          ExerciseSlot(
            id: 's1',
            description: 'Speed bag or double-end',
            preferredCategories: [ExerciseCategory.combat],
            preferredSports: [SportCategory.boxing],
            minIntensity: 7,
            targetSets: 3,
            targetReps: '2 min',
            targetRpe: 9,
            restSeconds: 60,
          ),
        ],
      ),
    ],
    requiredEquipment: [],
    recommendedWeeklyFrequency: 2,
  );

  /// Wrestling Strength Template
  static WorkoutTemplate get wrestlingStrength => WorkoutTemplate(
    id: 'wrest_str_001',
    name: 'Wrestling Strength Base',
    description: 'Build the strength foundation for wrestling',
    primarySport: SportCategory.wrestling,
    trainingFocus: TrainingFocus.grapplingStrength,
    targetDuration: const Duration(minutes: 60),
    blocks: [
      TemplateBlock(
        id: 'prep',
        name: 'Movement Prep',
        type: BlockType.warmup,
        description: 'Prepare joints and activate muscles',
        targetDuration: const Duration(minutes: 10),
        focusDescription: 'Hip and shoulder mobility',
        targetRpe: 4,
        exerciseSlots: [
          ExerciseSlot(
            id: 'mp1',
            description: 'Hip and ankle flow',
            preferredCategories: [ExerciseCategory.mobility],
            targetSets: 1,
            targetReps: '5 min',
            targetRpe: 3,
          ),
        ],
      ),
      TemplateBlock(
        id: 'main_strength',
        name: 'Main Lifts',
        type: BlockType.strength,
        description: 'Heavy compound lifts',
        targetDuration: const Duration(minutes: 35),
        focusDescription: 'Build absolute strength',
        targetRpe: 8,
        exerciseSlots: [
          ExerciseSlot(
            id: 'ms1',
            description: 'Lower body push/pull',
            preferredCategories: [ExerciseCategory.strength],
            minIntensity: 7,
            targetSets: 5,
            targetReps: '5 reps',
            targetRpe: 8,
            restSeconds: 180,
          ),
          ExerciseSlot(
            id: 'ms2',
            description: 'Upper body pull focus',
            preferredCategories: [ExerciseCategory.strength],
            minIntensity: 7,
            targetSets: 4,
            targetReps: '6-8 reps',
            targetRpe: 8,
            restSeconds: 120,
          ),
          ExerciseSlot(
            id: 'ms3',
            description: 'Core stability',
            preferredCategories: [ExerciseCategory.isometric],
            minIntensity: 6,
            targetSets: 4,
            targetReps: '30s hold',
            targetRpe: 7,
            restSeconds: 60,
          ),
        ],
      ),
      TemplateBlock(
        id: 'accessory',
        name: 'Grappling-Specific',
        type: BlockType.strength,
        description: 'Support muscles for wrestling',
        targetDuration: const Duration(minutes: 10),
        focusDescription: 'Grip, neck, and posterior chain',
        targetRpe: 7,
        exerciseSlots: [
          ExerciseSlot(
            id: 'acc1',
            description: 'Grip and neck work',
            minIntensity: 6,
            targetSets: 3,
            targetReps: 'to fatigue',
            targetRpe: 7,
            restSeconds: 60,
          ),
        ],
      ),
    ],
    requiredEquipment: [],
    recommendedWeeklyFrequency: 3,
  );

  /// BJJ Guard Work Template
  static WorkoutTemplate get bjjGuard => WorkoutTemplate(
    id: 'bjj_guard_001',
    name: 'BJJ Guard Development',
    description: 'Build guard retention and attack capability',
    primarySport: SportCategory.bjj,
    trainingFocus: TrainingFocus.grapplingStrength,
    targetDuration: const Duration(minutes: 45),
    blocks: [
      TemplateBlock(
        id: 'hip_mobility',
        name: 'Hip Preparation',
        type: BlockType.warmup,
        description: 'Essential hip mobility for guard work',
        targetDuration: const Duration(minutes: 10),
        focusDescription: 'Open hips and activate core',
        targetRpe: 4,
        exerciseSlots: [
          ExerciseSlot(
            id: 'hm1',
            description: '90/90 and hip flow',
            preferredCategories: [ExerciseCategory.mobility],
            requiredPatterns: [MovementPattern.hipMobility],
            targetSets: 1,
            targetReps: '8 min',
            targetRpe: 3,
          ),
        ],
      ),
      TemplateBlock(
        id: 'guard_drills',
        name: 'Guard Movement',
        type: BlockType.skillWork,
        description: 'Drill guard retention patterns',
        targetDuration: const Duration(minutes: 15),
        focusDescription: 'Technical precision',
        targetRpe: 6,
        exerciseSlots: [
          ExerciseSlot(
            id: 'gd1',
            description: 'Hip escape and recovery',
            preferredCategories: [ExerciseCategory.combat],
            preferredSports: [SportCategory.bjj],
            requiredPatterns: [MovementPattern.shrimp],
            targetSets: 5,
            targetReps: '2 min',
            targetRpe: 6,
            restSeconds: 30,
          ),
        ],
      ),
      TemplateBlock(
        id: 'isometric',
        name: 'Guard Strength',
        type: BlockType.strength,
        description: 'Isometric holds for guard control',
        targetDuration: const Duration(minutes: 15),
        focusDescription: 'Build holding strength',
        targetRpe: 7,
        exerciseSlots: [
          ExerciseSlot(
            id: 'iso1',
            description: 'Guard position holds',
            preferredCategories: [ExerciseCategory.isometric],
            targetSets: 4,
            targetReps: '45s hold',
            targetRpe: 7,
            restSeconds: 60,
          ),
        ],
      ),
    ],
    requiredEquipment: [],
    recommendedWeeklyFrequency: 2,
  );

  /// Active Recovery Template
  static WorkoutTemplate get activeRecovery => WorkoutTemplate(
    id: 'rec_001',
    name: 'Active Recovery',
    description: 'Promote recovery while staying active',
    primarySport: SportCategory.generalCombat,
    trainingFocus: TrainingFocus.recovery,
    targetDuration: const Duration(minutes: 30),
    blocks: [
      TemplateBlock(
        id: 'flow',
        name: 'Movement Flow',
        type: BlockType.mobility,
        description: 'Gentle full body movement',
        targetDuration: const Duration(minutes: 15),
        focusDescription: 'Blood flow without stress',
        targetRpe: 3,
        exerciseSlots: [
          ExerciseSlot(
            id: 'f1',
            description: 'Light cardio',
            preferredCategories: [ExerciseCategory.sprint],
            maxIntensity: 4,
            targetSets: 1,
            targetReps: '10 min',
            targetRpe: 3,
          ),
        ],
      ),
      TemplateBlock(
        id: 'stretch',
        name: 'Flexibility Work',
        type: BlockType.mobility,
        description: 'Static and dynamic stretching',
        targetDuration: const Duration(minutes: 15),
        focusDescription: 'Increase range of motion',
        targetRpe: 2,
        exerciseSlots: [
          ExerciseSlot(
            id: 'sw1',
            description: 'Full body stretch',
            preferredCategories: [ExerciseCategory.mobility],
            targetSets: 1,
            targetReps: '15 min',
            targetRpe: 2,
          ),
        ],
      ),
    ],
    requiredEquipment: [],
    minFitnessLevel: FitnessLevel.beginner,
    maxFitnessLevel: FitnessLevel.advanced,
    recommendedWeeklyFrequency: 2,
  );

  /// Get all templates
  static List<WorkoutTemplate> get all => [
    mmaConditioning,
    boxingPower,
    wrestlingStrength,
    bjjGuard,
    activeRecovery,
  ];

  /// Get templates by sport
  static List<WorkoutTemplate> bySport(SportCategory sport) {
    return all.where((t) => t.primarySport == sport).toList();
  }

  /// Get templates by training focus
  static List<WorkoutTemplate> byTrainingFocus(TrainingFocus focus) {
    return all.where((t) => t.trainingFocus == focus).toList();
  }

  /// Get templates suitable for user's fitness level
  static List<WorkoutTemplate> forFitnessLevel(FitnessLevel level) {
    return all
        .where(
          (t) =>
              level.index >= t.minFitnessLevel.index &&
              level.index <= t.maxFitnessLevel.index,
        )
        .toList();
  }

  /// Get templates suitable for available equipment
  static List<WorkoutTemplate> forEquipment(
    List<EquipmentType> availableEquipment,
  ) {
    return all
        .where((t) => t.hasRequiredEquipment(availableEquipment))
        .toList();
  }

  /// Get template by ID
  static WorkoutTemplate? byId(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}
