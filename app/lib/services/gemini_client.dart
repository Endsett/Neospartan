import 'dart:developer' as developer;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/ai_config.dart';

/// Centralized Gemini Client
/// Handles all Gemini API interactions with retry logic and error handling
class GeminiClient {
  static final GeminiClient _instance = GeminiClient._internal();
  factory GeminiClient() => _instance;
  GeminiClient._internal();

  late GenerativeModel _model;
  bool _initialized = false;

  /// Initialize the Gemini client
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _model = GenerativeModel(
        model: AIConfig.geminiModel,
        apiKey: AIConfig.geminiApiKey,
      );
      _initialized = true;
      developer.log('Gemini client initialized', name: 'GeminiClient');
    } catch (e) {
      developer.log(
        'Failed to initialize Gemini client: $e',
        name: 'GeminiClient',
      );
      _initialized = false;
    }
  }

  /// Check if client is initialized
  bool get isInitialized => _initialized;

  /// Generate content with retry logic
  Future<String?> generateContent(
    String prompt, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    if (!_initialized) {
      developer.log('Gemini client not initialized', name: 'GeminiClient');
      return null;
    }

    var attempts = 0;

    while (attempts < maxRetries) {
      try {
        developer.log(
          'Generating content (attempt ${attempts + 1})',
          name: 'GeminiClient',
        );

        final response = await _model.generateContent([Content.text(prompt)]);
        final result = response.text;

        if (result != null && result.isNotEmpty) {
          developer.log('Content generated successfully', name: 'GeminiClient');
          return result;
        }

        developer.log('Empty response from Gemini', name: 'GeminiClient');
      } catch (e) {
        attempts++;
        developer.log(
          'Error generating content (attempt $attempts): $e',
          name: 'GeminiClient',
          error: e,
        );

        if (attempts < maxRetries) {
          // Exponential backoff
          await Future.delayed(delay * attempts);
        }
      }
    }

    developer.log(
      'Failed to generate content after $maxRetries attempts',
      name: 'GeminiClient',
    );
    return null;
  }

  /// Generate content with streaming response
  Stream<String> generateContentStream(String prompt) async* {
    if (!_initialized) {
      developer.log('Gemini client not initialized', name: 'GeminiClient');
      return;
    }

    try {
      developer.log('Starting content stream', name: 'GeminiClient');

      final response = await _model.generateContentStream([
        Content.text(prompt),
      ]);

      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null) {
          yield text;
        }
      }

      developer.log('Content stream completed', name: 'GeminiClient');
    } catch (e) {
      developer.log(
        'Error in content stream: $e',
        name: 'GeminiClient',
        error: e,
      );
      rethrow;
    }
  }

  /// Count tokens in a prompt
  Future<int> countTokens(String prompt) async {
    if (!_initialized) return 0;

    try {
      final response = await _model.countTokens([Content.text(prompt)]);
      return response.totalTokens;
    } catch (e) {
      developer.log('Error counting tokens: $e', name: 'GeminiClient');
      return prompt.length ~/ 4; // Rough estimate
    }
  }

  /// Check if content is safe
  Future<bool> isContentSafe(String content) async {
    if (!_initialized) return true;

    try {
      final response = await _model.generateContent([
        Content.text(
          'Is this content safe for fitness advice? Answer with only "yes" or "no": $content',
        ),
      ]);

      final result = response.text?.toLowerCase().trim();
      return result == 'yes';
    } catch (e) {
      developer.log('Error checking content safety: $e', name: 'GeminiClient');
      return true; // Default to safe if check fails
    }
  }
}
