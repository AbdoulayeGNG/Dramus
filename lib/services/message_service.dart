import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dramus/models/message_model.dart';
import 'package:dramus/core/api/api_client.dart';

class MessageService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient.I;

  List<Conversation> _conversations = [];
  Map<String, List<Message>> _messagesByConversation = {};
  bool _isLoading = false;
  String? currentUserId;

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;

  /// Définir l'ID de l'utilisateur courant
  void setCurrentUserId(String userId) {
    currentUserId = userId;
    debugPrint('MessageService: Current user ID set to: $userId');
  }

  /// Charger toutes les conversations de l'utilisateur
  /// Charger toutes les conversations de l'utilisateur
  Future<void> loadConversations() async {
    if (currentUserId == null) {
      debugPrint(
          'MessageService: Cannot load conversations - current user ID not set');
      return;
    }

    try {
      debugPrint(
          'MessageService: Loading conversations for user: $currentUserId');
      _isLoading = true;
      notifyListeners();

      final response = await _apiClient.dio.get('/api/messages');

      debugPrint(
          'MessageService: Conversations response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> conversationsData = [];

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          conversationsData = data['data'] as List<dynamic>;
        } else if (data is List<dynamic>) {
          conversationsData = data;
        }

        debugPrint(
            'MessageService: Processing ${conversationsData.length} conversations from API');

        // Helper pour extraire l'ID
        String extractId(dynamic value) {
          if (value == null) return '';
          if (value is String) return value.trim();
          if (value is Map<String, dynamic>) {
            return (value['_id']?.toString() ?? value['id']?.toString() ?? '')
                .trim();
          }
          return value.toString().trim();
        }

        List<Conversation> newConversations = [];
        // On ne remplit pas _messagesByConversation ici car on n'a que le lastMessage
        // Les messages complets seront chargés via loadConversation()

        for (var convJson in conversationsData) {
          try {
            // Structure attendue d'après les logs:
            // { _id: { ...UserObject... }, lastMessage: { ...MessageObject... }, unreadCount: 0 }

            final otherUserObj =
                convJson['_id']; // L'objet utilisateur de l'interlocuteur
            final lastMessageObj = convJson['lastMessage'];

            if (otherUserObj == null || lastMessageObj == null) {
              debugPrint(
                  'MessageService: Skipping invalid conversation format: missing _id or lastMessage');
              continue;
            }

            // Extraction des infos de l'autre utilisateur
            String otherUserId = extractId(otherUserObj);
            String otherUserName = 'Utilisateur';
            String? otherUserAvatar;

            if (otherUserObj is Map<String, dynamic>) {
              otherUserName = otherUserObj['fullName'] ??
                  '${otherUserObj['firstName'] ?? ''} ${otherUserObj['lastName'] ?? ''}'
                      .trim();
              if (otherUserName.trim().isEmpty) otherUserName = 'Utilisateur';
              otherUserAvatar = otherUserObj['avatar'];
            }

            // Création du message
            final lastMessage =
                Message.fromJson(lastMessageObj as Map<String, dynamic>);

            // Création de la conversation
            final conversation = Conversation(
              id: otherUserId,
              userId1: currentUserId!,
              user1Name: 'Vous',
              userId2: otherUserId,
              user2Name: otherUserName,
              user2Avatar: otherUserAvatar,
              lastMessage: lastMessage,
              updatedAt: lastMessage.createdAt,
            );

            newConversations.add(conversation);
          } catch (e) {
            debugPrint('MessageService: Error parsing conversation item: $e');
          }
        }

        // Trier les conversations pour avoir les plus récentes en premier
        newConversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        // Mettre à jour la liste principale
        _conversations = newConversations;

        debugPrint(
            'MessageService: Loaded ${_conversations.length} distinct conversations');
        notifyListeners();
      }
    } on DioException catch (e) {
      debugPrint('MessageService: Error loading conversations: ${e.message}');
    } catch (e) {
      debugPrint('MessageService: Unexpected error loading conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger une conversation spécifique avec un utilisateur
  Future<void> loadConversation(String userId) async {
    final otherUserId = userId.trim();
    if (currentUserId == null) {
      debugPrint(
          'MessageService: Cannot load conversation - current user ID not set');
      return;
    }

    try {
      debugPrint(
          'MessageService: Loading conversation with user: $otherUserId');
      _isLoading = true;
      notifyListeners();

      final response =
          await _apiClient.dio.get('/api/messages/conversation/$otherUserId');

      debugPrint('MessageService: Response status: ${response.statusCode}');
      debugPrint('MessageService: Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> messagesData = [];

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          messagesData = data['data'] as List<dynamic>;
        } else if (data is List<dynamic>) {
          messagesData = data;
        }

        final messages = messagesData
            .map((json) => Message.fromJson(json as Map<String, dynamic>))
            .toList();

        // Trier par date
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        _messagesByConversation[otherUserId] = messages;

        // Mettre à jour ou créer la conversation
        final existingConvIndex =
            _conversations.indexWhere((c) => c.id == otherUserId);

        if (messages.isNotEmpty) {
          final lastMessage = messages.last;

          String otherUserName = existingConvIndex != -1
              ? _conversations[existingConvIndex].user2Name
              : 'Utilisateur';

          // Tenter de trouver un meilleur nom dans les messages fraîchement chargés
          for (var i = messages.length - 1; i >= 0; i--) {
            final msg = messages[i];
            String? potentialName;

            if (msg.senderId == otherUserId) {
              potentialName = msg.senderName;
            } else if (msg.receiverId == otherUserId) {
              potentialName = msg.receiverName;
            }

            if (potentialName != null && potentialName.trim().isNotEmpty) {
              otherUserName = potentialName;
              break;
            }
          }

          final conversation = Conversation(
            id: otherUserId,
            userId1: currentUserId!,
            user1Name: 'Vous',
            userId2: otherUserId,
            user2Name: otherUserName,
            lastMessage: lastMessage,
            updatedAt: lastMessage.createdAt,
          );

          if (existingConvIndex != -1) {
            _conversations[existingConvIndex] = conversation;
          } else {
            _conversations.insert(0, conversation);
          }
        }

        debugPrint(
            'MessageService: Loaded ${messages.length} messages for conversation');
        notifyListeners();
      }
    } on DioException catch (e) {
      debugPrint('MessageService: Error loading conversation: ${e.message}');
      debugPrint('MessageService: Status code: ${e.response?.statusCode}');
      debugPrint('MessageService: Response data: ${e.response?.data}');
    } catch (e) {
      debugPrint('MessageService: Unexpected error loading conversation: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupérer les messages d'une conversation (depuis le cache local)
  List<Message> getMessagesForConversation(String conversationId) {
    return _messagesByConversation[conversationId.trim()] ?? [];
  }

  /// Envoyer un message
  Future<bool> sendMessage({
    required String receiverId,
    required String content,
    String? propertyId,
  }) async {
    if (currentUserId == null) {
      debugPrint(
          'MessageService: Cannot send message - current user ID not set');
      return false;
    }

    try {
      debugPrint('MessageService: Sending message to user: $receiverId');
      _isLoading = true;
      notifyListeners();

      final messageData = {
        'receiverId': receiverId,
        'content': content,
        if (propertyId != null) 'propertyId': propertyId,
      };

      debugPrint('MessageService: Message data: $messageData');

      final response = await _apiClient.dio.post(
        '/api/messages',
        data: messageData,
      );

      debugPrint('MessageService: Response status: ${response.statusCode}');
      debugPrint('MessageService: Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extraire le message créé depuis la réponse
        Map<String, dynamic> messageJson;

        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          messageJson = response.data['data'] as Map<String, dynamic>;
        } else if (response.data is Map<String, dynamic>) {
          messageJson = response.data as Map<String, dynamic>;
        } else {
          // Si le serveur ne renvoie pas le message, on le crée localement
          messageJson = {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'senderId': currentUserId,
            'receiverId': receiverId,
            'content': content,
            'propertyId': propertyId,
            'read': false,
            'createdAt': DateTime.now().toIso8601String(),
          };
        }

        final newMessage = Message.fromJson(messageJson);

        // Ajouter le message à la conversation locale
        if (!_messagesByConversation.containsKey(receiverId)) {
          _messagesByConversation[receiverId] = [];
        }
        _messagesByConversation[receiverId]!.add(newMessage);

        // Mettre à jour ou créer la conversation
        final existingConvIndex =
            _conversations.indexWhere((c) => c.id == receiverId);

        final conversation = Conversation(
          id: receiverId,
          userId1: currentUserId!,
          user1Name: 'Vous',
          userId2: receiverId,
          user2Name: existingConvIndex != -1
              ? _conversations[existingConvIndex].user2Name
              : 'Utilisateur',
          lastMessage: newMessage,
          updatedAt: newMessage.createdAt,
        );

        if (existingConvIndex != -1) {
          _conversations[existingConvIndex] = conversation;
        } else {
          _conversations.insert(0, conversation);
        }

        // Retrier les conversations
        _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        debugPrint('MessageService: Message sent successfully');
        notifyListeners();
        return true;
      }

      return false;
    } on DioException catch (e) {
      debugPrint('MessageService: Error sending message: ${e.message}');
      debugPrint('MessageService: Status code: ${e.response?.statusCode}');
      debugPrint('MessageService: Response data: ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('MessageService: Unexpected error sending message: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marquer un message comme lu
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      debugPrint('MessageService: Marking message as read: $messageId');

      final response =
          await _apiClient.dio.patch('/api/messages/$messageId/read');

      debugPrint('MessageService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Mettre à jour le message localement
        for (var messages in _messagesByConversation.values) {
          final msgIndex = messages.indexWhere((m) => m.id == messageId);
          if (msgIndex != -1) {
            messages[msgIndex] = messages[msgIndex].copyWith(read: true);
            break;
          }
        }

        notifyListeners();
        return true;
      }

      return false;
    } on DioException catch (e) {
      debugPrint('MessageService: Error marking message as read: ${e.message}');
      return false;
    }
  }

  /// Marquer tous les messages d'une conversation comme lus
  Future<void> markConversationAsRead(String conversationId) async {
    final messages = _messagesByConversation[conversationId] ?? [];

    for (var message in messages) {
      if (!message.read && message.receiverId == currentUserId) {
        await markMessageAsRead(message.id);
      }
    }
  }

  /// Supprimer un message (en tant qu'expéditeur)
  Future<bool> deleteMessage(String messageId) async {
    try {
      debugPrint('MessageService: Deleting message: $messageId');

      final response = await _apiClient.dio.delete('/api/messages/$messageId');

      debugPrint('MessageService: Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Retirer le message localement
        for (var conversationId in _messagesByConversation.keys) {
          _messagesByConversation[conversationId]!
              .removeWhere((m) => m.id == messageId);

          // Si c'était le dernier message, mettre à jour la conversation
          if (_messagesByConversation[conversationId]!.isNotEmpty) {
            final lastMessage = _messagesByConversation[conversationId]!.last;
            final convIndex =
                _conversations.indexWhere((c) => c.id == conversationId);

            if (convIndex != -1) {
              _conversations[convIndex] = _conversations[convIndex].copyWith(
                lastMessage: lastMessage,
                updatedAt: lastMessage.createdAt,
              );
            }
          } else {
            // Si plus de messages, retirer la conversation
            _conversations.removeWhere((c) => c.id == conversationId);
            _messagesByConversation.remove(conversationId);
          }
        }

        notifyListeners();
        return true;
      }

      return false;
    } on DioException catch (e) {
      debugPrint('MessageService: Error deleting message: ${e.message}');
      return false;
    }
  }

  /// Obtenir le nombre de messages non lus
  int getUnreadCount() {
    int count = 0;
    for (var messages in _messagesByConversation.values) {
      count += messages
          .where((msg) => !msg.read && msg.receiverId == currentUserId)
          .length;
    }
    return count;
  }

  /// Créer une nouvelle conversation avec un utilisateur
  Future<void> startConversation(String userId, String userName) async {
    // Vérifier si la conversation existe déjà
    final index = _conversations.indexWhere((c) => c.id == userId);

    if (index != -1) {
      // La conversation existe déjà
      // Si on a un nom plus précis que "Utilisateur", on met à jour
      if (userName != 'Utilisateur' &&
          userName.isNotEmpty &&
          _conversations[index].user2Name == 'Utilisateur') {
        _conversations[index] =
            _conversations[index].copyWith(user2Name: userName);
        notifyListeners();
      }
    } else {
      // Créer une nouvelle conversation vide
      final newConv = Conversation(
        id: userId,
        userId1: currentUserId ?? '',
        user1Name: 'Vous',
        userId2: userId,
        user2Name: userName,
        lastMessage: Message(
          id: '',
          senderId: '',
          receiverId: '',
          content: '',
          propertyId: null,
          read: true,
          createdAt: DateTime.now(),
        ),
        updatedAt: DateTime.now(),
      );

      _conversations.insert(0, newConv);
      _messagesByConversation[userId] = [];
      notifyListeners();
    }
  }

  /// Réinitialiser le service (lors de la déconnexion)
  void clear() {
    _conversations = [];
    _messagesByConversation = {};
    currentUserId = null;
    _isLoading = false;
    notifyListeners();
  }
}
