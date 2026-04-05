/// User Fitness Level
enum FitnessLevel { beginner, intermediate, advanced }

/// Experience Level for training progression
enum ExperienceLevel { novice, hoplite, spartan, legend }

/// Training Goal Types
enum TrainingGoal {
  mma,
  boxing,
  muayThai,
  wrestling,
  bjj,
  generalCombat,
  strength,
  conditioning,
}

/// User Body Composition Data
class BodyComposition {
  final double weight; // kg
  final double height; // cm
  final double? bodyFatPercentage;
  final double? muscleMass; // kg
  final String? gender;
  final int age;

  const BodyComposition({
    required this.weight,
    required this.height,
    this.bodyFatPercentage,
    this.muscleMass,
    this.gender,
    required this.age,
  });

  double get bmi => weight / ((height / 100) * (height / 100));

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'height': height,
      'body_fat_percentage': bodyFatPercentage,
      'muscle_mass': muscleMass,
      'gender': gender,
      'age': age,
      'bmi': bmi,
    };
  }

  factory BodyComposition.fromMap(Map<String, dynamic> map) {
    return BodyComposition(
      weight: map['weight']?.toDouble() ?? 0,
      height: map['height']?.toDouble() ?? 0,
      bodyFatPercentage: map['body_fat_percentage']?.toDouble(),
      muscleMass: map['muscle_mass']?.toDouble(),
      gender: map['gender'],
      age: map['age'] ?? 0,
    );
  }
}

/// Complete User Profile
class UserProfile {
  final String userId;
  final String? displayName;
  final String? photoUrl;
  final BodyComposition bodyComposition;
  final FitnessLevel fitnessLevel;
  final ExperienceLevel? experienceLevel;
  final TrainingGoal trainingGoal;
  final String? philosophicalBaseline;
  final int trainingDaysPerWeek;
  final int? preferredWorkoutDuration; // minutes
  final List<String>? injuriesOrLimitations;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool hasCompletedOnboarding;

  const UserProfile({
    required this.userId,
    this.displayName,
    this.photoUrl,
    required this.bodyComposition,
    required this.fitnessLevel,
    this.experienceLevel,
    required this.trainingGoal,
    this.philosophicalBaseline,
    this.trainingDaysPerWeek = 3,
    this.preferredWorkoutDuration,
    this.injuriesOrLimitations,
    this.dateOfBirth,
    required this.createdAt,
    this.updatedAt,
    this.hasCompletedOnboarding = false,
  });

  String get fitnessLevelText {
    switch (fitnessLevel) {
      case FitnessLevel.beginner:
        return 'Beginner';
      case FitnessLevel.intermediate:
        return 'Intermediate';
      case FitnessLevel.advanced:
        return 'Advanced';
    }
  }

