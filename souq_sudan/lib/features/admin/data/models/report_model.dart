import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/report_entity.dart';
import '../../../../core/enums/app_enums.dart';

class ReportModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reportedItemId;
  final String type;
  final String reason;
  final String? adminNote;
  final bool isResolved;
  final String? resolvedBy;
  final Timestamp createdAt;
  final Timestamp? resolvedAt;

  const ReportModel({
    required this.id, required this.reporterId, required this.reporterName,
    required this.reportedItemId, required this.type, required this.reason,
    this.adminNote, this.isResolved = false, this.resolvedBy,
    required this.createdAt, this.resolvedAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      id: id,
      reporterId: (map['reporterId'] as String?) ?? '',
      reporterName: (map['reporterName'] as String?) ?? '',
      reportedItemId: (map['reportedItemId'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'ad',
      reason: (map['reason'] as String?) ?? '',
      adminNote: map['adminNote'] as String?,
      isResolved: (map['isResolved'] as bool?) ?? false,
      resolvedBy: map['resolvedBy'] as String?,
      createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
      resolvedAt: map['resolvedAt'] as Timestamp?,
    );
  }

  factory ReportModel.fromDocument(DocumentSnapshot doc) =>
      ReportModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Report toEntity() {
    return Report(
      id: id, reporterId: reporterId, reporterName: reporterName,
      reportedItemId: reportedItemId,
      type: ReportTypeExtension.fromString(type),
      reason: reason, adminNote: adminNote, isResolved: isResolved,
      resolvedBy: resolvedBy, createdAt: createdAt.toDate(),
      resolvedAt: resolvedAt?.toDate(),
    );
  }
}
