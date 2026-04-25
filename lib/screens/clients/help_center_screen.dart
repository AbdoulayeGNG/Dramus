import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Comment créer un compte Dramus ?',
      'answer':
          'Cliquez sur "S\'inscrire" sur la page de connexion, remplissez vos informations et validez votre email.',
      'category': 'Compte'
    },
    {
      'question': 'Comment ajouter une propriété en favoris ?',
      'answer':
          'Cliquez sur l\'icône en forme de cœur sur une annonce pour l\'ajouter à vos favoris.',
      'category': 'Recherche'
    },
    {
      'question': 'Comment contacter une agence ?',
      'answer':
          'Sur la page de détail d\'un bien, utilisez le bouton "Contacter" pour envoyer un message ou appeler directement.',
      'category': 'Contact'
    },
    {
      'question': 'Les annonces sont-elles vérifiées ?',
      'answer':
          'Dramus s\'efforce de vérifier chaque agence partenaire pour garantir la sécurité de vos transactions.',
      'category': 'Sécurité'
    },
    {
      'question': 'Comment modifier mes critères de recherche ?',
      'answer':
          'Utilisez le panneau de filtres sur la page des annonces pour ajuster le prix, le type de bien et la localisation.',
      'category': 'Recherche'
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs.where((faq) {
      return faq['question']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DramusColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Centre d\'aide',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: DramusColors.white,
        foregroundColor: DramusColors.darkPetroleum,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategories(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildFaqSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildContactSupport(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: DramusColors.white,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        children: [
          Text(
            'Comment pouvons-nous vous aider ?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DramusColors.darkPetroleum,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: DramusColors.lightBackground,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: DramusColors.border),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Rechercher une question...',
                prefixIcon:
                    Icon(Icons.search, color: DramusColors.secondaryText),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {
        'icon': Icons.person_outline,
        'label': 'Mon Compte',
        'color': Colors.blue
      },
      {'icon': Icons.search, 'label': 'Recherche', 'color': Colors.orange},
      {
        'icon': Icons.home_work_outlined,
        'label': 'Annonces',
        'color': DramusColors.primaryTeal
      },
      {
        'icon': Icons.security_outlined,
        'label': 'Sécurité',
        'color': Colors.red
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.5,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: DramusColors.border),
          ),
          child: InkWell(
            onTap: () {
              setState(() => _searchQuery = cat['label'] as String);
              _searchController.text = cat['label'] as String;
            },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Icon(cat['icon'] as IconData,
                      color: cat['color'] as Color, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    cat['label'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaqSection() {
    final faqs = _filteredFaqs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Questions Fréquentes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_searchQuery.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() => _searchQuery = '');
                  _searchController.clear();
                },
                child: const Text('Toutes'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (faqs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('Aucun résultat trouvé.')),
          )
        else
          ...faqs.map((faq) => _buildFaqItem(faq['question']!, faq['answer']!)),
      ],
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: DramusColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: DramusColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: DramusColors.darkPetroleum,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: const TextStyle(
                  color: DramusColors.secondaryText,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSupport() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DramusColors.darkPetroleum, DramusColors.primaryTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: DramusColors.primaryTeal.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent, size: 50, color: Colors.white),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Pas trouvé de réponse ?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Notre équipe support est disponible 24/7 pour vous accompagner.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.message_outlined,
                  label: 'WhatsApp',
                  onTap: () => _launchUrl('https://wa.me/224620000000'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  onTap: () => _launchUrl('mailto:support@dramus.com'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildContactButton(
            icon: Icons.phone_in_talk_outlined,
            label: 'Appeler le support',
            onTap: () => _launchUrl('tel:+224620000000'),
            isPrimary: false,
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = true,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.white : Colors.transparent,
        foregroundColor: isPrimary ? DramusColors.darkPetroleum : Colors.white,
        elevation: 0,
        side: isPrimary ? null : const BorderSide(color: Colors.white),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
