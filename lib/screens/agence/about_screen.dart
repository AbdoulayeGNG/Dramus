import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (e) {
      // Fallback values already set
      debugPrint('Error loading package info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'À propos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.xl),
            _buildAppLogo(context),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'DRAMUS',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Immobilier Premium',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: DramusColors.primaryTeal,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Version $_version ($_buildNumber)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DramusColors.secondaryText,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Dramus est la plateforme de référence pour l\'immobilier de prestige. '
              'Nous connectons les agences, les propriétaires et les clients à la recherche '
              'de biens d\'exception.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Nous suivre',
              children: [
                _buildSocialLink(context, 'Site web', Icons.language),
                _buildDivider(),
                _buildSocialLink(context, 'Facebook', Icons.facebook),
                _buildDivider(),
                _buildSocialLink(context, 'Instagram', Icons.camera_alt),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              '© ${DateTime.now().year} Dramus Inc. Tous droits réservés.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogo(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: DramusColors.primaryTeal,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DramusColors.primaryTeal.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.home_work_outlined,
        size: 50,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: DramusColors.secondaryText,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLink(BuildContext context, String title, IconData icon) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: DramusColors.darkPetroleum),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16);
  }
}
