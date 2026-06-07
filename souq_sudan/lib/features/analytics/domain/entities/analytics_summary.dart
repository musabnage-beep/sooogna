/// Aggregated seller metrics stored at `users/{uid}/analytics/summary`.
/// All counters are maintained client-side via `FieldValue.increment` under
/// the Firebase Spark plan (no Cloud Functions).
class AnalyticsSummary {
  final int totalViews;
  final int totalContacts;
  final int totalSaved;
  final int profileVisits;
  final DateTime? updatedAt;

  const AnalyticsSummary({
    this.totalViews = 0,
    this.totalContacts = 0,
    this.totalSaved = 0,
    this.profileVisits = 0,
    this.updatedAt,
  });

  static const empty = AnalyticsSummary();
}
