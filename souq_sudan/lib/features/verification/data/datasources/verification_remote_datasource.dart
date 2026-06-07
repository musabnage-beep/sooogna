import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/verification_request_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/image_compressor.dart';

class VerificationRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  VerificationRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.verificationRequestsCollection);

  /// Submit (or re-submit) an identity verification request for the current
  /// user. Optionally uploads an ID document image to private storage.
  Future<void> submitRequest({
    required String userId,
    required String userName,
    required String requestedStatus,
    String? idImagePath,
  }) async {
    String? idImageUrl;
    if (idImagePath != null) {
      final file = File(idImagePath);
      final compressed =
          await ImageCompressor.compressToMaxSize(file, AppConstants.maxImageSizeBytes);
      final ref = _storage.ref('verification/$userId/id.jpg');
      await ref.putFile(compressed);
      idImageUrl = await ref.getDownloadURL();
      await ImageCompressor.deleteIfTemp(compressed);
    }

    final data = <String, dynamic>{
      'userId': userId,
      'userName': userName,
      'requestedStatus': requestedStatus,
      'status': 'pending',
      'adminNote': null,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (idImageUrl != null) data['idImageUrl'] = idImageUrl;

    // Deterministic doc id == userId -> at most one request per user.
    await _col.doc(userId).set(data, SetOptions(merge: true));
  }

  Stream<VerificationRequestModel?> watchMyRequest(String userId) {
    return _col.doc(userId).snapshots().map(
          (doc) => doc.exists ? VerificationRequestModel.fromDocument(doc) : null,
        );
  }

  /// Admin: pending verification requests, newest first.
  Stream<List<VerificationRequestModel>> watchPending() {
    return _col
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => VerificationRequestModel.fromDocument(d)).toList());
  }

  /// Admin: approve a request -> set the user's badge + close the request.
  Future<void> approve({
    required String userId,
    required String grantedStatus,
    String? adminNote,
  }) async {
    final batch = _firestore.batch();
    batch.update(
      _firestore.collection(AppConstants.usersCollection).doc(userId),
      {'verifiedStatus': grantedStatus, 'isVerified': true},
    );
    batch.update(_col.doc(userId), {
      'status': 'approved',
      'adminNote': adminNote,
    });
    await batch.commit();
  }

  /// Admin: reject a request (badge unchanged).
  Future<void> reject({required String userId, String? adminNote}) async {
    await _col.doc(userId).update({
      'status': 'rejected',
      'adminNote': adminNote,
    });
  }
}
