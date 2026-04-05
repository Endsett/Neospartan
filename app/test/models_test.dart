import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/models/workout_tracking.dart';
import 'package:app/models/workout_protocol.dart';

void main() {
  group('Model Tests', () {
    
    group('UserProfile', () {
      test('can be instantiated with minimal data', () {
        final profile = UserProfile(
          userId: 'test-id',
          bodyComposition: BodyComposition(
            weight: 70,
            height: 175,
            age: 25,
          ),
          fitnessLevel: FitnessLevel.beginner,
          trainingGoal: TrainingGoal.generalCombat,
          createdAt: DateTime.now(),
        );
        
        expect(profile.userId, 'test-id');
        expect(profile.fitnessLevel, FitnessLevel.beginner);
      });

      test('hasCompletedOnboarding defaults to false', () {
        final profile = UserProfile(
          userId: 'test-id',
          bodyComposition: BodyComposition(weight: 70, height: 175, age: 25),
          fitnessLevel: FitnessLevel.beginner,
          trainingGoal: TrainingGoal.generalCombat,
          createdAt: DateTime.now(),
        );
        
        expect(profile.hasCompletedOnboarding, false);
      });
    });

    group('WorkoutTracking', () {
      test('MicroCycle can be created', () {
        final cycle = MicroCycle(
          days: [],
          startDate: DateTime.now(),
          endDate: DateTime.now().add(Duration(days: 7)),
        );
        
        expect(cycle.days, isEmpty);
      });

      test('CompletedWorkout can be created', () {
        final workout = CompletedWorkout(
          id: 'test-id',
          protocolTitle: 'Test Workout',
          exercises: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          totalDurationMinutes: 30,
          readinessScoreAtStart: 80,
        );
        
        expect(workout.protocolTitle, 'Test Workout');
        expect(workout.readinessScoreAtStart, 80);
      });
    });

    group('WorkoutProtocol', () {
      test('ProtocolTier enum values exist', () {
        expect(ProtocolTier.values.length, 4);
        expect(ProtocolTier.elite, isNotNull);
        expect(ProtocolTier.ready, isNotNull);
        expect(ProtocolTier.fatigued, isNotNull);
        expect(ProtocolTier.recovery, isNotNull);
      });

      test('TrainingGoal enum values exist', () {
        expect(TrainingGoal.values.length, greaterThan(5));
      });
    });
  });
}
