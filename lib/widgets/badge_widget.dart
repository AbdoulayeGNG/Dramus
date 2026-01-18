import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';

class BadgeWidget extends StatelessWidget {
  final String label;
  final BadgeType type;

  const BadgeWidget({
    super.key,
    required this.label,
    required this.type,
  });

  Color get backgroundColor {
    switch (type) {
      case BadgeType.sale:
        return DramusColors.saleGreen;
      case BadgeType.rent:
        return DramusColors.rentYellow;
      case BadgeType.premium:
        return DramusColors.premiumYellow;
      case BadgeType.notification:
        return DramusColors.notificationRed;
    }
  }

  Color get textColor {
    switch (type) {
      case BadgeType.sale:
        return DramusColors.white;
      case BadgeType.rent:
        return DramusColors.darkText;
      case BadgeType.premium:
        return DramusColors.darkText;
      case BadgeType.notification:
        return DramusColors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.horizontalSm + AppSpacing.verticalXs,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

enum BadgeType { sale, rent, premium, notification }
