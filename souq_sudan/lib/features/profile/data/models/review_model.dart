import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/review_entity.dart';

class ReviewModel {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerImage;
  final String userId;
  final double rating;
  final String? comment;
  final Timestamp createdAt;

  const ReviewModel({
    required this.id, required this.reviewerId, required this.reviewerName,
    this.reviewerImage, required this.userId, required this.rating,
    this.comment, required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      reviewerId: (map['reviewerId'] as String?) ?? '',
      reviewerName: (map['reviewerName'] as String?) ?? '',
      reviewerImage: map['reviewerImage'] as String?,
      userId: (map['userId'] as String?) ?? '',
      rating: ((map['rating'] as num?) ?? 0).toDouble(),
      comment: map['comment'] as String?,
      createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  factory ReviewModel.fromDocument(DocumentSnapshot doc) =>
      ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
    'reviewerId': reviewerId, 'reviewerName': reviewerName,
    'reviewerImage': reviewerImage, 'userId': userId,
    'rating': rating, 'comment': comment, 'createdAt': createdAt,
  };

  Review toEntity() => Review(
    id: id, reviewerId: reviewerId, reviewerName: reviewerName,
    reviewerImage: reviewerImage, userId: userId, rating: rating,
    comment: comment, createdAt: createdAt.toDate(),
  );
}
