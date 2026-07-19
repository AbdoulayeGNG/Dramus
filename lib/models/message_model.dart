class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String? propertyId;
  final String? senderName;
  final String? receiverName;
  final bool read;
  final String status; // 'sent', 'delivered', 'read'
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.propertyId,
    this.senderName,
    this.receiverName,
    required this.read,
    this.status = 'sent',
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Helper pour extraire l'ID depuis un objet ou une string
    String extractId(dynamic value) {
      if (value == null) return '';
      if (value is String) return value.trim();
      if (value is Map<String, dynamic>) {
        return (value['_id']?.toString() ?? value['id']?.toString() ?? '')
            .trim();
      }
      return value.toString().trim();
    }

    // Helper pour extraire le nom
    String? extractName(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value['fullName'] ??
            '${value['firstName'] ?? ''} ${value['lastName'] ?? ''}'.trim();
      }
      return null;
    }

    return Message(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      senderId: extractId(json['senderId']),
      receiverId: extractId(json['receiverId']),
      content: json['content'] ?? '',
      propertyId:
          json['propertyId'] != null ? extractId(json['propertyId']) : null,
      senderName: extractName(json['senderId']),
      receiverName: extractName(json['receiverId']),
      read: (json['read'] as bool?) ?? false,
      status: json['status']?.toString() ??
          ((json['read'] as bool?) == true ? 'read' : 'sent'),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'propertyId': propertyId,
        'read': read,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    String? propertyId,
    bool? read,
    String? status,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      propertyId: propertyId ?? this.propertyId,
      read: read ?? this.read,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Conversation {
  final String id;
  final String userId1;
  final String user1Name;
  final String userId2;
  final String user2Name;
  final String? user2Avatar; // Avatar de l'autre utilisateur
  final Message lastMessage;
  final DateTime updatedAt;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.userId1,
    required this.user1Name,
    required this.userId2,
    required this.user2Name,
    this.user2Avatar,
    required this.lastMessage,
    required this.updatedAt,
    this.unreadCount = 0,
  });

  Conversation copyWith({
    String? id,
    String? userId1,
    String? user1Name,
    String? userId2,
    String? user2Name,
    String? user2Avatar,
    Message? lastMessage,
    DateTime? updatedAt,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId1: userId1 ?? this.userId1,
      user1Name: user1Name ?? this.user1Name,
      userId2: userId2 ?? this.userId2,
      user2Name: user2Name ?? this.user2Name,
      user2Avatar: user2Avatar ?? this.user2Avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
