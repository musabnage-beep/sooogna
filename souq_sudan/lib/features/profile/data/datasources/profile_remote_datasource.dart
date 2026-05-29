import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/review_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../../core/constants/app_constants.dart';

class ProfileRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProfileRemoteDataSource({required FirebaseFirestore firestore, required FirebaseStorage storage})
      : _firestore = firestore, _storage = storage;

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromDocument(doc);
  }

  Future<void> updateProfile(String userId, {String? name, String? profileImagePath}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (profileImagePath != null) {
      final file = File(profileImagePath);
      final compressed = await ImageCompressor.compressToMaxSize(file, AppConstants.maxImageSizeBytes);
      final ref = _storage.ref('profile_images/$userId');
      await ref.putFile(compressed);
      final url = await ref.getDownloadURL();
      updates['profileImage'] = url;
    }
    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update(updates);
    }
  }

  Future<void> submitReview(ReviewModel review) async {
    final reviewRef = _firestore.collection('reviews').doc();
    await _firestore.runTransaction((tx) async {
      final userDoc = await tx.get(_firestore.collection('users').doc(review.userId));
      if (!userDoc.exists) return;
      final data = userDoc.data()!;
      final oldRating = ((data['rating'] as num?) ?? 0).toDouble();
      final oldCount = (data['ratingCount'] as int?) ?? 0;
      final newCount = oldCount + 1;
      final newRating = ((oldRating * oldCount) + review.rating) / newCount;
      tx.set(reviewRef, {...review.toMap(), 'createdAt': FieldValue.serverTimestamp()});
      tx.update(_firestore.collection('users').doc(review.userId), {
        'rating': double.parse(newRating.toStringAsFixed(1)),
        'ratingCount': newCount,
      });
    });
  }

  Future<List<ReviewModel>> getReviewsForUser(String userId) async {
    final snap = await _firestore.collection('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => ReviewModel.fromDocument(d)).toList();
  }

  Future<bool> hasUserReviewed(String reviewerId, String userId) async {
    final snap = await _firestore.collection('reviews')
        .where('reviewerId', isEqualTo: reviewerId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> deleteAccount(String userId) async {
    final batch = _firestore.batch();
    // Delete user's ads
    final ads = await _firestore.collection('ads').where('userId', isEqualTo: userId).get();
    for (final doc in ads.docs) batch.delete(doc.reference);
    // Delete user's reviews
    final reviews = await _firestore.collection('reviews').where('userId', isEqualTo: userId).get();
    for (final doc in reviews.docs) batch.delete(doc.reference);
    // Delete user document
    batch.delete(_firestore.collection('users').doc(userId));
    await batch.commit();
    // Delete profile image
    try {
      await _storage.ref('profile_images/$userId').delete();
    } catch (_) {}
  }

  Future<void> reportUser(String reporterId, String reporterName, String userId, String reason) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportedItemId': userId,
      'type': 'user',
      'reason': reason,
      'isResolved': false,
      'adminNote': null,
      'resolvedBy': null,
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    });
  }
}
