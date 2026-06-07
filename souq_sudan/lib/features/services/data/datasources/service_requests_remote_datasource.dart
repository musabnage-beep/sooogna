import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/service_request_model.dart';

class ServiceRequestsRemoteDataSource {
  final FirebaseFirestore _firestore;

  ServiceRequestsRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.serviceRequestsCollection);

  CollectionReference<Map<String, dynamic>> _responses(String requestId) =>
      _col.doc(requestId).collection(AppConstants.serviceResponsesSubcollection);

  /// Open requests, optionally filtered by city/category, newest first.
  Future<List<ServiceRequestModel>> getRequests({
    String? city,
    String? category,
    Timestamp? afterCreatedAt,
    int limit = AppConstants.requestsPageSize,
  }) async {
    Query<Map<String, dynamic>> q = _col.where('status', isEqualTo: 'open');
    if (city != null && city.isNotEmpty) {
      q = q.where('city', isEqualTo: city);
    }
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    q = q.orderBy('createdAt', descending: true);
    if (afterCreatedAt != null) q = q.startAfter([afterCreatedAt]);
    final snap = await q.limit(limit).get();
    return snap.docs.map((d) => ServiceRequestModel.fromDocument(d)).toList();
  }

  Future<ServiceRequestModel?> getRequestById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ServiceRequestModel.fromDocument(doc);
  }

  Stream<List<ServiceRequestModel>> watchMyRequests(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ServiceRequestModel.fromDocument(d)).toList());
  }

  Future<String> createRequest(ServiceRequestModel model) async {
    final ref = await _col.add(model.toMap()
      ..['createdAt'] = FieldValue.serverTimestamp());
    return ref.id;
  }

  Future<void> setStatus(String requestId, String status) async {
    await _col.doc(requestId).update({'status': status});
  }

  Stream<List<ServiceResponseModel>> watchResponses(String requestId) {
    return _responses(requestId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ServiceResponseModel.fromDocument(d)).toList());
  }

  /// Add a provider response and bump the parent request's responseCount (+1).
  Future<void> addResponse(String requestId, ServiceResponseModel response) async {
    final batch = _firestore.batch();
    final respRef = _responses(requestId).doc();
    batch.set(respRef, response.toMap()
      ..['createdAt'] = FieldValue.serverTimestamp());
    batch.update(_col.doc(requestId), {
      'responseCount': FieldValue.increment(1),
    });
    await batch.commit();
  }
}
