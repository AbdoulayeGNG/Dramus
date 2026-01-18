class PropertyLocation {
  final String city;
  final String district;
  final double latitude;
  final double longitude;

  const PropertyLocation({
    required this.city,
    required this.district,
    required this.latitude,
    required this.longitude,
  });

  factory PropertyLocation.fromJson(Map<String, dynamic> json) =>
      PropertyLocation(
        city: json['city'] ?? '',
        district: json['district'] ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'city': city,
        'district': district,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class Property {
  final String id;
  final String ownerId;
  final String title;
  final String type; // Maison | Appartement | Terrain
  final num price;
  final PropertyLocation location;
  final num surface;
  final String description;
  final List<String> images;
  final String status; // draft | published | archived
  final int views;

  const Property({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.type,
    required this.price,
    required this.location,
    required this.surface,
    required this.description,
    required this.images,
    required this.status,
    required this.views,
  });

  factory Property.fromJson(Map<String, dynamic> json) => Property(
        id: json['id']?.toString() ?? '',
        ownerId: json['ownerId']?.toString() ?? '',
        title: json['title'] ?? '',
        type: json['type'] ?? 'Maison',
        price: json['price'] ?? 0,
        location: PropertyLocation.fromJson(json['location'] ?? {}),
        surface: json['surface'] ?? 0,
        description: json['description'] ?? '',
        images:
            ((json['images'] ?? []) as List).map((e) => e.toString()).toList(),
        status: json['status'] ?? 'draft',
        views: (json['views'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'title': title,
        'type': type,
        'price': price,
        'location': location.toJson(),
        'surface': surface,
        'description': description,
        'images': images,
        'status': status,
        'views': views,
      };
}
