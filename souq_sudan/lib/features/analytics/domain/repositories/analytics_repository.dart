import '../entities/analytics_summary.dart';

abstract class AnalyticsRepository {
  Stream<AnalyticsSummary> watchSummary(String userId);

  /// Fire-and-forget counter increment. Implementations swallow errors so a
  /// failed analytics write never breaks the buyer flow that triggered it.
  Future<void> bumpViews(String sellerId);
  Future<void> bumpContacts(String sellerId);
  Future<void> bumpSaved(String sellerId);
  Future<void> bumpProfileVisits(String userId);
}