  String get trainingGoalText {
    switch (trainingGoal) {
      case TrainingGoal.mma:
        return 'MMA / Mixed Martial Arts';
      case TrainingGoal.boxing:
        return 'Boxing';
      case TrainingGoal.muayThai:
        return 'Muay Thai';
      case TrainingGoal.wrestling:
        return 'Wrestling';
      case TrainingGoal.bjj:
        return 'Brazilian Jiu-Jitsu';
      case TrainingGoal.generalCombat:
        return 'General Combat Sports';
      case TrainingGoal.strength:
        return 'Strength Training';
      case TrainingGoal.conditioning:
        return 'Combat Conditioning';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': userId,
      'user_id': userId,
      'display_name': displayName,
      'photo_url': photoUrl,
      'body_composition': bodyComposition.toMap(),
      'fitness_level': fitnessLevel.name,
      'experience_level': experienceLevel?.name,
      'training_goal': trainingGoal.name,
      'philosophical_baseline': philosophicalBaseline,
      'training_days_per_week': trainingDaysPerWeek,
      'preferred_workout_duration': preferredWorkoutDuration,
      'injuries_or_limitations': injuriesOrLimitations,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'has_completed_onboarding': hasCompletedOnboarding,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final rawFitness = map['fitness_level'];
    final rawExperience = map['experience_level'];
    final rawGoal = map['training_goal'];

    return UserProfile(
      userId: map['id'] ?? map['user_id'] ?? '',
      displayName: map['display_name'],
      photoUrl: map['photo_url'],
      bodyComposition: BodyComposition.fromMap(map['body_composition'] ?? {}),
      fitnessLevel: rawFitness is int
          ? FitnessLevel.values[rawFitness]
          : FitnessLevel.values.firstWhere(
              (v) => v.name == rawFitness,
              orElse: () => FitnessLevel.beginner,
            ),
      experienceLevel: rawExperience == null
          ? null
          : rawExperience is int
          ? ExperienceLevel.values[rawExperience]
          : ExperienceLevel.values.firstWhere(
              (v) => v.name == rawExperience,
              orElse: () => ExperienceLevel.novice,
            ),
      trainingGoal: rawGoal is int
          ? TrainingGoal.values[rawGoal]
          : TrainingGoal.values.firstWhere(
              (v) => v.name == rawGoal,
              orElse: () => TrainingGoal.generalCombat,
            ),
      philosophicalBaseline: map['philosophical_baseline'],
      trainingDaysPerWeek: map['training_days_per_week'] ?? 3,
      preferredWorkoutDuration: map['preferred_workout_duration'],
      injuriesOrLimitations: (map['injuries_or_limitations'] as List<dynamic>?)
          ?.cast<String>(),
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'])
          : null,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      hasCompletedOnboarding: map['has_completed_onboarding'] ?? false,
    );
  }

  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? photoUrl,
    BodyComposition? bodyComposition,
    FitnessLevel? fitnessLevel,
    ExperienceLevel? experienceLevel,
    TrainingGoal? trainingGoal,
    String? philosophicalBaseline,
    int? trainingDaysPerWeek,
    int? preferredWorkoutDuration,
    List<String>? injuriesOrLimitations,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasCompletedOnboarding,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bodyComposition: bodyComposition ?? this.bodyComposition,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      trainingGoal: trainingGoal ?? this.trainingGoal,
      philosophicalBaseline:
          philosophicalBaseline ?? this.philosophicalBaseline,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      preferredWorkoutDuration:
          preferredWorkoutDuration ?? this.preferredWorkoutDuration,
      injuriesOrLimitations:
          injuriesOrLimitations ?? this.injuriesOrLimitations,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

/// Weekly Progress Tracking for AI Adjustments
class WeeklyProgress {
  final DateTime weekStarting;
  final int workoutsCompleted;
  final int totalPlannedWorkouts;
  final double averageRPE;
  final double totalVolume;
  final int averageReadiness;
  final bool achievedGoals;
  final String? userFeedback;
  final List<double>? dailyReadinessScores;

  const WeeklyProgress({
    required this.weekStarting,
    required this.workoutsCompleted,
    required this.totalPlannedWorkouts,
    required this.averageRPE,
    required this.totalVolume,
    required this.averageReadiness,
    this.achievedGoals = false,
    this.userFeedback,
    this.dailyReadinessScores,
  });

  double get completionRate =>
      totalPlannedWorkouts > 0 ? workoutsCompleted / totalPlannedWorkouts : 0;

  bool get shouldIncreaseDifficulty =>
      completionRate >= 0.8 && averageReadiness >= 70 && averageRPE <= 8;

  bool get shouldDecreaseDifficulty =>
      completionRate < 0.5 || averageReadiness < 50;

  Map<String, dynamic> toMap() {
    return {
      'week_starting': weekStarting.toIso8601String(),
      'workouts_completed': workoutsCompleted,
      'total_planned_workouts': totalPlannedWorkouts,
      'average_rpe': averageRPE,
      'total_volume': totalVolume,
      'average_readiness': averageReadiness,
      'achieved_goals': achievedGoals,
      'user_feedback': userFeedback,
      'daily_readiness_scores': dailyReadinessScores,
    };
  }
}
