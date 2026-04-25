class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phone;
  final String avatar;
  final String role; // client | particulier | agent | agence
  final String? agencyId;
  final bool? isVerified;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phone,
    required this.avatar,
    required this.role,
    this.agencyId,
    this.isVerified,
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    String f = firstName.isNotEmpty ? firstName[0] : '';
    String l = lastName.isNotEmpty ? lastName[0] : '';
    if (f.isEmpty && l.isEmpty) return 'U';
    return (f + l).toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['_id'] ?? json['id'])?.toString() ?? '',
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        email: json['email'] ?? '',
        password: json['password'] ?? '',
        phone: json['phone'] ?? '',
        avatar: json['avatar'] ?? '',
        role: () {
          final r = json['role'];
          if (r == null) return 'client';
          if (r is String) return r;
          if (r is Map<String, dynamic>)
            return (r['name'] ?? r['role'] ?? 'client').toString();
          return 'client';
        }(),
        agencyId: json['agencyId'] ?? json['agency'] ?? null,
        isVerified: (json['isVerified'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'avatar': avatar,
        'role': role,
        'agencyId': agencyId,
        'isVerified': isVerified,
      };
  User copyWith(
      {String? firstName,
      String? lastName,
      String? email,
      String? password,
      String? phone,
      String? avatar,
      String? role, // client | particulier | agent | agence
      String? agencyId,
      bool? isVerified}) {
    return User(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      agencyId: agencyId ?? this.agencyId,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
