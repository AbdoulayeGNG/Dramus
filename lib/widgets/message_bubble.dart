import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dramus/models/message_model.dart';
import 'package:dramus/theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.md,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: isCurrentUser && onDelete != null
                  ? () => _showMessageOptions(context)
                  : null,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? DramusColors.primaryTeal
                      : DramusColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                    bottomLeft: Radius.circular(
                      isCurrentUser ? AppRadius.lg : AppRadius.sm,
                    ),
                    bottomRight: Radius.circular(
                      isCurrentUser ? AppRadius.sm : AppRadius.lg,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DramusColors.darkText.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isCurrentUser
                            ? DramusColors.white
                            : DramusColors.darkText,
                      ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: DramusColors.secondaryText,
                          fontSize: 10,
                        ),
                  ),
                  if (isCurrentUser) ...[ 
                    SizedBox(width: AppSpacing.xs),
                    Icon(
                      message.read ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.read 
                          ? DramusColors.primaryTeal
                          : DramusColors.secondaryText,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: DramusColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DramusColors.mediumGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: DramusColors.notificationRed,
                ),
                title: Text(
                  'Supprimer le message',
                  style: TextStyle(
                    color: DramusColors.notificationRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (onDelete != null) {
                    onDelete!();
                  }
                },
              ),
              SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
