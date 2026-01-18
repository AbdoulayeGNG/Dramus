import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/models/message_model.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/header_section.dart';
import 'package:dramus/widgets/message_bubble.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String? _selectedConversationId;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Consumer<MessageService>(
      builder: (context, messageService, _) {
        return isMobile
            ? _buildMobileLayout(context, messageService)
            : _buildDesktopLayout(context, messageService);
      },
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, MessageService messageService) {
    if (_selectedConversationId != null) {
      final conv = messageService.conversations.firstWhere(
        (c) => c.id == _selectedConversationId,
        orElse: () => messageService.conversations.first,
      );
      return _buildChatView(context, messageService, conv);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //HeaderSection(title: 'Messages'),
        Expanded(
          child: _buildConversationsList(context, messageService),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, MessageService messageService) {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: Container(
            color: DramusColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderSection(title: 'Messages', isDark: false),
                Expanded(
                  child: _buildConversationsList(context, messageService),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _selectedConversationId != null
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
                        size: 48,
                        color: DramusColors.secondaryText,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        'Sélectionnez une conversation',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    if (messageService.conversations.isEmpty) {
      return Center(
        child: Text('Aucune conversation',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    return ListView.builder(
      itemCount: messageService.conversations.length,
      itemBuilder: (context, index) {
        final conv = messageService.conversations[index];
        final isSelected = _selectedConversationId == conv.id;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedConversationId = conv.id);
            messageService.markAsRead(conv.id);
          },
          child: Container(
            color:
                isSelected ? DramusColors.lightBackground : DramusColors.white,
            padding: AppSpacing.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?img=${index}',
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  conv.user2Name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              Text(
                                _formatTime(conv.updatedAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: DramusColors.secondaryText,
                                    ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            conv.lastMessage.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: conv.lastMessage.read
                                          ? DramusColors.secondaryText
                                          : DramusColors.darkText,
                                      fontWeight: conv.lastMessage.read
                                          ? FontWeight.w400
                                          : FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Divider(
                  color: DramusColors.border.withValues(alpha: 0.5),
                  height: 0.5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatView(
      BuildContext context, MessageService messageService, Conversation conv) {
    final messages = messageService.getMessagesForConversation(conv.id);
    final messageInputController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: DramusColors.darkPetroleum,
        title: Text(conv.user2Name),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                return MessageBubble(
                  message: message,
                  isCurrentUser: message.senderId == 'user1',
                );
              },
            ),
          ),
          Container(
            color: DramusColors.white,
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageInputController,
                    decoration: InputDecoration(
                      hintText: 'Votre message...',
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
                      contentPadding:
                          AppSpacing.horizontalMd + AppSpacing.verticalSm,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                GestureDetector(
                  onTap: () {
                    if (messageInputController.text.isNotEmpty) {
                      messageService.sendMessage(
                        conv.id,
                        'user1',
                        'Vous',
                        conv.userId2,
                        messageInputController.text,
                      );
                      messageInputController.clear();
                    }
                  },
                  child: Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: DramusColors.primaryTeal,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Icon(
                      Icons.send,
                      color: DramusColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (date == yesterday) {
      return 'Hier';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
