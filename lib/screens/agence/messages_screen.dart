import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dramus/models/message_model.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/conversation_tile.dart';
import 'package:dramus/widgets/conversation_skeleton.dart';
import 'package:dramus/widgets/empty_conversations_state.dart';
import 'package:dramus/widgets/improved_message_bubble.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String? _selectedConversationId;
  bool _isInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMessages();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeMessages() async {
    if (_isInitialized) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    final messageService = Provider.of<MessageService>(context, listen: false);

    if (authController.user != null) {
      messageService.setCurrentUserId(authController.user!.id);
      await messageService.loadConversations();
      setState(() {
        _isInitialized = true;
      });
    }
  }

  List<Conversation> _getFilteredConversations(MessageService messageService) {
    if (_searchQuery.isEmpty) {
      return messageService.conversations;
    }

    return messageService.conversations.where((conv) {
      final nameLower = conv.user2Name.toLowerCase();
      final contentLower = conv.lastMessage.content.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();
      return nameLower.contains(queryLower) ||
          contentLower.contains(queryLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Consumer<MessageService>(
      builder: (context, messageService, _) {
        if (!_isInitialized) {
          return Scaffold(
            backgroundColor: DramusColors.lightBackground,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: DramusColors.primaryTeal,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Chargement des conversations...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DramusColors.secondaryText,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return isMobile
            ? _buildMobileLayout(context, messageService)
            : _buildDesktopLayout(context, messageService);
      },
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, MessageService messageService) {
    if (_selectedConversationId != null) {
      // Chercher la conversation existante
      Conversation? conv;
      try {
        conv = messageService.conversations.firstWhere(
          (c) =>
              c.id == _selectedConversationId ||
              c.userId2 == _selectedConversationId ||
              c.userId1 == _selectedConversationId,
        );
      } catch (e) {
        // Si la conversation n'existe pas encore, retourner à la liste
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _selectedConversationId = null);
          }
        });
      }

      if (conv != null) {
        return _buildChatView(context, messageService, conv);
      }
    }

    // Vue de la liste des conversations avec AppBar amélioré
    return Scaffold(
      backgroundColor: DramusColors.lightBackground,
      appBar: AppBar(
        backgroundColor: DramusColors.white,
        foregroundColor: DramusColors.darkText,
        title: Text(
          'Messages',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: DramusColors.darkText,
                fontWeight: FontWeight.bold,
              ),
        ),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: DramusColors.darkText),
            onPressed: () => messageService.loadConversations(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: DramusColors.darkText),
            onPressed: () {
              // TODO: Naviguer vers l'écran de notifications
            },
          ),
          // Badge de compteur de messages non lus
          if (messageService.getUnreadCount() > 0)
            Padding(
              padding: AppSpacing.horizontalSm,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DramusColors.notificationRed,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Text(
                    '${messageService.getUnreadCount()}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: DramusColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),
          /*IconButton(
            icon: const Icon(Icons.refresh, color: DramusColors.white),
            onPressed: () => messageService.loadConversations(),
          ),*/
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: DramusColors.white,
            padding: AppSpacing.paddingMd,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: DramusColors.secondaryText,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: DramusColors.secondaryText,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: const BorderSide(
                    color: DramusColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: const BorderSide(
                    color: DramusColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: const BorderSide(
                    color: DramusColors.primaryTeal,
                    width: 2,
                  ),
                ),
                contentPadding: AppSpacing.horizontalMd + AppSpacing.verticalSm,
                filled: true,
                fillColor: DramusColors.lightBackground,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => messageService.loadConversations(),
              child: _buildConversationsList(context, messageService),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, MessageService messageService) {
    return Row(
      children: [
        SizedBox(
          width: 380,
          child: Container(
            color: DramusColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: AppSpacing.paddingMd,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Messages',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (messageService.getUnreadCount() > 0) ...[
                            SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: DramusColors.notificationRed,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                              ),
                              child: Text(
                                '${messageService.getUnreadCount()}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: DramusColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => messageService.loadConversations(),
                        color: DramusColors.primaryTeal,
                      ),
                    ],
                  ),
                ),
                // Barre de recherche
                Padding(
                  padding: AppSpacing.horizontalMd,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: DramusColors.secondaryText,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: DramusColors.secondaryText,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(
                          color: DramusColors.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(
                          color: DramusColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(
                          color: DramusColors.primaryTeal,
                          width: 2,
                        ),
                      ),
                      contentPadding:
                          AppSpacing.horizontalMd + AppSpacing.verticalSm,
                      filled: true,
                      fillColor: DramusColors.lightBackground,
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                Expanded(
                  child: _buildConversationsList(context, messageService),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedConversationId != null &&
                  messageService.conversations
                      .any((c) => c.id == _selectedConversationId)
              ? _buildChatView(
                  context,
                  messageService,
                  messageService.conversations.firstWhere(
                    (c) => c.id == _selectedConversationId,
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline,
                        size: 80,
                        color:
                            DramusColors.secondaryText.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        'Sélectionnez une conversation',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: DramusColors.secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Choisissez une conversation dans la liste',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DramusColors.secondaryText,
                            ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildConversationsList(
      BuildContext context, MessageService messageService) {
    final filteredConversations = _getFilteredConversations(messageService);
    final authController = Provider.of<AuthController>(context, listen: false);

    // État de chargement avec skeleton
    if (messageService.isLoading && messageService.conversations.isEmpty) {
      return const ConversationSkeleton(itemCount: 6);
    }

    // État vide
    if (filteredConversations.isEmpty) {
      return EmptyConversationsState(
        isSearching: _searchQuery.isNotEmpty,
        customMessage: _searchQuery.isNotEmpty
            ? 'Aucune conversation ne correspond à votre recherche'
            : 'Les messages de vos clients apparaîtront ici',
      );
    }

    // Liste des conversations avec le nouveau widget
    return ListView.separated(
      itemCount: filteredConversations.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 72,
        color: DramusColors.border,
      ),
      itemBuilder: (context, index) {
        final conv = filteredConversations[index];
        final hasUnread = !conv.lastMessage.read &&
            conv.lastMessage.receiverId == messageService.currentUserId;

        return ConversationTile(
          conversation: conv,
          isSelected: _selectedConversationId == conv.id,
          hasUnread: hasUnread,
          currentUserId: authController.user?.id,
          onTap: () async {
            setState(() => _selectedConversationId = conv.id);
            messageService.loadConversation(conv.id);
            await messageService.markConversationAsRead(conv.id);
          },
        );
      },
    );
  }

  Widget _buildChatView(
      BuildContext context, MessageService messageService, Conversation conv) {
    final messages = messageService.getMessagesForConversation(conv.id);
    debugPrint(
        'AgenceChatView (DEBUG): id=${conv.id}, msg_count=${messages.length}');
    final messageInputController = TextEditingController();
    final scrollController = ScrollController();
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUserId = authController.user?.id ?? '';

    return Scaffold(
      backgroundColor: DramusColors.lightBackground,
      appBar: AppBar(
        backgroundColor: DramusColors.white,
        foregroundColor: DramusColors.darkText,
        leading: MediaQuery.of(context).size.width < 900
            ? IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: DramusColors.darkText),
                onPressed: () {
                  setState(() => _selectedConversationId = null);
                },
              )
            : null,
        automaticallyImplyLeading: MediaQuery.of(context).size.width < 900,
        title: Row(
          children: [
            // Avatar dans l'AppBar
            conv.user2Avatar != null && conv.user2Avatar!.isNotEmpty
                ? CircleAvatar(
                    radius: 20,
                    backgroundColor: DramusColors.lightGray,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: conv.user2Avatar!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color:
                              DramusColors.primaryTeal.withValues(alpha: 0.2),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DramusColors.primaryTeal,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => CircleAvatar(
                          radius: 20,
                          backgroundColor: DramusColors.primaryTeal,
                          child: Text(
                            _getInitials(conv.user2Name),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: DramusColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 20,
                    backgroundColor: DramusColors.primaryTeal,
                    child: Text(
                      _getInitials(conv.user2Name),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: DramusColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (conv.user2Name.isNotEmpty &&
                            conv.user2Name != 'Utilisateur')
                        ? conv.user2Name
                        : 'Client inconnu',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: DramusColors.darkText,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? (messageService.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: DramusColors.secondaryText
                                  .withValues(alpha: 0.5),
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'Aucun message',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: DramusColors.secondaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'Commencez la conversation',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: DramusColors.secondaryText,
                                  ),
                            ),
                          ],
                        ),
                      ))
                : ListView.builder(
                    controller: scrollController,
                    reverse: true,
                    padding: AppSpacing.paddingMd,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      // Correction cruciale : Normalisation des IDs pour la comparaison
                      final currentUserIdNormalized = currentUserId.trim();
                      final senderIdNormalized = message.senderId.trim();
                      final isCurrentUser =
                          senderIdNormalized == currentUserIdNormalized;

                      // Logique de groupement des messages
                      // Attention : l'index est inversé (reverse: true), donc :
                      // index correspond au message actuel
                      // index + 1 correspond au message précédent (plus vieux)
                      // index - 1 correspond au message suivant (plus récent)

                      final currentIndex = messages.length - 1 - index;

                      // Vérifier si le message précédent est du même auteur (pour savoir si on est le premier du groupe)
                      bool isFirstInGroup = true;
                      if (currentIndex > 0) {
                        final previousMessage = messages[currentIndex - 1];
                        if (previousMessage.senderId.trim() ==
                            senderIdNormalized) {
                          isFirstInGroup = false;
                        }
                      }

                      // Vérifier si le message suivant est du même auteur (pour savoir si on est le dernier du groupe)
                      bool isLastInGroup = true;
                      if (currentIndex < messages.length - 1) {
                        final nextMessage = messages[currentIndex + 1];
                        if (nextMessage.senderId.trim() == senderIdNormalized) {
                          isLastInGroup = false;
                        }
                      }

                      // Gestion des séparateurs de date avec sécurité
                      Widget? dateSeparatorWidget;
                      if (currentIndex == 0) {
                        try {
                          dateSeparatorWidget =
                              DateSeparator(date: message.createdAt);
                        } catch (e) {
                          debugPrint('Error building DateSeparator: $e');
                        }
                      } else {
                        final previousMessage = messages[currentIndex - 1];
                        final currentDate = DateTime(message.createdAt.year,
                            message.createdAt.month, message.createdAt.day);
                        final prevDate = DateTime(
                            previousMessage.createdAt.year,
                            previousMessage.createdAt.month,
                            previousMessage.createdAt.day);
                        if (currentDate != prevDate) {
                          try {
                            dateSeparatorWidget =
                                DateSeparator(date: message.createdAt);
                          } catch (e) {
                            debugPrint('Error building DateSeparator: $e');
                          }
                        }
                      }

                      return Column(
                        children: [
                          if (dateSeparatorWidget != null) dateSeparatorWidget,
                          ImprovedMessageBubble(
                            message: message,
                            isCurrentUser: isCurrentUser,
                            isFirstInGroup: isFirstInGroup,
                            isLastInGroup: isLastInGroup,
                            showAvatar:
                                isLastInGroup, // Afficher l'avatar seulement à la fin du groupe
                            senderName: !isCurrentUser ? conv.user2Name : null,
                            onDelete: isCurrentUser
                                ? () =>
                                    _deleteMessage(messageService, message.id)
                                : null,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          // Zone de saisie avec indicateur de chargement
          Container(
            decoration: BoxDecoration(
              color: DramusColors.white,
              boxShadow: [
                BoxShadow(
                  color: DramusColors.darkText.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: AppSpacing.paddingMd,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageInputController,
                      maxLines: null,
                      enabled: !_isSending,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: _isSending
                            ? 'Envoi en cours...'
                            : 'Écrivez votre message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          borderSide: const BorderSide(
                            color: DramusColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          borderSide: const BorderSide(
                            color: DramusColors.border,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          borderSide: BorderSide(
                            color: DramusColors.border.withValues(alpha: 0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          borderSide: const BorderSide(
                            color: DramusColors.primaryTeal,
                            width: 2,
                          ),
                        ),
                        contentPadding:
                            AppSpacing.horizontalMd + AppSpacing.verticalMd,
                        filled: true,
                        fillColor: _isSending
                            ? DramusColors.lightGray
                            : DramusColors.lightBackground,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Material(
                    color: _isSending
                        ? DramusColors.secondaryText
                        : DramusColors.primaryTeal,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: InkWell(
                      onTap: _isSending
                          ? null
                          : () async {
                              if (messageInputController.text
                                  .trim()
                                  .isNotEmpty) {
                                final content =
                                    messageInputController.text.trim();
                                messageInputController.clear();

                                setState(() {
                                  _isSending = true;
                                });

                                try {
                                  final success =
                                      await messageService.sendMessage(
                                    receiverId: conv.userId2,
                                    content: content,
                                  );

                                  if (!success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: DramusColors.white,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Erreur lors de l\'envoi du message',
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor:
                                            DramusColors.notificationRed,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.md),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: DramusColors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Erreur réseau: ${e.toString()}',
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor:
                                            DramusColors.notificationRed,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.md),
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isSending = false;
                                    });
                                  }
                                }
                              }
                            },
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: Container(
                        padding: AppSpacing.paddingMd,
                        child: _isSending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: DramusColors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: DramusColors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(
      MessageService messageService, String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Supprimer le message'),
        content: const Text('Voulez-vous vraiment supprimer ce message ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: DramusColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: DramusColors.notificationRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await messageService.deleteMessage(messageId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error_outline,
                  color: DramusColors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  success
                      ? 'Message supprimé'
                      : 'Erreur lors de la suppression',
                ),
              ],
            ),
            backgroundColor:
                success ? DramusColors.saleGreen : DramusColors.notificationRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == 'Utilisateur') return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
