import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

const _apiKeyStorageKey = 'gemini_api_key';

/// AI service wrapping Google Gemini.
///
/// Uses BYOK (Bring Your Own Key) pattern — the user stores their Gemini API
/// key in secure storage. If no key is present, all AI features degrade
/// gracefully with no errors shown to the user.
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  static const _storage = FlutterSecureStorage();

  GenerativeModel? _model;
  bool _hasKey = false;

  bool get isAvailable => _hasKey && _model != null;

  /// Load key from secure storage and init Gemini client. Call once at startup.
  Future<void> initialize() async {
    try {
      final key = await _storage.read(key: _apiKeyStorageKey);
      if (key != null && key.isNotEmpty) {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: key,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 2048,
          ),
        );
        _hasKey = true;
        debugPrint('AiService: Gemini initialized with user-provided key');
      } else {
        _hasKey = false;
        debugPrint('AiService: No API key found — AI features disabled');
      }
    } catch (e) {
      _hasKey = false;
      debugPrint('AiService.initialize error: $e');
    }
  }

  /// Save a new API key and re-initialize the Gemini client.
  Future<bool> saveApiKey(String apiKey) async {
    try {
      await _storage.write(key: _apiKeyStorageKey, value: apiKey.trim());
      await initialize();
      return _hasKey;
    } catch (e) {
      debugPrint('AiService.saveApiKey error: $e');
      return false;
    }
  }

  /// Check whether a key is saved (without exposing the key value).
  Future<bool> hasApiKey() async {
    try {
      final key = await _storage.read(key: _apiKeyStorageKey);
      return key != null && key.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Clear the stored API key and disable AI features.
  Future<void> removeApiKey() async {
    try {
      await _storage.delete(key: _apiKeyStorageKey);
      _model = null;
      _hasKey = false;
    } catch (e) {
      debugPrint('AiService.removeApiKey error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Prompt templates
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates a financial health summary given spending context.
  Future<String?> generateFinancialInsight({
    required double totalIncome,
    required double totalExpenses,
    required Map<String, double> categoryBreakdown,
    String language = 'id',
  }) async {
    if (!isAvailable) return null;
    try {
      final langInstruction = language == 'id'
          ? 'Respond in Bahasa Indonesia. Be concise, warm, and actionable.'
          : 'Respond in English. Be concise, warm, and actionable.';

      final categories = categoryBreakdown.entries
          .map((e) => '- ${e.key}: Rp ${e.value.toStringAsFixed(0)}')
          .join('\n');

      final prompt = '''
$langInstruction

You are a personal finance assistant embedded in a finance app. Analyze the following data and give a 2–3 sentence insight with one actionable tip.

Income this month: Rp ${totalIncome.toStringAsFixed(0)}
Expenses this month: Rp ${totalExpenses.toStringAsFixed(0)}
Net: Rp ${(totalIncome - totalExpenses).toStringAsFixed(0)}

Top spending categories:
$categories

Keep the response under 100 words. Do not use markdown headers. Use a friendly, encouraging tone.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      debugPrint('AiService.generateFinancialInsight error: $e');
      return null;
    }
  }

  /// Generates a daily productivity coaching message.
  Future<String?> generateDailyCoaching({
    required int completedHabits,
    required int totalHabits,
    required int completedTasks,
    required int pendingTasks,
    String language = 'id',
  }) async {
    if (!isAvailable) return null;
    try {
      final langInstruction = language == 'id'
          ? 'Respond in Bahasa Indonesia. Be brief, motivational, and specific.'
          : 'Respond in English. Be brief, motivational, and specific.';

      final prompt = '''
$langInstruction

You are a personal productivity coach. Give a 1–2 sentence motivational insight based on the user's progress today. Max 60 words.

Habits: $completedHabits out of $totalHabits completed.
Tasks: $completedTasks done, $pendingTasks pending.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      debugPrint('AiService.generateDailyCoaching error: $e');
      return null;
    }
  }

  /// Multi-turn chat for the AI assistant feature.
  Future<String?> chat({
    required List<({String role, String text})> history,
    required String userMessage,
    String language = 'id',
  }) async {
    if (!isAvailable) return null;
    try {
      final systemPrompt = language == 'id'
          ? 'Kamu adalah asisten pribadi dalam aplikasi Life OS. Bantu pengguna dengan keuangan, produktivitas, dan kesehatan. Jawab dengan singkat dan ramah dalam Bahasa Indonesia.'
          : 'You are a personal assistant inside the Life OS app. Help users with finance, productivity, and wellness. Be concise and friendly in English.';

      final contents = <Content>[
        Content.text(systemPrompt),
        ...history.map((h) => h.role == 'user'
            ? Content.text(h.text)
            : Content.model([TextPart(h.text)])),
        Content.text(userMessage),
      ];

      final response = await _model!.generateContent(contents);
      return response.text;
    } catch (e) {
      debugPrint('AiService.chat error: $e');
      return null;
    }
  }
}
