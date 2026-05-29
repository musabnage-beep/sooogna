import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/review_model.dart';
import '../../../auth/domain/entities/user_entity.dart' show AppUser;
import '../../../../core/utils/result.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _dataSource;
  ProfileRepositoryImpl(this._dataSource);

  String _mapError(dynamic e) {
    if (e is FirebaseException) return 'حدث خطأ (${e.code})';
    if (e is SocketException) return 'لا يوجد اتصال بالإنترنت';
    return 'حدث خطأ غير متوقع';
  }

  @override
  Future<Result<AppUser?>> getUserById(String userId) async {
    try {
      final model = await _dataSource.getUserById(userId);
      return Result.success(model?.toEntity());
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> updateProfile(String userId, {String? name, String? profileImagePath}) async {
    try {
      await _dataSource.updateProfile(userId, name: name, profileImagePath: profileImagePath);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> submitReview(Review review) async {
    try {
      final model = ReviewModel(
        id: '',
        reviewerId: review.reviewerId,
        reviewerName: review.reviewerName,
        reviewerImage: review.reviewerImage,
        userId: review.userId,
        rating: review.rating,
        comment: review.comment,
        createdAt: Timestamp.fromDate(review.createdAt),
      );
      await _dataSource.submitReview(model);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(_mapError(e));
    }
  }

  @override
  Future<Result<List<Review>>> getReviewsForUser(String userId) async {
    try {
      final models = await _dataSource.getReviewsForUser(userId);
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<bool>> hasUserReviewed(String reviewerId, String userId) async {
    try {
      final result = await _dataSource.hasUserReviewed(reviewerId, userId);
      return Result.success(result);
    } catch (e) { return const Result.success(false); }
  }

  @override
  Future<Result<void>> deleteAccount(String userId) async {
    try {
      await _dataSource.deleteAccount(userId);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> reportUser(String reporterId, String reporterName, String userId, String reason) async {
    try {
      await _dataSource.reportUser(reporterId, reporterName, userId, reason);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }
}
