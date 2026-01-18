class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String? propertyId;
  final bool read;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.propertyId,
    required this.read,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id']?.toString() ?? '',
        senderId: json['senderId'] ?? '',
        receiverId: json['receiverId'] ?? '',
        content: json['content'] ?? '',
        propertyId: json['propertyId']?.toString(),
        read: (json['read'] as bool?) ?? false,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'propertyId': propertyId,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
      };



  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    String? propertyId,
    bool? read,
    DateTime? createdAt,
  
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      propertyId: propertyId ?? this.propertyId,
      read: read ?? this.read,
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
  final Message lastMessage;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.userId1,
    required this.user1Name,
    required this.userId2,
    required this.user2Name,
    required this.lastMessage,
    required this.updatedAt,
  });

  Conversation copyWith({
    String? id,
    String? userId1,
    String? user1Name,
    String? userId2,
    String? user2Name,
    Message? lastMessage,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId1: userId1 ?? this.userId1,
      user1Name: user1Name ?? this.user1Name,
      userId2: userId2 ?? this.userId2,
      user2Name: user2Name ?? this.user2Name,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
