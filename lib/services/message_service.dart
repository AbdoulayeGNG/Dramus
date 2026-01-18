import 'package:flutter/foundation.dart';
import 'package:dramus/models/message_model.dart';

class MessageService extends ChangeNotifier {
  late List<Conversation> _conversations;
  late Map<String, List<Message>> _messagesByConversation;

  MessageService() {
    _initializeSampleData();
  }

  List<Conversation> get conversations => _conversations;

  void _initializeSampleData() {
    _conversations = [
      Conversation(
        id: 'conv1',
        userId1: 'user1',
        user1Name: 'Vous',
        userId2: 'agent1',
        user2Name: 'Mamadou Diallo',
        lastMessage: Message(
          id: 'msg1',
          senderId: 'agent1',
          receiverId: 'user1',
          content: 'Oui, c\'est possible de visiter demain à 14h. À bientôt!',
          propertyId: null,
          read: true,
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      Conversation(
        id: 'conv2',
        userId1: 'user1',
        user1Name: 'Vous',
        userId2: 'agent2',
        user2Name: 'Fatoumata Bah',
        lastMessage: Message(
          id: 'msg2',
          senderId: 'user1',
          receiverId: 'agent2',
          content:
              'Merci pour les informations. J\'aimerais avoir plus de détails sur les charges.',
          propertyId: null,
          read: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Conversation(
        id: 'conv3',
        userId1: 'user1',
        user1Name: 'Vous',
        userId2: 'agent3',
        user2Name: 'Lamine Toure',
        lastMessage: Message(
          id: 'msg3',
          senderId: 'agent3',
          receiverId: 'user1',
          content:
              'La location est disponible à partir du 1er février. Prix négociable pour engagement 2 ans.',
          propertyId: null,
          read: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Conversation(
        id: 'conv4',
        userId1: 'user1',
        user1Name: 'Vous',
        userId2: 'agent4',
        user2Name: 'Mariama Bah',
        lastMessage: Message(
          id: 'msg4',
          senderId: 'user1',
          receiverId: 'agent4',
          content: 'Pouvez-vous m\'envoyer les photos supplémentaires?',
          propertyId: null,
          read: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    _messagesByConversation = {
      'conv1': [
        Message(
          id: 'msg1_1',
          senderId: 'user1',
          receiverId: 'agent1',
          content: 'Bonjour, je suis intéressé par le penthouse du Plateau.',
          propertyId: null,
          read: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Message(
          id: 'msg1_2',
          senderId: 'agent1',
          receiverId: 'user1',
          content:'Bonjour! Excellente propriété. Puis-je vous proposer une visite demain?',
          propertyId: null,
          read: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Message(
          id: 'msg1_3',
          senderId: 'user1',
          receiverId: 'agent1',
          content: 'Avec plaisir! À quelle heure?',
          propertyId: null,
          read: true,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        Message(
          id: 'msg1_4',
          senderId: 'agent1',
          receiverId: 'user1',
          content: 'Oui, c\'est possible de visiter demain à 14h. À bientôt!',
          propertyId: null,
          read: true,
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
      ],
      'conv2': [
        Message(
          id: 'msg2_1',
          senderId: 'agent2',
          receiverId: 'user1',
          content: 'Bonsoir, voici les détails de la villa que vous cherchez.',
          propertyId: null,
          read: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        Message(
          id: 'msg2_2',
          senderId: 'user1',
          receiverId: 'agent2',
          content:
              'Merci pour les informations. J\'aimerais avoir plus de détails sur les charges.',
          propertyId: null,
          read: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Message(
          id: 'msg2_3',
          senderId: 'agent2',
          receiverId: 'user1',
          content:
              'Merci pour les informations. J\'aimerais avoir plus de détails sur les charges.',
          propertyId: null,
          read: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
      'conv3': [
        Message(
          id: 'msg3_1',
          senderId: 'user1',
          receiverId: 'agent3',
          content: 'Bonjour, j\'aimerais savoir la date de disponibilité.',
          propertyId: null,
          read: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        Message(
          id: 'msg3_2',
          senderId: 'agent3',
          receiverId: 'user1',
          content:
              'La location est disponible à partir du 1er février. Prix négociable pour engagement 2 ans.',
          propertyId: null,
          read: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ],
      'conv4': [
        Message(
          id: 'msg4_1',
          senderId: 'agent4',
          receiverId: 'user1',
          content:
              'Bon matin! Le studio est vraiment disponible et en excellent état.',
          propertyId: null,
          read: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Message(
          id: 'msg4_2',
          senderId: 'user1',
          receiverId: 'agent4',
          content: 'Pouvez-vous m\'envoyer les photos supplémentaires?',
          propertyId: null,
          read: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    };
  }

  List<Message> getMessagesForConversation(String conversationId) {
    return _messagesByConversation[conversationId] ?? [];
  }

  void sendMessage(
    String conversationId,
    String senderId,
    String senderName,
    String receiverId,
    String content,
  ) {
    final message = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      propertyId: null,
      read: false,
      createdAt: DateTime.now(),
    );

    if (!_messagesByConversation.containsKey(conversationId)) {
      _messagesByConversation[conversationId] = [];
    }

    _messagesByConversation[conversationId]?.add(message);

    final convIndex =
        _conversations.indexWhere((conv) => conv.id == conversationId);
    if (convIndex != -1) {
      _conversations[convIndex] = _conversations[convIndex].copyWith(
        lastMessage: message,
        updatedAt: DateTime.now(),
      );
    }

    notifyListeners();
  }

  void markAsRead(String conversationId) {
    final messages = _messagesByConversation[conversationId];
    if (messages != null) {
      for (int i = 0; i < messages.length; i++) {
        if (!messages[i].read) {
          messages[i] = messages[i].copyWith(read: true);
        }
      }
      notifyListeners();
    }
  }

  int getUnreadCount() {
    int count = 0;
    for (var messages in _messagesByConversation.values) {
      count += messages.where((msg) => !msg.read).length;
    }
    return count;
  }
}
