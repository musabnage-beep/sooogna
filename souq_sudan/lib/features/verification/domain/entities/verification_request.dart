import '../../../../core/enums/app_enums.dart';

class VerificationRequest {
  final String userId;
  final String userName;
  final String? idImageUrl;
  final VerifiedStatus requestedStatus;
  final VerificationRequestStatus status;
  final String? adminNote;
  final DateTime createdAt;

  const VerificationRequest({
    required this.userId,
    required this.userName,
    this.idImageUrl,
    this.requestedStatus = VerifiedStatus.verified,
    this.status = VerificationRequestStatus.pending,
    this.adminNote,
    required this.createdAt,
  });
}
