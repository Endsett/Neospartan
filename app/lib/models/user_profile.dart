/// User Fitness Level
enum FitnessLevel {
  beginner,
  intermediate,
  advanced,
}

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
  final BodyComposition bodyComposition;
  final FitnessLevel fitnessLevel;
  final TrainingGoal trainingGoal;
  final int trainingDaysPerWeek;
  final int? preferredWorkoutDuration; // minutes
  final List<String>? injuriesOrLimitations;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool hasCompletedOnboarding;

  const UserProfile({
    required this.userId,
    this.displayName,
    required this.bodyComposition,
    required this.fitnessLevel,
    required this.trainingGoal,
    this.trainingDaysPerWeek = 3,
    this.preferredWorkoutDuration,
    this.injuriesOrLimitations,
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
      'user_id': userId,
      'display_name': displayName,
      'body_composition': bodyComposition.toMap(),
      'fitness_level': fitnessLevel.index,
      'training_goal': trainingGoal.index,
      'training_days_per_week': trainingDaysPerWeek,
      'preferred_workout_duration': preferredWorkoutDuration,
      'injuries_or_limitations': injuriesOrLimitations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'has_completed_onboarding': hasCompletedOnboarding,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['user_id'] ?? '',
      displayName: map['display_name'],
      bodyComposition: BodyComposition.fromMap(map['body_composition'] ?? {}),
      fitnessLevel: FitnessLevel.values[map['fitness_level'] ?? 0],
      trainingGoal: TrainingGoal.values[map['training_goal'] ?? 0],
      trainingDaysPerWeek: map['training_days_per_week'] ?? 3,
      preferredWorkoutDuration: map['preferred_workout_duration'],
      injuriesOrLimitations: (map['injuries_or_limitations'] as List<dynamic>?)?.cast<String>(),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      hasCompletedOnboarding: map['has_completed_onboarding'] ?? false,
    );
  }

  UserProfile copyWith({
    String? userId,
    String? displayName,
    BodyComposition? bodyComposition,
    FitnessLevel? fitnessLevel,
    TrainingGoal? trainingGoal,
    int? trainingDaysPerWeek,
    int? preferredWorkoutDuration,
    List<String>? injuriesOrLimitations,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasCompletedOnboarding,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bodyComposition: bodyComposition ?? this.bodyComposition,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      trainingGoal: trainingGoal ?? this.trainingGoal,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      preferredWorkoutDuration: preferredWorkoutDuration ?? this.preferredWorkoutDuration,
      injuriesOrLimitations: injuriesOrLimitations ?? this.injuriesOrLimitations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
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
