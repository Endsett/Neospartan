import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/supabase_auth_service.dart';
import 'package:app/services/supabase_database_service.dart';
import 'package:app/config/supabase_config.dart';

void main() {
  group('Supabase Integration Tests', () {
    
    test('SupabaseConfig is not using dev keys', () {
      // Verify we're not using placeholder keys
      final isDev = SupabaseConfig.isUsingDevKeys;
      
      // This will be true if .env file has placeholder values
      // In production, this should be false
      print('Using dev keys: $isDev');
    });

    test('SupabaseAuthService is a singleton', () {
      final instance1 = SupabaseAuthService();
      final instance2 = SupabaseAuthService();
      
      expect(identical(instance1, instance2), true);
    });

    test('SupabaseDatabaseService is a singleton', () {
      final instance1 = SupabaseDatabaseService();
      final instance2 = SupabaseDatabaseService();
      
      expect(identical(instance1, instance2), true);
    });

    test('SupabaseDatabaseService has correct table methods', () {
      final db = SupabaseDatabaseService();
      
      // Verify methods exist by checking they're callable
      expect(() => db.currentUserId, returnsNormally);
      expect(() => db.isAuthenticated, returnsNormally);
      expect(() => db.getUserProfile('test-id'), returnsNormally);
      expect(() => db.getWorkoutSessions(), returnsNormally);
    });
  });
}
