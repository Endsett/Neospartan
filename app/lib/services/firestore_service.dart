import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/workout_tracking.dart';
import '../repositories/user_repository.dart';
import '../repositories/workout_repository.dart';
import '../repositories/biometrics_repository.dart';
import '../repositories/daily_readiness_repository.dart';

/// Unified Firestore Service
/// Provides a single entry point for all Firestore operations
/// Combines all repositories for easy access
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // Repositories
  final UserRepository _userRepository = UserRepository();
  final WorkoutRepository _workoutRepository = WorkoutRepository();
  final BiometricsRepository _biometricsRepository = BiometricsRepository();
  final DailyReadinessRepository _readinessRepository = DailyReadinessRepository();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER OPERATIONS ====================

  Future<UserProfile?> getUserProfile(String userId) =>
      _userRepository.getUserProfile(userId);

  Future<bool> saveUserProfile(UserProfile profile) =>
      _userRepository.saveUserProfile(profile);

  Future<bool> createUserProfile(UserProfile profile) =>
      _userRepository.createUserProfile(profile);

  Stream<UserProfile?> userProfileStream(String userId) =>
      _userRepository.userProfileStream(userId);

  Future<bool> completeOnboarding(String userId) =>
      _userRepository.completeOnboarding(userId);

  // ==================== WORKOUT OPERATIONS ====================

  Future<bool> saveWorkout(String userId, CompletedWorkout workout) =>
      _workoutRepository.saveWorkout(userId, workout);

  Future<CompletedWorkout?> getWorkout(String userId, String workoutId) =>
      _workoutRepository.getWorkout(userId, workoutId);

  Future<List<CompletedWorkout>> getWorkoutHistory(
    String userId, {
    int limit = 50,
    String? startAfterId,
  }) =>
      _workoutRepository.getWorkoutHistory(userId, limit: limit, startAfterId: startAfterId);

  Future<List<CompletedWorkout>> getWorkoutsForDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) =>
      _workoutRepository.getWorkoutsForDateRange(userId, start, end);

  Stream<List<CompletedWorkout>> workoutHistoryStream(
    String userId, {
    int limit = 20,
  }) =>
      _workoutRepository.workoutHistoryStream(userId, limit: limit);

  Stream<List<CompletedWorkout>> todayWorkoutsStream(String userId) =>
      _workoutRepository.todayWorkoutsStream(userId);

  // ==================== BIOMETRIC OPERATIONS ====================

  Future<bool> saveBiometric(BiometricReading reading) =>
      _biometricsRepository.saveBiometric(reading);

  Future<bool> saveBiometricsBatch(List<BiometricReading> readings) =>
      _biometricsRepository.saveBiometricsBatch(readings);

  Future<BiometricReading?> getLatestBiometric(
    String userId,
    BiometricType type,
  ) =>
      _biometricsRepository.getLatestBiometric(userId, type);

  Future<List<BiometricReading>> getBiometricsForRange(
    String userId,
    BiometricType type,
    DateTime start,
    DateTime end,
  ) =>
      _biometricsRepository.getBiometricsForRange(userId, type, start, end);

  Stream<BiometricReading?> latestBiometricStream(
    String userId,
    BiometricType type,
  ) =>
      _biometricsRepository.latestBiometricStream(userId, type);

  // ==================== DAILY READINESS OPERATIONS ====================

  Future<bool> saveDailyReadiness(DailyReadiness readiness) =>
      _readinessRepository.saveReadiness(readiness);

  Future<DailyReadiness?> getTodayReadiness(String userId) =>
      _readinessRepository.getTodayReadiness(userId);

  Future<DailyReadiness?> getReadinessForDate(String userId, DateTime date) =>
      _readinessRepository.getReadinessForDate(userId, date);

  Future<List<DailyReadiness>> getRecentReadiness(
    String userId, {
    int days = 7,
  }) =>
      _readinessRepository.getRecentReadiness(userId, days: days);

  Stream<DailyReadiness?> todayReadinessStream(String userId) =>
      _readinessRepository.todayReadinessStream(userId);

  Future<bool> hasLoggedReadinessToday(String userId) =>
      _readinessRepository.hasLoggedReadinessToday(userId);

  // ==================== BATCH OPERATIONS ====================

  /// Save workout and update user stats in a batch
  Future<bool> saveWorkoutAndUpdateStats(
    String userId,
    CompletedWorkout workout,
  ) async {
    try {
      // Save workout
      final workoutSaved = await _workoutRepository.saveWorkout(userId, workout);
      if (!workoutSaved) return false;

      // Update user stats
      final statsUpdated = await _userRepository.updateWorkoutStats(
        userId,
        workoutsCompleted: 1,
        workoutMinutes: workout.totalDurationMinutes,
        lastWorkoutDate: workout.startTime,
      );

      return statsUpdated;
    } catch (e) {
      developer.log('Error in batch save: $e', name: 'FirestoreService');
      return false;
    }
  }

  /// Get complete user dashboard data
  Future<DashboardData> getDashboardData(String userId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      // Parallel data fetching
      final results = await Future.wait([
        _userRepository.getUserProfile(userId),
        _workoutRepository.getWorkoutsForDateRange(userId, weekStart, now),
        _readinessRepository.getTodayReadiness(userId),
        _biometricsRepository.getLatestBiometric(userId, BiometricType.hrv),
        _biometricsRepository.getLatestBiometric(userId, BiometricType.restingHR),
      ]);

      return DashboardData(
        userProfile: results[0] as UserProfile?,
        thisWeekWorkouts: results[1] as List<CompletedWorkout>,
        todayReadiness: results[2] as DailyReadiness?,
        latestHrv: results[3] as BiometricReading?,
        latestRestingHR: results[4] as BiometricReading?,
      );
    } catch (e) {
      developer.log('Error getting dashboard data: $e', name: 'FirestoreService');
      return DashboardData();
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Check if user exists in Firestore
  Future<bool> userExists(String userId) =>
      _userRepository.userExists(userId);

  /// Get Firestore instance for raw operations
  FirebaseFirestore get firestore => _firestore;

  /// Enable offline persistence (call at app start)
  static Future<void> enableOfflinePersistence() async {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      developer.log('Offline persistence enabled', name: 'FirestoreService');
    } catch (e) {
      developer.log('Error enabling offline persistence: $e', name: 'FirestoreService');
    }
  }
}

/// Dashboard data container
class DashboardData {
  final UserProfile? userProfile;
  final List<CompletedWorkout> thisWeekWorkouts;
  final DailyReadiness? todayReadiness;
  final BiometricReading? latestHrv;
  final BiometricReading? latestRestingHR;

  DashboardData({
    this.userProfile,
    this.thisWeekWorkouts = const [],
    this.todayReadiness,
    this.latestHrv,
    this.latestRestingHR,
  });

  int get workoutsThisWeek => thisWeekWorkouts.length;
  int get totalWorkoutMinutesThisWeek =>
      thisWeekWorkouts.fold(0, (sum, w) => sum + w.totalDurationMinutes);
  double get averageReadiness => todayReadiness?.overallReadiness.toDouble() ?? 70.0;
}
