import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/core/state/theme_controller.dart';
import 'package:dramus/screens/agence/edit_profile_screen.dart';
import 'package:dramus/screens/agence/help_center_screen.dart';
import 'package:dramus/services/agent_service.dart';
import 'package:dramus/services/auth_service.dart';
import 'package:dramus/services/favorites_service.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/screens/auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSectionHeader(context, 'Compte'),
            _buildSettingsItem(
              context,
              icon: Icons.person_outline,
              title: 'Modifier mon profil',
              subtitle: 'Nom, prénom, téléphone',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildSettingsItem(
              context,
              icon: Icons.lock_outline,
              title: 'Mot de passe',
              subtitle: 'Changer votre mot de passe',
              onTap: () => _showChangePasswordDialog(context),
            ),
            _buildDivider(),
            _buildSettingsItem(
              context,
              icon: Icons.delete_outline,
              title: 'Supprimer mon compte',
              subtitle: 'Action irréversible',
              textColor: DramusColors.notificationRed,
              onTap: () => _showDeleteAccountDialog(context),
            ),
            _buildSectionHeader(context, 'Application'),
            Consumer<ThemeController>(
              builder: (context, themeController, child) {
                return _buildSwitchItem(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: 'Mode Sombre',
                  subtitle: 'Basculer entre le thème clair et sombre',
                  value: themeController.isDarkMode,
                  onChanged: (val) => themeController.toggleDarkMode(val),
                );
              },
            ),
            _buildDivider(),
            _buildSettingsItem(
              context,
              icon: Icons.language,
              title: 'Langue',
              trailing: Text(
                'Français',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              onTap: () {},
            ),
            _buildDivider(),
            _buildSettingsItem(
              context,
              icon: Icons.help_outline,
              title: 'Aide & Support',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HelpCenterScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: AppSpacing.xxl),
            Center(
              child: Text(
                'Version 1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DramusColors.secondaryText,
                    ),
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).cardColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: textColor ?? DramusColors.primaryTeal, size: 24),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textColor,
                          ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing
              .sm, // Un peu moins de padding vertical car Switch est haut
        ),
        child: Row(
          children: [
            Icon(icon, color: DramusColors.primaryTeal, size: 24),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: DramusColors.primaryTeal,
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(
            'Modifier le mot de passe',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Entrez votre mot de passe actuel et votre nouveau mot de passe.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe actuel',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(
                            () => obscureCurrent = !obscureCurrent),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Requis' : null,
                  ),
                  SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      prefixIcon: const Icon(Icons.lock_open_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscureNew = !obscureNew),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      if (value.length < 8) return 'Minimum 8 caractères';
                      return null;
                    },
                  ),
                  SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le nouveau mot de passe',
                      prefixIcon: const Icon(Icons.check_circle_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => isLoading = true);
                        try {
                          final success =
                              await AuthService.instance.updatePassword(
                            currentPasswordController.text,
                            newPasswordController.text,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Mot de passe mis à jour avec succès !'
                                    : 'Erreur lors de la mise à jour (vérifiez votre mot de passe actuel)'),
                                backgroundColor: success
                                    ? DramusColors.saleGreen
                                    : DramusColors.notificationRed,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Une erreur est survenue : $e'),
                                backgroundColor: DramusColors.notificationRed,
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setDialogState(() => isLoading = false);
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: DramusColors.primaryTeal,
                foregroundColor: DramusColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DramusColors.white,
                      ),
                    )
                  : const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext parentContext) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool obscurePwd = true;

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(
            'Supprimer mon compte (Irreversible)',
            style: Theme.of(parentContext).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DramusColors.notificationRed,
                ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cette action est irréversible. Toutes vos données seront perdues. Veuillez entrer votre mot de passe pour confirmer.',
                    style:
                        Theme.of(parentContext).textTheme.bodySmall?.copyWith(
                              color: Theme.of(parentContext)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePwd,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePwd ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscurePwd = !obscurePwd),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      return null;
                    },
                    onChanged: (val) {
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: Text(
                'Annuler',
                style: TextStyle(
                    color:
                        Theme.of(parentContext).colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: (isLoading || passwordController.text.isEmpty)
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => isLoading = true);
                        try {
                          final success = await AuthService.instance
                              .deleteAccount(passwordController.text);

                          if (parentContext.mounted) {
                            if (success) {
                              Navigator.pop(dialogContext);
                              try {
                                parentContext.read<ListingService>().reset();
                                parentContext
                                    .read<FavoritesService>()
                                    .clearFavorites();
                                parentContext.read<MessageService>().clear();
                                parentContext.read<AgentService>().clear();
                              } catch (e) {
                                debugPrint(
                                    'Erreur lors du nettoyage des caches: $e');
                              }
                              await parentContext
                                  .read<AuthController>()
                                  .signOut(skipServerLogout: true);

                              if (parentContext.mounted) {
                                Navigator.of(parentContext).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Erreur lors de la suppression'),
                                  backgroundColor: DramusColors.notificationRed,
                                ),
                              );
                              setDialogState(() => isLoading = false);
                            }
                          }
                        } catch (e) {
                          if (parentContext.mounted) {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Text('Une erreur est survenue : $e'),
                                backgroundColor: DramusColors.notificationRed,
                              ),
                            );
                            setDialogState(() => isLoading = false);
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: DramusColors.notificationRed,
                foregroundColor: DramusColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DramusColors.white,
                      ),
                    )
                  : const Text('Supprimer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, indent: 56);
  }
}
