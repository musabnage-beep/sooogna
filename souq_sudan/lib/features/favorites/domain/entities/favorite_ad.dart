/// A denormalized snapshot of a saved ad (Feature 8).
/// Stored at `users/{uid}/favorites/{adId}` so the Saved list renders
/// without N extra ad reads.
class FavoriteAd {
  final String adId;
  final String title;
  final double price;
  final String? image;
  final String city;
  final DateTime savedAt;

  const FavoriteAd({
    required this.adId,
    required this.title,
    required this.price,
    this.image,
    this.city = '',
    required this.savedAt,
  });
}
