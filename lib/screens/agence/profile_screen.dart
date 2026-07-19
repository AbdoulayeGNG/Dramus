import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/models/user_model.dart';
import 'package:dramus/services/agent_service.dart';
import 'package:dramus/services/favorites_service.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/custom_button.dart';
import 'package:dramus/screens/auth/login_screen.dart';
import 'package:dramus/screens/agence/favorites_screen.dart';
import 'package:dramus/screens/agence/listings_screen.dart';
import 'package:dramus/screens/agence/settings_screen.dart';
import 'package:dramus/screens/agence/help_center_screen.dart';
import 'package:dramus/screens/agence/about_screen.dart';

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
      // Réinitialiser tous les caches avant la déconnexion
      if (context.mounted) {
        try {
          context.read<ListingService>().reset();
          context.read<FavoritesService>().clearFavorites();
          context.read<MessageService>().clear();
          context.read<AgentService>().clear();
        } catch (e) {
          debugPrint('Erreur lors du nettoyage des caches: $e');
        }
      }

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
            backgroundImage: user.avatar.isNotEmpty
                ? CachedNetworkImageProvider(user.avatar)
                : null,
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
        side: BorderSide(color: Theme.of(context).dividerColor),
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
          icon: Icons.favorite_outline,
          label: 'Mes favoris',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const FavoritesScreen(),
              ),
            );
          },
        ),
        SizedBox(height: AppSpacing.md),
        _buildMenuItem(
          context,
          icon: Icons.home_outlined,
          label: 'Mes annonces',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Mes annonces'),
                    backgroundColor:
                        Theme.of(context).appBarTheme.backgroundColor,
                    foregroundColor:
                        Theme.of(context).appBarTheme.foregroundColor,
                    elevation: 0,
                  ),
                  body: const ListingsScreen(),
                ),
              ),
            );
          },
        ),
        SizedBox(height: AppSpacing.md),
        _buildMenuItem(
          context,
          icon: Icons.settings_outlined,
          label: 'Paramètres',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        ),
        SizedBox(height: AppSpacing.md),
        _buildMenuItem(
          context,
          icon: Icons.help_outline,
          label: 'Centre d\'aide',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const HelpCenterScreen(),
              ),
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
                builder: (context) => const AboutScreen(),
              ),
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
          side: BorderSide(color: Theme.of(context).dividerColor),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
