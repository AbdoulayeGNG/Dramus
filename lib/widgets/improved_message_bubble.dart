import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dramus/models/message_model.dart';
import 'package:dramus/theme.dart';

/// Widget de bulle de message amélioré style Telegram
class ImprovedMessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final VoidCallback? onDelete;
  final bool showAvatar;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final String? senderName;

  const ImprovedMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onDelete,
    this.showAvatar = true,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isCurrentUser ? 60 : 12,
        right: isCurrentUser ? 12 : 60,
        top: isFirstInGroup ? 8 : 2,
        bottom: isLastInGroup ? 8 : 2,
      ),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar pour les messages reçus (à gauche)
          if (!isCurrentUser && showAvatar && isLastInGroup)
            _buildAvatar(context)
          else if (!isCurrentUser && showAvatar)
            const SizedBox(width: 32),

          const SizedBox(width: 8),

          // Bulle de message
          Flexible(
            child: GestureDetector(
              onLongPress: isCurrentUser && onDelete != null
                  ? () => _showMessageOptions(context)
                  : null,
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Nom de l'expéditeur (pour les messages reçus)
                  if (!isCurrentUser && isFirstInGroup && senderName != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Text(
                        senderName!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),

                  // Bulle de message
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isCurrentUser
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                DramusColors.primaryTeal,
                                DramusColors.deepTeal,
                              ],
                            )
                          : null,
                      color: isCurrentUser ? null : Theme.of(context).cardColor,
                      borderRadius: _getBorderRadius(),
                      boxShadow: [
                        BoxShadow(
                          color: isCurrentUser
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Contenu du message
                        Text(
                          message.content,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                    height: 1.4,
                                  ),
                        ),
                        const SizedBox(height: 4),

                        // Heure et statut de lecture
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(message.createdAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: isCurrentUser
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.color,
                                    fontSize: 11,
                                  ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.status == 'sent'
                                    ? Icons.done_rounded
                                    : Icons.done_all_rounded,
                                size: 16,
                                color: message.status == 'read'
                                    ? DramusColors.statusBlue
                                    : Colors.white.withValues(alpha: 0.6),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Avatar pour les messages envoyés (à droite) - optionnel
          if (isCurrentUser && showAvatar && isLastInGroup)
            const SizedBox(width: 0) // Pas d'avatar pour l'utilisateur actuel
          else if (isCurrentUser && showAvatar)
            const SizedBox(width: 0),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final initials = _getInitials(senderName ?? 'U');
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(initials),
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius() {
    const radius = 18.0;
    const smallRadius = 4.0;

    if (isCurrentUser) {
      return BorderRadius.only(
        topLeft: const Radius.circular(radius),
        topRight: Radius.circular(isFirstInGroup ? radius : smallRadius),
        bottomLeft: const Radius.circular(radius),
        bottomRight: Radius.circular(isLastInGroup ? smallRadius : radius),
      );
    } else {
      return BorderRadius.only(
        topLeft: Radius.circular(isFirstInGroup ? radius : smallRadius),
        topRight: const Radius.circular(radius),
        bottomLeft: Radius.circular(isLastInGroup ? smallRadius : radius),
        bottomRight: const Radius.circular(radius),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else {
      return DateFormat('dd/MM HH:mm').format(dateTime);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  List<Color> _getGradientColors(String initials) {
    final hash = initials.codeUnits.fold(0, (prev, curr) => prev + curr);
    final gradients = [
      [DramusColors.primaryTeal, DramusColors.deepTeal],
      [DramusColors.saleGreen, DramusColors.primaryTeal],
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
    ];
    return gradients[hash % gradients.length];
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: DramusColors.notificationRed,
                ),
                title: const Text(
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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget pour afficher un séparateur de date
class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDate(date),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Aujourd\'hui';
    } else if (messageDate == yesterday) {
      return 'Hier';
    } else if (date.year == now.year) {
      return DateFormat('d MMMM', 'fr_FR').format(date);
    } else {
      return DateFormat('d MMMM yyyy', 'fr_FR').format(date);
    }
  }
}
