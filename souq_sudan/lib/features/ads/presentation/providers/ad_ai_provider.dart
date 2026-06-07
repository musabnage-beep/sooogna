import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/ai/ad_ai_service.dart';
import '../../../../core/utils/ai/heuristic_ad_ai_service.dart';
import '../../../../core/utils/ai/llm_ad_ai_service.dart';

/// The active ad-assist service. Defaults to the LLM wrapper with the LLM path
/// **disabled**, so it transparently uses the offline heuristic until a
/// server-side proxy supplies a [LlmCompletionFn]. To enable a real model
/// later, inject `completionFn` + `enabled: true` here (never embed keys).
final adAiServiceProvider = Provider<AdAiService>((ref) {
  return const LlmAdAiService(
    fallback: HeuristicAdAiService(),
    enabled: false,
  );
});
