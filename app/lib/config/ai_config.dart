import 'package:flutter/foundation.dart';

/// Centralized AI Configuration
/// Contains Gemini API key and model configuration for all AI services
class AIConfig {
  // Gemini 2.5 Flash API Key - Use this for all AI tasks
  // In production, use environment variables: String.fromEnvironment('GEMINI_API_KEY')
  static const String geminiApiKey = kDebugMode
      ? 'AIzaSyAp1gkplk30KQOPGenhjzcVnm_YQvz3Wyk' // Development key
      : String.fromEnvironment(
          'GEMINI_API_KEY',
          defaultValue: 'AIzaSyAp1gkplk30KQOPGenhjzcVnm_YQvz3Wyk',
        );

  // Model configuration
  static const String geminiModel = 'gemini-2.0-flash-exp';

  // API configuration
  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 1);
  static const int maxTokens = 8192;
  static const double temperature = 0.7;

  // Prevent instantiation
  AIConfig._();

  /// Check if using development API key
  static bool get isUsingDevKey =>
      geminiApiKey == 'AIzaSyAp1gkplk30KQOPGenhjzcVnm_YQvz3Wyk';
}
