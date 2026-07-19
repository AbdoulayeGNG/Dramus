import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48,
  });

  Color get _backgroundColor {
    switch (variant) {
      case ButtonVariant.primary:
        return DramusColors.primaryTeal;
      case ButtonVariant.secondary:
        return DramusColors.deepTeal;
      case ButtonVariant.outline:
        return Colors.transparent;
      case ButtonVariant.danger:
        return DramusColors.notificationRed;
    }
  }

  Color get _textColor {
    switch (variant) {
      case ButtonVariant.primary:
        return DramusColors.white;
      case ButtonVariant.secondary:
        return DramusColors.white;
      case ButtonVariant.outline:
        return DramusColors.primaryTeal;
      case ButtonVariant.danger:
        return DramusColors.white;
    }
  }

  BorderSide? get _borderSide {
    if (variant == ButtonVariant.outline) {
      return BorderSide(
        color: DramusColors.primaryTeal,
        width: 2,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final buttonContent = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_textColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: _textColor, size: 18),
                SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _textColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _backgroundColor,
          foregroundColor: _textColor,
          side: _borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          elevation: 0,
          disabledBackgroundColor: DramusColors.mediumGray,
          disabledForegroundColor: DramusColors.white,
        ),
        child: buttonContent,
      ),
    );
  }
}

enum ButtonVariant { primary, secondary, outline, danger }
