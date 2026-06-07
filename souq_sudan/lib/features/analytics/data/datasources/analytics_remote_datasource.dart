import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/analytics_summary.dart';
import '../models/analytics_summary_model.dart';

/// Reads and increments the per-user analytics summary doc at
/// `users/{uid}/analytics/summary`. Counters are bumped with
/// `FieldValue.increment` so concurrent buyer actions stay correct without a
/// server (Firebase Spark constraint).
class AnalyticsRemoteDataSource {
  final FirebaseFirestore _firestore;

  AnalyticsRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  DocumentReference<Map<String, dynamic>> _summaryRef(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.analyticsSubcollection)
          .doc(AppConstants.analyticsSummaryDoc);

  Stream<AnalyticsSummary> watchSummary(String userId) {
    return _summaryRef(userId)
        .snapshots()
        .map(AnalyticsSummaryModel.fromDocument);
  }

  Future<AnalyticsSummary> getSummary(String userId) async {
    final doc = await _summaryRef(userId).get();
    return AnalyticsSummaryModel.fromDocument(doc);
  }

  /// Increment one counter field on the target user's summary. Best-effort:
  /// callers should not block UX on the result.
  Future<void> bump(String userId, String field) async {
    await _summaryRef(userId).set({
      field: FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
