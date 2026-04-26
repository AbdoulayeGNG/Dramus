class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool read;
  final String type;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    required this.type,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? json['content'] ?? '',
      read: json['read'] == true,
      type: json['type'] ?? 'message',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'body': body,
      'read': read,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    bool? read,
    String? type,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      read: read ?? this.read,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}
