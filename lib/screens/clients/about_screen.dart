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
      debugPrint('Error loading package info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DramusColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'À propos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: DramusColors.white,
        foregroundColor: DramusColors.darkPetroleum,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            _buildLogoSection(),
            const SizedBox(height: AppSpacing.xxl),
            _buildMissionSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildLegalSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildSocialSection(),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              '© ${DateTime.now().year} Dramus. Tous droits réservés.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DramusColors.secondaryText,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: DramusColors.primaryTeal,
            borderRadius: BorderRadius.circular(24),
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
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'DRAMUS',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: DramusColors.darkPetroleum,
                letterSpacing: 1.5,
              ),
        ),
        Text(
          'Version $_version ($_buildNumber)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DramusColors.secondaryText,
              ),
        ),
      ],
    );
  }

  Widget _buildMissionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          Text(
            'Notre Mission',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DramusColors.darkPetroleum,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Dramus est la plateforme immobilière de référence en Guinée. Notre mission est de simplifier la recherche et la gestion de biens immobiliers grâce à une technologie de pointe et une expérience utilisateur premium.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DramusColors.darkText,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return _buildCardSection(
      title: 'Informations Légales',
      items: [
        _buildListTile(
          icon: Icons.description_outlined,
          label: 'Conditions Générales d\'Utilisation',
          onTap: () {},
        ),
        _buildDivider(),
        _buildListTile(
          icon: Icons.privacy_tip_outlined,
          label: 'Politique de Confidentialité',
          onTap: () {},
        ),
        _buildDivider(),
        _buildListTile(
          icon: Icons.gavel_outlined,
          label: 'Mentions Légales',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSocialSection() {
    return _buildCardSection(
      title: 'Nous Suivre',
      items: [
        _buildListTile(
          icon: Icons.language_outlined,
          label: 'Site Web',
          onTap: () {},
        ),
        _buildDivider(),
        _buildListTile(
          icon: Icons.facebook_outlined,
          label: 'Facebook',
          onTap: () {},
        ),
        _buildDivider(),
        _buildListTile(
          icon: Icons.camera_alt_outlined,
          label: 'Instagram',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildCardSection(
      {required String title, required List<Widget> items}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: DramusColors.secondaryText,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: const BorderSide(color: DramusColors.border),
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: DramusColors.primaryTeal, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 14, color: DramusColors.secondaryText),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, indent: 56, endIndent: 16);
  }
}
