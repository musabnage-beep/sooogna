class Review {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerImage;
  final String userId;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerImage,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });
}
