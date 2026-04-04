import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase Configuration
/// Contains Supabase URL and anon key for all backend services
class SupabaseConfig {
  // Prevent instantiation
  SupabaseConfig._();

  /// Initialize Supabase
  static Future<void> initialize() async {
    // Load environment variables from .env file
    await dotenv.load();

    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception(
        'Missing Supabase configuration. Please check your .env file '
        'has SUPABASE_URL and SUPABASE_ANON_KEY set.',
      );
    }

    await Supabase.initialize(url: url, anonKey: anonKey, debug: kDebugMode);
  }

  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get current user
  static User? get currentUser => Supabase.instance.client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get current user ID
  static String? get userId => currentUser?.id;

  /// Check if using development keys
  static bool get isUsingDevKeys {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    return url.isEmpty ||
        anonKey.isEmpty ||
        url == 'YOUR_SUPABASE_URL' ||
        anonKey == 'YOUR_SUPABASE_ANON_KEY';
  }
}
