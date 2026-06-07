import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/analytics_summary.dart';

class AnalyticsSummaryModel {
  static AnalyticsSummary fromMap(Map<String, dynamic> map) {
    return AnalyticsSummary(
      totalViews: (map['totalViews'] as num?)?.toInt() ?? 0,
      totalContacts: (map['totalContacts'] as num?)?.toInt() ?? 0,
      totalSaved: (map['totalSaved'] as num?)?.toInt() ?? 0,
      profileVisits: (map['profileVisits'] as num?)?.toInt() ?? 0,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static AnalyticsSummary fromDocument(DocumentSnapshot doc) {
    if (!doc.exists) return AnalyticsSummary.empty;
    return fromMap(doc.data() as Map<String, dynamic>);
  }
}
