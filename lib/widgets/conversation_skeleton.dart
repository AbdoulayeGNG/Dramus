import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dramus/theme.dart';

/// Widget de chargement skeleton pour les conversations
class ConversationSkeleton extends StatelessWidget {
  final int itemCount;

  const ConversationSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 72,
      ),
      itemBuilder: (context, index) => _buildSkeletonItem(context),
    );
  }

  Widget _buildSkeletonItem(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: DramusColors.lightGray.withValues(alpha: 0.3),
      highlightColor: DramusColors.white.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            // Avatar skeleton
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: DramusColors.lightGray,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Contenu skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nom skeleton
                      Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: DramusColors.lightGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Heure skeleton
                      Container(
                        width: 40,
                        height: 12,
                        decoration: BoxDecoration(
                          color: DramusColors.lightGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Message skeleton
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: DramusColors.lightGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 180,
                    height: 14,
                    decoration: BoxDecoration(
                      color: DramusColors.lightGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
