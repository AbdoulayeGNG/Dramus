import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dramus/models/message_model.dart';
import 'package:dramus/theme.dart';
import 'package:intl/intl.dart';

/// Widget amélioré pour afficher une conversation dans la liste
class ConversationTile extends StatefulWidget {
  final Conversation conversation;
  final bool isSelected;
  final bool hasUnread;
  final VoidCallback onTap;
  final String? currentUserId;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.isSelected,
    required this.hasUnread,
    required this.onTap,
    this.currentUserId,
  });

  @override
  State<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) {
          _animationController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _animationController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : _isHovered
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.surface,
              border: Border(
                left: BorderSide(
                  color: widget.isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                // Avatar avec effet de dégradé
                _buildAvatar(),
                const SizedBox(width: 12),
                // Contenu de la conversation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 4),
                      _buildLastMessage(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final hasAvatar = widget.conversation.user2Avatar != null &&
        widget.conversation.user2Avatar!.isNotEmpty;

    return Stack(
      children: [
        // Avatar principal
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: widget.isSelected || _isHovered
                ? [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: hasAvatar ? _buildImageAvatar() : _buildGradientAvatar(),
        ),
        // Badge de message non lu
        if (widget.hasUnread)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onError,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageAvatar() {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: widget.conversation.user2Avatar!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildGradientAvatar(),
        ),
      ),
    );
  }

  Widget _buildGradientAvatar() {
    final initials = _getInitials(widget.conversation.user2Name);
    final colors = _getGradientColors(initials);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Nom de l'utilisateur
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  _getUserName(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: widget.hasUnread
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: widget.hasUnread
                            ? Theme.of(context).textTheme.titleMedium?.color
                            : Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.color
                                ?.withValues(alpha: 0.85),
                      ),
                ),
              ),
              // Icône de vérification (optionnel)
              if (widget.conversation.user2Name.isNotEmpty &&
                  widget.conversation.user2Name != 'Utilisateur')
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.verified,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Horodatage
        _buildTimestamp(context),
      ],
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: widget.hasUnread
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _formatTime(widget.conversation.updatedAt),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: widget.hasUnread
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: widget.hasUnread ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11,
            ),
      ),
    );
  }

  Widget _buildLastMessage(BuildContext context) {
    final isCurrentUserSender =
        widget.conversation.lastMessage.senderId == widget.currentUserId;
    final hasPropertyId = widget.conversation.lastMessage.propertyId != null &&
        widget.conversation.lastMessage.propertyId!.isNotEmpty;

    return Row(
      children: [
        // Icône de statut d'envoi
        if (isCurrentUserSender) ...[
          Icon(
            widget.conversation.lastMessage.read
                ? Icons.done_all_rounded
                : Icons.done_rounded,
            size: 14,
            color: widget.conversation.lastMessage.read
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
        ],
        // Icône de type de message
        if (hasPropertyId) ...[
          Icon(
            Icons.home_rounded,
            size: 14,
            color: DramusColors.premiumYellow,
          ),
          const SizedBox(width: 4),
        ],
        // Contenu du message
        Expanded(
          child: Text(
            widget.conversation.lastMessage.content.isNotEmpty
                ? widget.conversation.lastMessage.content
                : hasPropertyId
                    ? '📍 Message à propos d\'une propriété'
                    : 'Aucun message',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: widget.hasUnread
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.8)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight:
                      widget.hasUnread ? FontWeight.w500 : FontWeight.w400,
                  height: 1.3,
                ),
          ),
        ),
      ],
    );
  }

  String _getUserName() {
    if (widget.conversation.user2Name.isNotEmpty &&
        widget.conversation.user2Name != 'Utilisateur') {
      return widget.conversation.user2Name;
    }
    return 'Utilisateur inconnu';
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == 'Utilisateur') return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  List<Color> _getGradientColors(String initials) {
    // Générer des couleurs basées sur les initiales
    final hash = initials.codeUnits.fold(0, (prev, curr) => prev + curr);
    final gradients = [
      [DramusColors.primaryTeal, DramusColors.deepTeal],
      [DramusColors.saleGreen, DramusColors.primaryTeal],
      [DramusColors.premiumYellow, const Color(0xFFFFA000)],
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
    ];
    return gradients[hash % gradients.length];
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    if (date == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (date == yesterday) {
      return 'Hier';
    } else if (date.isAfter(weekAgo)) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[dateTime.weekday - 1];
    } else if (date.year == now.year) {
      return DateFormat('dd MMM', 'fr_FR').format(dateTime);
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }
}
