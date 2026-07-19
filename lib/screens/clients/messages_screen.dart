import 'dart:async';

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
  final String? preselectedConversationId;
  final String? propertyId;
  final String? ownerName;
  final String? prefilledMessage;
  final VoidCallback? onConversationOpened;

  const MessagesScreen({
    super.key,
    this.preselectedConversationId,
    this.propertyId,
    this.ownerName,
    this.prefilledMessage,
    this.onConversationOpened,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String? _selectedConversationId;
  bool _isInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _searchQuery = '';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Si les conversations ont déjà été chargées, ne pas afficher le loading
    final messageService = context.read<MessageService>();
    _isInitialized = messageService.hasInitialLoad ||
        messageService.conversations.isNotEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMessages();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _ensurePreselectedConversation(
      MessageService messageService) async {
    final preselected = widget.preselectedConversationId;
    if (preselected == null) return;

    // Si la conversation n'existe pas encore, la créer temporairement
    final exists = messageService.conversations
        .any((c) => c.id == preselected || c.userId2 == preselected);
    if (!exists) {
      await messageService.startConversation(
          preselected, widget.ownerName ?? 'Propriétaire');
    }

    if (!mounted) return;
    setState(() {
      _selectedConversationId = preselected;
      if (widget.prefilledMessage != null) {
        _messageController.text = widget.prefilledMessage!;
      }
    });

    messageService.loadConversation(preselected);
    messageService.setActiveConversation(preselected);
    widget.onConversationOpened?.call();
  }

  Future<void> _initializeMessages() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final messageService = Provider.of<MessageService>(context, listen: false);

    if (authController.user != null) {
      messageService.setCurrentUserId(authController.user!.id);

      final hasData = messageService.conversations.isNotEmpty ||
          messageService.hasInitialLoad;

      if (hasData) {
        await _ensurePreselectedConversation(messageService);

        if (!mounted) return;
        setState(() {
          _isInitialized = true;
        });

        // Rafraîchir en arrière-plan si un chargement n'est pas déjà en cours
        if (!messageService.isLoading) {
          unawaited(messageService.loadConversations());
        }
        return;
      }

      await messageService.loadConversations();

      await _ensurePreselectedConversation(messageService);

      if (!mounted) return;
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
            backgroundColor: Theme.of(context).colorScheme.surface,
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarBackgroundColor =
        isDark ? theme.appBarTheme.backgroundColor : theme.colorScheme.primary;
    final appBarForegroundColor = isDark
        ? theme.appBarTheme.foregroundColor
        : theme.colorScheme.onPrimary;

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
        // Conversation non trouvée, créer une conversation temporaire
        final authController =
            Provider.of<AuthController>(context, listen: false);
        conv = Conversation(
          id: _selectedConversationId!,
          userId1: authController.user?.id ?? '',
          user1Name: authController.user?.fullName ?? '',
          userId2: _selectedConversationId!,
          user2Name: widget.ownerName ?? 'Propriétaire',
          lastMessage: Message(
            id: '',
            senderId: '',
            receiverId: '',
            content: '',
            propertyId: widget.propertyId,
            read: true,
            createdAt: DateTime.now(),
          ),
          updatedAt: DateTime.now(),
        );
      }

      return _buildChatView(context, messageService, conv);
    }

    // Vue de la liste des conversations avec AppBar
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
        title: Text(
          'Messages',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: appBarForegroundColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        elevation: 0,
        actions: [
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
          IconButton(
            icon: Icon(Icons.refresh, color: appBarForegroundColor),
            onPressed: () => messageService.loadConversations(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: Theme.of(context).colorScheme.surface,
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
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                fillColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.05),
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
            color: Theme.of(context).colorScheme.surface,
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
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
          child: _selectedConversationId != null
              ? () {
                  Conversation? conv;
                  try {
                    conv = messageService.conversations.firstWhere(
                      (c) =>
                          c.id == _selectedConversationId ||
                          c.userId2 == _selectedConversationId ||
                          c.userId1 == _selectedConversationId,
                    );
                  } catch (e) {
                    final authController =
                        Provider.of<AuthController>(context, listen: false);
                    conv = Conversation(
                      id: _selectedConversationId!,
                      userId1: authController.user?.id ?? '',
                      user1Name: authController.user?.fullName ?? 'Vous',
                      userId2: _selectedConversationId!,
                      user2Name: widget.ownerName ?? 'Propriétaire',
                      lastMessage: Message(
                        id: '',
                        senderId: '',
                        receiverId: '',
                        content: '',
                        propertyId: widget.propertyId,
                        read: true,
                        createdAt: DateTime.now(),
                      ),
                      updatedAt: DateTime.now(),
                    );
                  }
                  return _buildChatView(context, messageService, conv);
                }()
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline,
                        size: 80,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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

    // État de chargement avec skeleton (uniquement au premier chargement)
    if (!messageService.hasInitialLoad &&
        messageService.isLoading &&
        messageService.conversations.isEmpty) {
      return const ConversationSkeleton(itemCount: 6);
    }

    // État vide
    if (filteredConversations.isEmpty) {
      return EmptyConversationsState(
        isSearching: _searchQuery.isNotEmpty,
        customMessage: _searchQuery.isNotEmpty
            ? 'Aucune conversation ne correspond à votre recherche'
            : 'Contactez un propriétaire pour commencer une conversation',
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
            setState(() {
              _selectedConversationId = conv.id;
            });
            messageService.setActiveConversation(conv.id);
            messageService.loadConversation(conv.id);
          },
        );
      },
    );
  }

  Widget _buildChatView(
      BuildContext context, MessageService messageService, Conversation conv) {
    final messages = messageService.getMessagesForConversation(conv.id);
    debugPrint('ChatView: id=${conv.id}, msg_count=${messages.length}');
    final scrollController = ScrollController();
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUserId = authController.user?.id ?? '';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarBackgroundColor =
        isDark ? theme.appBarTheme.backgroundColor : theme.colorScheme.primary;
    final appBarForegroundColor = isDark
        ? theme.appBarTheme.foregroundColor
        : theme.colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
        leading: MediaQuery.of(context).size.width < 900
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: appBarForegroundColor),
                onPressed: () {
                  setState(() => _selectedConversationId = null);
                  messageService.setActiveConversation(null);
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
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: conv.user2Avatar!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: appBarForegroundColor,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Text(
                            _getInitials(conv.user2Name),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: appBarForegroundColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Text(
                      _getInitials(conv.user2Name),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: appBarForegroundColor,
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
                        : 'Utilisateur inconnu',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: appBarForegroundColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: appBarForegroundColor),
            onPressed: () => messageService.loadConversation(conv.id),
          ),
        ],
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

                      final currentIndex = messages.length - 1 - index;

                      // Vérifier si le message précédent est du même auteur
                      bool isFirstInGroup = true;
                      if (currentIndex > 0) {
                        final previousMessage = messages[currentIndex - 1];
                        if (previousMessage.senderId.trim() ==
                            senderIdNormalized) {
                          isFirstInGroup = false;
                        }
                      }

                      // Vérifier si le message suivant est du même auteur
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
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.05),
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
                      controller: _messageController,
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
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.1)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Material(
                    color: _isSending
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: InkWell(
                      onTap: _isSending
                          ? null
                          : () async {
                              if (_messageController.text.trim().isNotEmpty) {
                                final content = _messageController.text.trim();
                                _messageController.clear();

                                setState(() {
                                  _isSending = true;
                                });

                                try {
                                  final success =
                                      await messageService.sendMessage(
                                    receiverId: conv.userId2,
                                    content: content,
                                    propertyId: widget.propertyId,
                                  );

                                  if (success && mounted) {
                                    // Recharge les conversations pour récupérer
                                    // le vrai nom du propriétaire depuis le backend
                                    await messageService.loadConversations();

                                    // Retrouver la vraie conversation créée
                                    final realConv = messageService
                                        .conversations
                                        .where((c) =>
                                            c.userId2 == conv.userId2 ||
                                            c.userId1 == conv.userId2 ||
                                            c.id == conv.id)
                                        .firstOrNull;

                                    if (realConv != null && mounted) {
                                      setState(() {
                                        _selectedConversationId = realConv.id;
                                      });
                                      messageService
                                          .loadConversation(realConv.id);
                                    }
                                  } else if (!success && mounted) {
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
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                color: Theme.of(context).colorScheme.onPrimary,
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
    bool isDeleting = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            title: const Text('Supprimer le message'),
            content: const Text('Voulez-vous vraiment supprimer ce message ?'),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: isDeleting
                        ? DramusColors.secondaryText.withValues(alpha: 0.5)
                        : DramusColors.secondaryText,
                  ),
                ),
              ),
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        final success =
                            await messageService.deleteMessage(messageId);
                        if (context.mounted) {
                          Navigator.pop(context, success);
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DramusColors.notificationRed,
                        ),
                      )
                    : Text(
                        'Supprimer',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: DramusColors.white,
              ),
              const SizedBox(width: 8),
              const Text('Message supprimé'),
            ],
          ),
          backgroundColor: DramusColors.saleGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
    } else if (result == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: DramusColors.white,
              ),
              const SizedBox(width: 8),
              const Text('Erreur lors de la suppression'),
            ],
          ),
          backgroundColor: DramusColors.notificationRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == 'Utilisateur') return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
