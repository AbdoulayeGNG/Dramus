import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dramus/models/message_model.dart';
import 'package:dramus/theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? DramusColors.primaryTeal
                    : DramusColors.lightGray,
                borderRadius: BorderRadius.circular(AppRadius.lg),
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
            SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: DramusColors.secondaryText,
                      ),
                ),
                if (isCurrentUser && message.read) ...[
                  SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.done_all,
                    size: 12,
                    color: DramusColors.primaryTeal,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
