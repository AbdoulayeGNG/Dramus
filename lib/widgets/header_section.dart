import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';

class HeaderSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isDark;

  const HeaderSection({
    super.key,
    required this.title,
    this.subtitle,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isDark
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
