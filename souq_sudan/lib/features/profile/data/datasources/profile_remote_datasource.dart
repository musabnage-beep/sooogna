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
      await ImageCompressor.deleteIfTemp(compressed);
    }
    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update(updates);
    }
  }

  Future<void> submitReview(ReviewModel review) async {
    // Deterministic ID enforces one review per (reviewer, target) — matches
    // the Firestore rule. A repeat submission edits the existing review
    // instead of creating a duplicate.
    final reviewId = '${review.reviewerId}_${review.userId}';
    final reviewRef = _firestore.collection('reviews').doc(reviewId);
    final userRef = _firestore.collection('users').doc(review.userId);
    await _firestore.runTransaction((tx) async {
      // All reads must precede writes in a Firestore transaction.
      final userDoc = await tx.get(userRef);
      if (!userDoc.exists) return;
      final existing = await tx.get(reviewRef);

      final data = userDoc.data()!;
      final oldRating = ((data['rating'] as num?) ?? 0).toDouble();
      final oldCount = (data['ratingCount'] as int?) ?? 0;
      final oldTotal = oldRating * oldCount;

      double newTotal;
      int newCount;
      if (existing.exists) {
        // Editing: swap the previous score for the new one, count unchanged.
        final prev = ((existing.data()?['rating'] as num?) ?? 0).toDouble();
        newCount = oldCount;
        newTotal = oldTotal - prev + review.rating;
      } else {
        newCount = oldCount + 1;
        newTotal = oldTotal + review.rating;
      }
      final newRating = newCount > 0 ? newTotal / newCount : 0.0;

      tx.set(reviewRef, {
        ...review.toMap(),
        // Generalized review target (Feature 4) — backward compatible with the
        // legacy `userId` field used by older reviews.
        'targetType': 'user',
        'targetId': review.userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(userRef, {
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
    // Gather references first (each scan is capped to avoid unbounded reads),
    // then delete in chunks that respect Firestore's 500-write batch limit so
    // a user with lots of content can still be removed without a server tier.
    final refs = <DocumentReference>[];

    final ads = await _firestore
        .collection('ads')
        .where('userId', isEqualTo: userId)
        .limit(AppConstants.maxDeleteScan)
        .get();
    refs.addAll(ads.docs.map((d) => d.reference));

    final reviews = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .limit(AppConstants.maxDeleteScan)
        .get();
    refs.addAll(reviews.docs.map((d) => d.reference));

    // Remove chats so the user disappears from the other party's chat list and
    // no orphaned chat docs reference a deleted account.
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
