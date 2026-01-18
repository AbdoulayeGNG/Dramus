class Listing {
  final String id;
  final String title;
  final String description;
  final String location;
  final double price;
  final String type; // 'sale' or 'rent'
  final bool isPremium;
  final List<String> imageUrls;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final String agentName;
  final String agentPhone;
  final String agentEmail;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  bool isFavorite;

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.price,
    required this.type,
    required this.isPremium,
    required this.imageUrls,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.agentName,
    required this.agentPhone,
    required this.agentEmail,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  Listing copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    double? price,
    String? type,
    bool? isPremium,
    List<String>? imageUrls,
    int? bedrooms,
    int? bathrooms,
    double? area,
    String? agentName,
    String? agentPhone,
    String? agentEmail,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return Listing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      price: price ?? this.price,
      type: type ?? this.type,
      isPremium: isPremium ?? this.isPremium,
      imageUrls: imageUrls ?? this.imageUrls,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      agentName: agentName ?? this.agentName,
      agentPhone: agentPhone ?? this.agentPhone,
      agentEmail: agentEmail ?? this.agentEmail,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
