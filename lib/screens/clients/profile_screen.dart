import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/models/user_model.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/custom_button.dart';
import 'package:dramus/screens/auth/login_screen.dart';
import 'package:dramus/services/auth_service.dart';
import 'package:dramus/screens/clients/favorites_screen.dart';
import 'package:dramus/screens/clients/help_center_screen.dart';
import 'package:dramus/screens/clients/about_screen.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/services/favorites_service.dart';
import 'package:dramus/services/agent_service.dart';
import 'package:dramus/services/notification_service.dart';
import 'package:dramus/core/state/theme_controller.dart';
import 'package:dramus/screens/clients/edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _getRoleLabel(String role) {
    switch (role) {
      case 'individual':
        return 'Particulier';
      case 'agency':
        return 'Agence';
      case 'agent':
        return 'Agent';
      case 'admin':
        return 'Administrateur';
      default:
        return role;
    }
  }

  Future<void> _handleLogout(
      BuildContext context, AuthController authController) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Déconnexion',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _performLogout(context, authController);
    }
  }

  Future<void> _performLogout(
      BuildContext context, AuthController authController,
      {bool skipServerLogout = false}) async {
    // Réinitialiser tous les services avant la déconnexion locale
    if (context.mounted) {
      try {
        context.read<ListingService>().reset();
        context.read<FavoritesService>().clearFavorites();
        context.read<MessageService>().clear();
        context.read<AgentService>().clear();

        // NotificationService peut parfois être en cours d'initialisation
        try {
          final notifs = context.read<NotificationService>();
          notifs.unregisterToken();
          notifs.reset();
        } catch (e) {
          debugPrint('Could not reset NotificationService: $e');
        }
      } catch (e) {
        debugPrint('Error during services reset: $e');
      }
    }

    await authController.signOut(skipServerLogout: skipServerLogout);

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        final user = authController.user;

        if (user == null) {
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: AppSpacing.xxl),
                SizedBox(height: AppSpacing.xxl),
                Icon(
                  Icons.account_circle,
                  size: 100,
                  color: Theme.of(context).disabledColor,
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Mode Invité',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Connectez-vous pour profiter de toutes les fonctionnalités.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                SizedBox(height: AppSpacing.xxl),
                Padding(
                  padding: AppSpacing.paddingLg,
                  child: CustomButton(
                    label: 'Se connecter ou s\'inscrire',
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false);
                    },
                    isFullWidth: true,
                  ),
                ),
                Padding(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assistance',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      _buildMenuItem(
                        context,
                        icon: Icons.help_outline,
                        label: 'Centre d\'aide',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const HelpCenterScreen()),
                          );
                        },
                      ),
                      SizedBox(height: AppSpacing.md),
                      _buildMenuItem(
                        context,
                        icon: Icons.info_outline,
                        label: 'À propos',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const AboutScreen()),
                          );
                        },
                      ),
                      SizedBox(height: AppSpacing.xxl),
                      Text(
                        'Application',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Consumer<ThemeController>(
                        builder: (context, themeController, child) {
                          return _buildSwitchItem(
                            context,
                            icon: Icons.dark_mode_outlined,
                            title: 'Mode Sombre',
                            value: themeController.isDarkMode,
                            onChanged: (val) =>
                                themeController.toggleDarkMode(val),
                          );
                        },
                      ),
                      SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(context, user),
              Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileInfo(context, user),
                    SizedBox(height: AppSpacing.xxl),
                    _buildMenuSection(context, authController),
                    SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primary,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.1),
            backgroundImage:
                user.avatar.isNotEmpty ? CachedNetworkImageProvider(user.avatar) : null,
            child: user.avatar.isEmpty
                ? Text(
                    user.initials,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : null,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              _getRoleLabel(user.role),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations personnelles',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.lg),
        _buildInfoCard(
          context,
          icon: Icons.mail_outline,
          label: 'Email',
          value: user.email,
        ),
        SizedBox(height: AppSpacing.md),
        if (user.phone.isNotEmpty) ...[
          _buildInfoCard(
            context,
            icon: Icons.phone_outlined,
            label: 'Téléphone',
            value: user.phone,
          ),
          SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
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

  Widget _buildMenuSection(
      BuildContext context, AuthController authController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.lg),
        _buildMenuItem(
          context,
          icon: Icons.person_outline,
          label: 'Modifier mon profil',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const ClientEditProfileScreen()),
            );
          },
        ),
        SizedBox(height: AppSpacing.md),
        _buildMenuItem(
          context,
          icon: Icons.favorite_outline,
          label: 'Mes favoris',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            );
          },
        ),
        SizedBox(height: AppSpacing.md),
        _buildMenuItem(
          context,
          icon: Icons.lock_reset_outlined,
          label: 'Modifier le mot de passe',
          onTap: () => _showChangePasswordDialog(context),
        ),
        SizedBox(height: AppSpacing.md),
        _buildMenuItem(
          context,
          icon: Icons.help_outline,
          label: 'Centre d\'aide',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
            );
          },
        ),
        SizedBox(height: AppSpacing.md),
        _buildMenuItem(
          context,
          icon: Icons.info_outline,
          label: 'À propos',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            );
          },
        ),
        SizedBox(height: AppSpacing.md),
        _buildMenuItem(
          context,
          icon: Icons.delete_outline,
          label: 'Supprimer mon compte',
          textColor: DramusColors.notificationRed,
          onTap: () => _showDeleteAccountDialog(context),
        ),
        SizedBox(height: AppSpacing.xxl),
        Text(
          'Application',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.lg),
        Consumer<ThemeController>(
          builder: (context, themeController, child) {
            return _buildSwitchItem(
              context,
              icon: Icons.dark_mode_outlined,
              title: 'Mode Sombre',
              value: themeController.isDarkMode,
              onChanged: (val) => themeController.toggleDarkMode(val),
            );
          },
        ),
        SizedBox(height: AppSpacing.xxl),
        CustomButton(
          label: 'Déconnexion',
          onPressed: () => _handleLogout(context, authController),
          variant: ButtonVariant.danger,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Row(
            children: [
              Icon(icon,
                  color: textColor ?? Theme.of(context).colorScheme.primary),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
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
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Une erreur est survenue : $e'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
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
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
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
            'Supprimer mon compte',
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
                              await _performLogout(parentContext,
                                  parentContext.read<AuthController>(),
                                  skipServerLogout: true);
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
}
