import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/verification_request.dart';
import '../../../../core/enums/app_enums.dart';

class VerificationRequestModel {
  final String userId;
  final String userName;
  final String? idImageUrl;
  final String requestedStatus;
  final String status;
  final String? adminNote;
  final Timestamp createdAt;

  const VerificationRequestModel({
    required this.userId,
    required this.userName,
    this.idImageUrl,
    this.requestedStatus = 'verified',
    this.status = 'pending',
    this.adminNote,
    required this.createdAt,
  });

  factory VerificationRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return VerificationRequestModel(
      userId: (map['userId'] as String?) ?? id,
      userName: (map['userName'] as String?) ?? '',
      idImageUrl: map['idImageUrl'] as String?,
      requestedStatus: (map['requestedStatus'] as String?) ?? 'verified',
      status: (map['status'] as String?) ?? 'pending',
      adminNote: map['adminNote'] as String?,
      createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  factory VerificationRequestModel.fromDocument(DocumentSnapshot doc) {
    return VerificationRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'idImageUrl': idImageUrl,
      'requestedStatus': requestedStatus,
      'status': status,
      'adminNote': adminNote,
      'createdAt': createdAt,
    };
  }

  VerificationRequest toEntity() {
    return VerificationRequest(
      userId: userId,
      userName: userName,
      idImageUrl: idImageUrl,
      requestedStatus: VerifiedStatusExtension.fromString(requestedStatus),
      status: VerificationRequestStatusExtension.fromString(status),
      adminNote: adminNote,
      createdAt: createdAt.toDate(),
    );
  }
}
