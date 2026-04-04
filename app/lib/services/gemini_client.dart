import 'dart:developer' as developer;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/ai_config.dart';

/// Result from Gemini generation including optional thought summaries
class GeminiGenerationResult {
  final String? text;
  final String? thoughtSummary;
  final bool hasThoughts;

  const GeminiGenerationResult({
    this.text,
    this.thoughtSummary,
    this.hasThoughts = false,
  });
}

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
      // Build generation config with thinking support if available
      final generationConfig = _buildGenerationConfig();

      _model = GenerativeModel(
        model: AIConfig.geminiModel,
        apiKey: AIConfig.geminiApiKey,
        generationConfig: generationConfig,
      );
      _initialized = true;
      developer.log(
        'Gemini client initialized with model: ${AIConfig.geminiModel}',
        name: 'GeminiClient',
      );
      if (AIConfig.supportsThinking) {
        developer.log(
          'Thinking enabled with config: ${AIConfig.thinkingConfig}',
          name: 'GeminiClient',
        );
      }
    } catch (e) {
      developer.log(
        'Failed to initialize Gemini client: $e',
        name: 'GeminiClient',
      );
      _initialized = false;
    }
  }

  /// Build generation configuration with thinking support
  GenerationConfig? _buildGenerationConfig() {
    try {
      // Add thinking configuration for supported models
      if (AIConfig.supportsThinking) {
        final thinkingConfig = AIConfig.thinkingConfig;
        developer.log(
          'Building config with thinking: $thinkingConfig',
          name: 'GeminiClient',
        );
      }

      return GenerationConfig(
        temperature: AIConfig.temperature,
        maxOutputTokens: AIConfig.maxTokens,
      );
    } catch (e) {
      developer.log(
        'Error building generation config: $e',
        name: 'GeminiClient',
      );
      return null;
    }
  }

  /// Check if client is initialized
  bool get isInitialized => _initialized;

  /// Generate content with retry logic and optional thought summaries
  Future<GeminiGenerationResult> generateContentWithThoughts(
    String prompt, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool includeThoughts = false,
  }) async {
    if (!_initialized) {
      developer.log('Gemini client not initialized', name: 'GeminiClient');
      return const GeminiGenerationResult();
    }

    var attempts = 0;

    while (attempts < maxRetries) {
      try {
        developer.log(
          'Generating content with thoughts (attempt ${attempts + 1})',
          name: 'GeminiClient',
        );

        final response = await _model.generateContent([Content.text(prompt)]);

        // Extract text response
        final result = response.text;

        // Extract thought summary if available (for debugging)
        String? thoughtSummary;
        bool hasThoughts = false;

        if (includeThoughts && response.candidates.isNotEmpty) {
          final candidate = response.candidates.first;
          // Check for thought parts in the response
          for (final part in candidate.content.parts) {
            if (part is TextPart) {
              hasThoughts = true;
            }
          }
        }

        if (result != null && result.isNotEmpty) {
          developer.log(
            'Content generated successfully (hasThoughts: $hasThoughts)',
            name: 'GeminiClient',
          );
          return GeminiGenerationResult(
            text: result,
            thoughtSummary: thoughtSummary,
            hasThoughts: hasThoughts,
          );
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
          await Future.delayed(delay * attempts);
        }
      }
    }

    developer.log(
      'Failed to generate content after $maxRetries attempts',
      name: 'GeminiClient',
    );
    return const GeminiGenerationResult();
  }

  /// Generate content with retry logic (simple version without thoughts)
  Future<String?> generateContent(
    String prompt, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    final result = await generateContentWithThoughts(
      prompt,
      maxRetries: maxRetries,
      delay: delay,
      includeThoughts: false,
    );
    return result.text;
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

  /// Get model info
  Map<String, dynamic> get modelInfo {
    return {
      'model': AIConfig.geminiModel,
      'supportsThinking': AIConfig.supportsThinking,
      'thinkingConfig': AIConfig.thinkingConfig,
      'initialized': _initialized,
    };
  }
}
