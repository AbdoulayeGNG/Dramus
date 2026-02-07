import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/custom_button.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: DramusColors.notificationRed,
              fontWeight: FontWeight.bold,
            ),
      ),
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Annuler',
            style: TextStyle(color: DramusColors.secondaryText),
          ),
        ),
        CustomButton(
          label: 'Supprimer',
          onPressed: onConfirm,
          variant: ButtonVariant.danger,
          height: 36,
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}
