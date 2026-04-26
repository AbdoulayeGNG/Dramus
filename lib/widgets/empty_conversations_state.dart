import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';

/// Widget d'état vide amélioré pour les conversations
class EmptyConversationsState extends StatelessWidget {
  final bool isSearching;
  final String? customMessage;
  final IconData? customIcon;

  const EmptyConversationsState({
    super.key,
    this.isSearching = false,
    this.customMessage,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône animée
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DramusColors.primaryTeal.withValues(alpha: 0.1),
                      DramusColors.deepTeal.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  customIcon ??
                      (isSearching ? Icons.search_off : Icons.forum_outlined),
                  size: 56,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Titre
            Text(
              isSearching ? 'Aucun résultat' : 'Aucune conversation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              customMessage ??
                  (isSearching
                      ? 'Essayez avec d\'autres mots-clés'
                      : 'Les conversations avec vos contacts\napparaîtront ici'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Illustration décorative
            if (!isSearching)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDecorativeCircle(
                    DramusColors.primaryTeal.withValues(alpha: 0.2),
                    24,
                  ),
                  const SizedBox(width: 8),
                  _buildDecorativeCircle(
                    DramusColors.saleGreen.withValues(alpha: 0.2),
                    32,
                  ),
                  const SizedBox(width: 8),
                  _buildDecorativeCircle(
                    DramusColors.premiumYellow.withValues(alpha: 0.2),
                    24,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle(Color color, double size) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
