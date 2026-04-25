import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/models/user_model.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/custom_button.dart';
import 'package:dramus/screens/auth/login_screen.dart';
import 'package:dramus/services/auth_service.dart';
import 'package:dramus/screens/clients/favorites_screen.dart';
import 'package:dramus/screens/clients/help_center_screen.dart';
import 'package:dramus/screens/clients/about_screen.dart';

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
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: DramusColors.notificationRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authController.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        final user = authController.user;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
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
      color: DramusColors.darkPetroleum,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: DramusColors.primaryTeal,
            backgroundImage:
                user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
            child: user.avatar.isEmpty
                ? Text(
                    user.initials,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: DramusColors.white,
                    ),
                  )
                : null,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: DramusColors.white,
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
              color: DramusColors.primaryTeal,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              _getRoleLabel(user.role),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: DramusColors.white,
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
        side: const BorderSide(color: DramusColors.border),
      ),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            Icon(icon, color: DramusColors.primaryTeal),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: DramusColors.secondaryText,
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
          icon: Icons.home_outlined,
          label: 'Mes annonces',
          onTap: () {},
        ),
        SizedBox(height: AppSpacing.md),
        _buildMenuItem(
          context,
          icon: Icons.settings_outlined,
          label: 'Paramètres',
          onTap: () {},
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: DramusColors.border),
        ),
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Row(
            children: [
              Icon(icon, color: DramusColors.primaryTeal),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: DramusColors.secondaryText,
              ),
            ],
          ),
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
                  color: DramusColors.darkPetroleum,
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
                          color: DramusColors.secondaryText,
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
                style: TextStyle(color: DramusColors.secondaryText),
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
}
