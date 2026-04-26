import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/services/favorites_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/property_card.dart';
import 'package:dramus/screens/agence/property_detail_screen.dart';
import 'package:dramus/screens/agence/edit_property_screen.dart';
import 'package:dramus/screens/agence/favorites_screen.dart';
import 'package:dramus/widgets/delete_confirmation_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Property> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Déplacer l'appel dans didChangeDependencies pour éviter les problèmes de build
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadProperties();
      _applyFilters();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadProperties() async {
    final listingService = context.read<ListingService>();
    final authController = context.read<AuthController>();
    final user = authController.user;

    final role = user!.role.toLowerCase();
    if (role == 'agence' || role == 'agency') {
      await listingService.getAgencyListings(user.id);
    } else {
      // Pour particuliers et agents
      await listingService.getUserListings(user.id);
    }

    List<Property> properties = listingService.cachedListings;

    setState(() {
      _properties = properties;
    });
  }

  void _applyFilters() {
    final listingService = context.read<ListingService>();

    List<Property> listings = listingService.cachedListings;
    // Filtrer seulement les propriétés publiées pour l'affichage
    listings = listings.where((p) => p.status == 'published').toList();

    setState(() {
      _properties = listings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(context),
          // _buildQuickActionsSection supprimé
          _buildFeaturedListingsSection(context),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    // Removed gradient/background as requested — section now uses transparent background.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<AuthController>(
            builder: (context, authController, _) {
              final user = authController.user;
              String titleText;
              if (user != null) {
                final role = user.role.toLowerCase();
                if (role == 'particulier') {
                  titleText = 'Espace Particulier';
                } else if (role == 'agent') {
                  titleText = 'Espace Agent';
                } else {
                  titleText = 'Espace Agence';
                }
              } else {
                titleText = 'Espace Agence';
              }
              return Text(
                titleText,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
              );
            },
          ),
          //SizedBox(height: AppSpacing.lg),
          Consumer<AuthController>(
            builder: (context, authController, _) {
              final user = authController.user;
              String subtitleText;
              if (user != null) {
                final role = user.role.toLowerCase();
                if (role == 'particulier') {
                  subtitleText = 'Gérez vos annonces immobilières';
                } else if (role == 'agent') {
                  subtitleText = 'Gérez vos propriétés et clients';
                } else {
                  subtitleText =
                      'Voici un aperçu de votre activité immobilière';
                }
              } else {
                subtitleText = 'Voici un aperçu de votre activité immobilière';
              }
              return Text(
                subtitleText,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w100, fontSize: 12),
              );
            },
          ),
          SizedBox(height: AppSpacing.xl),

          // Dashboard cards arranged 2x2 using GridView
          Builder(
            builder: (context) {
              final activeCount =
                  _properties.where((p) => p.status == 'published').length;
              final viewsCount =
                  _properties.fold<int>(0, (sum, p) => sum + p.views);
              final messageService = context.watch<MessageService>();
              final unreadMessages = messageService.getUnreadCount();

              // Utilisation du FavoritesService pour le vrai compte
              final favoritesService = context.watch<FavoritesService>();
              final favoritesCount = favoritesService.favoriteIds.length;

              final cards = [
                {
                  'label': 'Annonces actives',
                  'value': activeCount.toString(),
                  'icon': Icons.inventory_2_outlined,
                  'color': DramusColors.primaryTeal,
                  'onTap': () {} // Rien pour l'instant
                },
                {
                  'label': 'Vues',
                  'value': viewsCount.toString(),
                  'icon': Icons.remove_red_eye_outlined,
                  'color': DramusColors.deepTeal,
                  'onTap': () {}
                },
                {
                  'label': 'Messages',
                  'value': unreadMessages.toString(),
                  'icon': Icons.mail_outline,
                  'color': DramusColors.notificationRed,
                  'onTap': () {
                    // Idéalement changer l'onglet vers Messages
                  }
                },
                {
                  'label': 'Favoris', // C'est ici qu'on navigue
                  'value': favoritesCount.toString(),
                  'icon': Icons.favorite_border,
                  'color': DramusColors.premiumYellow,
                  'onTap': () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  }
                },
              ];

              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  const spacing = AppSpacing.md;
                  // compute card width to have exactly 2 cards per row with spacing
                  final cardWidth =
                      ((maxWidth - spacing) / 2).clamp(140.0, 420.0);

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: cards.map((c) {
                      return SizedBox(
                        width: cardWidth,
                        child: GestureDetector(
                          onTap: c['onTap'] as VoidCallback?,
                          child: _buildStatCard(
                            context,
                            label: c['label'] as String,
                            value: c['value'] as String,
                            icon: c['icon'] as IconData,
                            color: c['color'] as Color,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // METHODES SUPPRIMEES : _buildQuickActionsSection, _buildActionCard

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: AppSpacing.md),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DramusColors.secondaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedListingsSection(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Annonces premium récentes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppSpacing.lg),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(
                  color: DramusColors.primaryTeal,
                ),
              ),
            )
          else
            Builder(
              builder: (context) {
                final recentProperties = _properties.take(2).toList();
                if (recentProperties.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Aucune annonce récente',
                        style: TextStyle(color: DramusColors.secondaryText),
                      ),
                    ),
                  );
                }
                return Column(
                  children: recentProperties
                      .map(
                        (property) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.lg,
                          ),
                          child: PropertyCard(
                            property: property,
                            onTap: () {},
                            onFavoriteToggle: (isFavorite) {
                              // TODO: implement
                            },
                            canManage: true,
                            onViewDetails: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PropertyDetailScreen(property: property),
                                ),
                              );
                            },
                            onEdit: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditPropertyScreen(property: property),
                                ),
                              );
                            },
                            onDelete: () {
                              _showDeleteConfirmationDialog(context, property);
                            },
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Property property) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return DeleteConfirmationDialog(
          title: 'Supprimer l\'annonce',
          message:
              'Êtes-vous sûr de vouloir supprimer cette annonce ? Cette action est irréversible.',
          onConfirm: () async {
            Navigator.of(dialogContext).pop(); // Fermer le dialog
            await _deleteProperty(property);
          },
          onCancel: () {
            Navigator.of(dialogContext).pop(); // Fermer le dialog
          },
        );
      },
    );
  }

  Future<void> _deleteProperty(Property property) async {
    final listingService = context.read<ListingService>();

    final success = await listingService.deleteListing(property.id);

    if (success && mounted) {
      // Rafraîchir les données
      await _loadProperties();
      _applyFilters();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annonce supprimée avec succès')),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression')),
        );
      }
    }
  }
}
