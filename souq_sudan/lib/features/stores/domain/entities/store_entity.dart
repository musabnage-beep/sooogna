/// A business store (Feature 7). The document id equals the owner's userId,
/// which enforces one store per owner and lets rules verify ownership cheaply.
class Store {
  final String storeId; // == ownerId
  final String ownerId;
  final String name;
  final String? logo;
  final String? banner;
  final String description;
  final String? whatsapp;
  final String? phone;
  final String city;
  final double rating;
  final int ratingCount;
  final int productCount;
  final DateTime createdAt;

  const Store({
    required this.storeId,
    required this.ownerId,
    required this.name,
    this.logo,
    this.banner,
    this.description = '',
    this.whatsapp,
    this.phone,
    required this.city,
    this.rating = 0,
    this.ratingCount = 0,
    this.productCount = 0,
    required this.createdAt,
  });

  Store copyWith({
    String? storeId,
    String? ownerId,
    String? name,
    String? logo,
    String? banner,
    String? description,
    String? whatsapp,
    String? phone,
    String? city,
    double? rating,
    int? ratingCount,
    int? productCount,
    DateTime? createdAt,
  }) {
    return Store(
      storeId: storeId ?? this.storeId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      banner: banner ?? this.banner,
      description: description ?? this.description,
      whatsapp: whatsapp ?? this.whatsapp,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
