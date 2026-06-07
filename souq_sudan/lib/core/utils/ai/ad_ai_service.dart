/// Feature 11 — AI-assisted ad creation.
///
/// `AdAiService` is a thin provider interface so the UI never depends on a
/// concrete AI backend. Two implementations exist:
///  * [HeuristicAdAiService] — fully offline, deterministic, always available.
///  * [LlmAdAiService] — wraps a real LLM via an injected completion function,
///    and is **disabled by default**. It always degrades to the heuristic
///    result when the LLM is off, unconfigured, or fails. No API keys ever
///    ship in the web bundle; a Blaze backend proxy must supply completions.
library;

/// Suggestions produced for a draft ad. Any field may be null when the service
/// has nothing useful to offer (the UI then leaves the user's input untouched).
class AdAiSuggestion {
  /// A cleaned-up version of the title (trimmed, de-duplicated whitespace).
  final String? title;

  /// A generated or improved description.
  final String? description;

  /// The best-matching category id (must be one of `AppConstants.categories`).
  final String? categoryId;

  const AdAiSuggestion({this.title, this.description, this.categoryId});

  bool get isEmpty => title == null && description == null && categoryId == null;
}

abstract class AdAiService {
  /// Whether suggestions can be produced at all (always true for heuristic).
  bool get isAvailable;

  Future<AdAiSuggestion> suggest({
    required String title,
    required String description,
    double? price,
    String? city,
  });
}
