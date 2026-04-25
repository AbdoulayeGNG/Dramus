class AgentModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? password;
  final String phone;
  final List<String> permissions;

  AgentModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.password,
    required this.phone,
    required this.permissions,
  });

  String get fullName => '$firstName $lastName';

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'permissions': permissions,
    };
    if (password != null && password!.isNotEmpty) {
      map['password'] = password!;
    }
    return map;
  }
}
