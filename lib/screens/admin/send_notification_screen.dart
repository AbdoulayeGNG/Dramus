import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/services/notification_service.dart';
import 'package:dramus/theme.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _usersController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _usersController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);

      await notificationService.sendNotification(
        _titleController.text.trim(),
        _bodyController.text.trim(),
        targetUserIds: _usersController.text.trim().isNotEmpty
            ? _usersController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification envoyée avec succès'),
            backgroundColor: DramusColors.notificationGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: DramusColors.notificationRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DramusColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Envoyer une notification',
          style: TextStyle(
            color: DramusColors.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: DramusColors.white,
        foregroundColor: DramusColors.darkText,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Promo spéciale',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Titre requis' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Profitez de -20%...',
                ),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Message requis' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _usersController,
                decoration: const InputDecoration(
                  labelText: 'ID Utilisateurs (optionnel)',
                  hintText: '1, 2, 3 (laisser vide pour tous)',
                  border: OutlineInputBorder(),
                  helperText: 'Séparez les IDs par des virgules pour cibler',
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: _isLoading ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DramusColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'ENVOYER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
