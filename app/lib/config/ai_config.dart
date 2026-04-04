import 'package:flutter/foundation.dart';

/// Centralized AI Configuration
/// Contains Gemini API key and model configuration for all AI services
/// Supports thinking models (Gemini 2.5 and 3.x series)
class AIConfig {
  // Gemini API Key - Use this for all AI tasks
  // In production, use environment variables: String.fromEnvironment('GEMINI_API_KEY')
  static const String geminiApiKey = kDebugMode
      ? 'AIzaSyAp1gkplk30KQOPGenhjzcVnm_YQvz3Wyk' // Development key
      : String.fromEnvironment(
          'GEMINI_API_KEY',
          defaultValue: 'AIzaSyAp1gkplk30KQOPGenhjzcVnm_YQvz3Wyk',
        );

  // Model configuration - Use thinking models for better reasoning
  // Available models:
  // - gemini-2.5-flash (dynamic thinking by default, supports thinkingBudget)
  // - gemini-2.5-flash-preview (dynamic thinking by default)
  // - gemini-3-flash-preview (supports thinkingLevel)
  // - gemini-3.1-flash-lite (minimal thinking by default)
  static const String geminiModel = 'gemini-2.5-flash-preview';

  // API configuration
  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 1);
  static const int maxTokens = 8192;
  static const double temperature = 0.7;

  // Thinking configuration for Gemini 2.5 models (using thinkingBudget)
  // -1 = Dynamic thinking (default)
  // 0 = Disable thinking
  // 128 to 24576 = Specific token budget for reasoning
  // For training plans, we want some reasoning but not too much latency
  static const int thinkingBudget = 1024;

  // Enable thought summaries to see model's reasoning
  static const bool includeThoughts = false; // Set to true for debugging

  // Prevent instantiation
  AIConfig._();

  /// Check if using development API key
  static bool get isUsingDevKey =>
      geminiApiKey == 'AIzaSyAp1gkplk30KQOPGenhjzcVnm_YQvz3Wyk';

  /// Check if current model supports thinking
  static bool get supportsThinking {
    return geminiModel.contains('2.5') || geminiModel.contains('3');
  }

  /// Get thinking configuration
  static Map<String, dynamic> get thinkingConfig {
    if (!supportsThinking) return {};

    if (geminiModel.contains('2.5')) {
      // Gemini 2.5 uses thinkingBudget
      return {'thinkingBudget': thinkingBudget};
    } else if (geminiModel.contains('3')) {
      // Gemini 3.x uses thinkingLevel
      return {
        'thinkingLevel': 'medium', // low, medium, high
      };
    }

    return {};
  }
}
