import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/models/user_model.dart';
import 'package:dramus/services/user_service.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/custom_button.dart';

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

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, _) {
        final user = userService.currentUser;

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
                    _buildMenuSection(context),
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
      color: DramusColors.darkPetroleum,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(user.avatar),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            user.firstName + ' ' + user.lastName,
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
        _buildInfoCard(
          context,
          icon: Icons.phone_outlined,
          label: 'Téléphone',
          value: user.phone,
        ),
        /*SizedBox(height: AppSpacing.md),
        _buildInfoCard(
          context,
          icon: Icons.info_outline,
          label: 'Bio',
          value: user.bio,
        ),*/
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

  Widget _buildMenuSection(BuildContext context) {
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
          onTap: () {},
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
          icon: Icons.help_outline,
          label: 'Centre d\'aide',
          onTap: () {},
        ),
        SizedBox(height: AppSpacing.md),
        _buildMenuItem(
          context,
          icon: Icons.info_outline,
          label: 'À propos',
          onTap: () {},
        ),
        SizedBox(height: AppSpacing.xxl),
        CustomButton(
          label: 'Déconnexion',
          onPressed: () {},
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
}
