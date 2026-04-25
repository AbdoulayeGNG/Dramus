import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DramusColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Centre d\'aide',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(context),
            SizedBox(height: AppSpacing.xl),
            Text(
              'Questions fréquentes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: DramusColors.darkPetroleum,
                  ),
            ),
            SizedBox(height: AppSpacing.md),
            _buildFaqItem(
              context,
              question: 'Comment modifier mon profil ?',
              answer:
                  'Allez dans l\'onglet Profil, puis cliquez sur Paramètres > Modifier mon profil.',
            ),
            _buildFaqItem(
              context,
              question: 'Comment publier une annonce ?',
              answer:
                  'Depuis l\'accueil ou l\'onglet Annonces, cliquez sur le bouton "+" pour créer une nouvelle annonce.',
            ),
            _buildFaqItem(
              context,
              question: 'Comment contacter le support ?',
              answer:
                  'Vous pouvez nous envoyer un email à support@dramus.com ou utiliser le formulaire ci-dessous.',
            ),
            SizedBox(height: AppSpacing.xl),
            _buildContactSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: DramusColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: DramusColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher une solution...',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: DramusColors.secondaryText),
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context,
      {required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: DramusColors.border),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: DramusColors.darkText,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Text(
              answer,
              style: const TextStyle(color: DramusColors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: DramusColors.primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent,
              size: 48, color: DramusColors.primaryTeal),
          SizedBox(height: AppSpacing.md),
          Text(
            'Besoin d\'aide supplémentaire ?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppSpacing.sm),
          const Text(
            'Notre équipe est là pour vous aider du Lundi au Vendredi, de 9h à 18h.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DramusColors.secondaryText),
          ),
          SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () {
              // Action pour contacter le support
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DramusColors.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text('Contacter le support'),
          ),
        ],
      ),
    );
  }
}
