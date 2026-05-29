import '../../../../core/enums/app_enums.dart';

class Report {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reportedItemId;
  final ReportType type;
  final String reason;
  final String? adminNote;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reportedItemId,
    required this.type,
    required this.reason,
    this.adminNote,
    this.isResolved = false,
    this.resolvedBy,
    required this.createdAt,
    this.resolvedAt,
  });
}
