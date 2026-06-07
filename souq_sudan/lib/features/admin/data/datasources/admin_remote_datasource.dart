import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/report_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../ads/data/models/ad_model.dart';
import '../../../../core/constants/app_constants.dart';

class AdminRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AdminRemoteDataSource({required FirebaseFirestore firestore, required FirebaseStorage storage})
      : _firestore = firestore, _storage = storage;

  Future<Map<String, int>> getDashboardStats() async {
    final results = await Future.wait([
      _firestore.collection('users').count().get(),
      _firestore.collection('ads').count().get(),
      _firestore.collection('ads').where('status', isEqualTo: 'active').count().get(),
      _firestore.collection('ads').where('status', isEqualTo: 'pending').count().get(),
      _firestore.collection('reports').where('isResolved', isEqualTo: false).count().get(),
    ]);

    final midnight = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    final todaySnap = await _firestore.collection('ads')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(midnight))
        .count()
        .get();

    return {
      'totalUsers': results[0].count ?? 0,
      'totalAds': results[1].count ?? 0,
      'activeAds': results[2].count ?? 0,
      'pendingAds': results[3].count ?? 0,
      'unresolvedReports': results[4].count ?? 0,
      'adsPostedToday': todaySnap.count ?? 0,
    };
  }

  Future<List<UserModel>> getAllUsers({DocumentSnapshot? lastDoc, int limit = 20}) async {
    Query query = _firestore.collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (lastDoc != null) query = query.startAfterDocument(lastDoc);
    final snap = await query.get();
    return snap.docs.map((d) => UserModel.fromDocument(d)).toList();
  }

  Future<void> banUser(String userId, String reason) async {
    await _firestore.collection('users').doc(userId).update({
      'isBanned': true,
      'banReason': reason,
    });
  }

  Future<void> unbanUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isBanned': false,
      'banReason': null,
    });
  }

  Future<void> verifyUser(String userId, bool isVerified) async {
    await _firestore.collection('users').doc(userId).update({'isVerified': isVerified});
  }

  Future<void> setUserRole(String userId, String role) async {
    await _firestore.collection('users').doc(userId).update({'role': role});
  }

  Future<void> deleteUserWithContent(String userId) async {
    final refs = <DocumentReference>[];

    final ads = await _firestore
        .collection('ads')
        .where('userId', isEqualTo: userId)
        .limit(AppConstants.maxDeleteScan)
        .get();
    for (final doc in ads.docs) {
      refs.add(doc.reference);
      try {
        final storageRef = _storage.ref('ad_images/${doc.id}');
        final items = await storageRef.listAll();
        for (final item in items.items) {
          await item.delete();
        }
      } catch (_) {}
    }

    final reviews = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .limit(AppConstants.maxDeleteScan)
        .get();
    refs.addAll(reviews.docs.map((d) => d.reference));

    final chats = await _firestore
        .collection('chats')
        .where('userIds', arrayContains: userId)
        .limit(AppConstants.maxDeleteScan)
        .get();
    refs.addAll(chats.docs.map((d) => d.reference));

    refs.add(_firestore.collection('users').doc(userId));

    const chunkSize = 450;
    for (var i = 0; i < refs.length; i += chunkSize) {
      final batch = _firestore.batch();
      for (final ref in refs.skip(i).take(chunkSize)) {
        batch.delete(ref);
      }
      await batch.commit();
    }

    try { await _storage.ref('profile_images/$userId').delete(); } catch (_) {}
  }

  Future<List<AdModel>> getAdsByStatus(String status, {DocumentSnapshot? lastDoc, int limit = 20}) async {
    Query query = _firestore.collection('ads')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (lastDoc != null) query = query.startAfterDocument(lastDoc);
    final snap = await query.get();
    return snap.docs.map((d) => AdModel.fromDocument(d)).toList();
  }

  Future<void> approveAd(String adId) async {
    await _firestore.collection('ads').doc(adId).update({
      'status': 'active',
      'rejectionReason': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectAd(String adId, String reason) async {
    await _firestore.collection('ads').doc(adId).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAdAdmin(String adId) async {
    try {
      final storageRef = _storage.ref('ad_images/$adId');
      final items = await storageRef.listAll();
      for (final item in items.items) {
        await item.delete();
      }
    } catch (_) {}
    await _firestore.collection('ads').doc(adId).delete();
  }

  Future<void> featureAd(String adId, bool isFeatured) async {
    await _firestore.collection('ads').doc(adId).update({'isFeatured': isFeatured});
  }

  Future<List<ReportModel>> getReports({bool? isResolved, DocumentSnapshot? lastDoc, int limit = 20}) async {
    Query query = _firestore.collection('reports').orderBy('createdAt', descending: true);
    if (isResolved != null) query = query.where('isResolved', isEqualTo: isResolved);
    query = query.limit(limit);
    if (lastDoc != null) query = query.startAfterDocument(lastDoc);
    final snap = await query.get();
    return snap.docs.map((d) => ReportModel.fromDocument(d)).toList();
  }

  Future<void> resolveReport(String reportId, String adminId, String adminNote) async {
    await _firestore.collection('reports').doc(reportId).update({
      'isResolved': true,
      'resolvedBy': adminId,
      'adminNote': adminNote,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
