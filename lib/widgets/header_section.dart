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
      color: isDark ? DramusColors.darkPetroleum : DramusColors.white,
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
                  color: isDark ? DramusColors.white : DramusColors.darkText,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? DramusColors.lightGray
                        : DramusColors.secondaryText,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
