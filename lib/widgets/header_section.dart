import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';

class HeaderSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isDark;
  final Widget? child;
  final EdgeInsetsGeometry padding;

  const HeaderSection({
    super.key,
    required this.title,
    this.subtitle,
    this.isDark = true,
    this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xl,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surface,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: isDark
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
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
          if (child != null) ...[
            SizedBox(height: AppSpacing.lg),
            child!,
          ],
        ],
      ),
    );
  }
}
