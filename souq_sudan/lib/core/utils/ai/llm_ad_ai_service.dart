import 'dart:convert';

import 'ad_ai_service.dart';

/// Signature of a backend proxy that returns a raw completion string for a
/// prompt. This is intentionally injectable: the web bundle must NEVER hold an
/// LLM API key, so a Blaze Cloud Function / server proxy supplies this function
/// in production. When null, the service is considered disabled.
typedef LlmCompletionFn = Future<String> Function(String prompt);

/// Real-LLM ad assistant. **Disabled by default** — pass a non-null
/// [completionFn] (and [enabled] = true) only once a server-side proxy exists.
/// Every failure path degrades gracefully to [fallback].
class LlmAdAiService implements AdAiService {
  final AdAiService fallback;
  final LlmCompletionFn? completionFn;
  final bool enabled;

  const LlmAdAiService({
    required this.fallback,
    this.completionFn,
    this.enabled = false,
  });

  @override
  bool get isAvailable => true; // always — falls back to heuristic.

  bool get _llmActive => enabled && completionFn != null;

  @override
  Future<AdAiSuggestion> suggest({
    required String title,
    required String description,
    double? price,
    String? city,
  }) async {
    if (!_llmActive) {
      return fallback.suggest(
        title: title,
        description: description,
        price: price,
        city: city,
      );
    }
    try {
      final prompt = _buildPrompt(title, description, price, city);
      final raw = await completionFn!(prompt);
      final parsed = _parse(raw);
      if (parsed != null && !parsed.isEmpty) return parsed;
    } catch (_) {
      // fall through to heuristic
    }
    return fallback.suggest(
      title: title,
      description: description,
      price: price,
      city: city,
    );
  }

  String _buildPrompt(
      String title, String description, double? price, String? city) {
    return 'أنت مساعد لكتابة إعلانات سوق سوداني. أعد فقط JSON بالحقول '
        '{"title","description","categoryId"} حيث categoryId إحدى: '
        'cars, real_estate, mobiles, electronics, jobs, services, livestock, '
        'furniture, clothes, other.\n'
        'العنوان: $title\nالوصف: $description\n'
        'السعر: ${price ?? ''}\nالمدينة: ${city ?? ''}';
  }

  AdAiSuggestion? _parse(String raw) {
    try {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start < 0 || end <= start) return null;
      final map = jsonDecode(raw.substring(start, end + 1))
          as Map<String, dynamic>;
      String? str(String k) {
        final v = map[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
        return null;
      }

      return AdAiSuggestion(
        title: str('title'),
        description: str('description'),
        categoryId: str('categoryId'),
      );
    } catch (_) {
      return null;
    }
  }
}
