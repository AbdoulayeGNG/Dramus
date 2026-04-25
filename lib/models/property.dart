class PropertyOwner {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? avatar;

  const PropertyOwner({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.avatar,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  factory PropertyOwner.fromJson(Map<String, dynamic> json) => PropertyOwner(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        avatar: json['avatar'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'avatar': avatar,
      };
}

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
  final PropertyOwner owner; // Changé de String ownerId à PropertyOwner owner
  final String title;
  final String type; // Maison | Appartement | Terrain
  final num price;
  final PropertyLocation location;
  final num surface;
  final String description;
  final List<String> images;
  final String status; // draft | published | archived
  final int views;
  final bool isFavorite; // Indique si la propriété est en favori

  const Property({
    required this.id,
    required this.owner,
    required this.title,
    required this.type,
    required this.price,
    required this.location,
    required this.surface,
    required this.description,
    required this.images,
    required this.status,
    required this.views,
    this.isFavorite = false,
  });

  // Getter pour compatibilité avec l'ancien code qui utilise ownerId
  String get ownerId => owner.id;

  factory Property.fromJson(Map<String, dynamic> json) {
    // Parser le owner - peut être un objet ou juste un ID
    PropertyOwner owner;
    final ownerData = json['ownerId'];

    if (ownerData is Map<String, dynamic>) {
      // Si c'est un objet complet, le parser
      owner = PropertyOwner.fromJson(ownerData);
    } else if (ownerData is String) {
      // Si c'est juste un ID, créer un PropertyOwner avec juste l'ID
      owner = PropertyOwner(
        id: ownerData,
        firstName: 'Propriétaire',
        lastName: '',
        email: '',
        phone: '',
        avatar: null,
      );
    } else {
      // Valeur par défaut si aucune donnée
      owner = PropertyOwner(
        id: '',
        firstName: 'Inconnu',
        lastName: '',
        email: '',
        phone: '',
        avatar: null,
      );
    }

    return Property(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      owner: owner,
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
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': owner.id, // Envoie juste l'ID pour la compatibilité backend
        'title': title,
        'type': type,
        'price': price,
        'location': location.toJson(),
        'surface': surface,
        'description': description,
        'images': images,
        'status': status,
        'views': views,
        'isFavorite': isFavorite,
      };
  Property copyWith({
    String? id,
    PropertyOwner? owner,
    String? title,
    String? type,
    num? price,
    PropertyLocation? location,
    num? surface,
    String? description,
    List<String>? images,
    String? status,
    int? views,
    bool? isFavorite,
  }) {
    return Property(
      id: id ?? this.id,
      owner: owner ?? this.owner,
      title: title ?? this.title,
      type: type ?? this.type,
      price: price ?? this.price,
      location: location ?? this.location,
      surface: surface ?? this.surface,
      description: description ?? this.description,
      images: images ?? this.images,
      status: status ?? this.status,
      views: views ?? this.views,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Property.empty() {
    return Property(
      id: '',
      owner: PropertyOwner(
          id: '', firstName: '', lastName: '', email: '', phone: ''),
      title: '',
      type: '',
      price: 0,
      location:
          PropertyLocation(city: '', district: '', latitude: 0, longitude: 0),
      surface: 0,
      description: '',
      images: [],
      status: 'draft',
      views: 0,
    );
  }
}
