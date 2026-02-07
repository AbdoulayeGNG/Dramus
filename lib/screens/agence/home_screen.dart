import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/custom_button.dart';
import 'package:dramus/widgets/property_card.dart';
import 'package:dramus/screens/agence/property_detail_screen.dart';
import 'package:dramus/screens/agence/edit_property_screen.dart';
import 'package:dramus/widgets/delete_confirmation_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Property> _properties = [];

  @override
  void initState() {
    super.initState();
    // Déplacer l'appel dans didChangeDependencies pour éviter les problèmes de build
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadProperties();
      _applyFilters();
    });
  }

  Future<void> _loadProperties() async {
    final listingService = context.read<ListingService>();
    final authController = context.read<AuthController>();
    final user = authController.user;

    // Charger les données seulement si elles ne sont pas déjà en cache
    if (!listingService.isLoaded) {
      final role = user!.role.toLowerCase();
      if (role == 'agence' || role == 'agency') {
        await listingService.getAgencyListings(user.id);
      } else {
        // Pour particuliers et agents
        await listingService.getUserListings(user.id);
      }
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
          //_buildQuickActionsSection(context),
          _buildStatisticsSection(context),
          _buildFeaturedListingsSection(context),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    // Removed gradient/background as requested — section now uses transparent background.
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: DramusColors.darkText,
                    fontWeight: FontWeight.bold,
                    fontSize: 24),
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: DramusColors.darkText,
                    fontWeight: FontWeight.w100,
                    fontSize: 12),
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
              final favoritesCount = 0; // TODO: implement favorites

              final cards = [
                {
                  'label': 'Annonces actives',
                  'value': activeCount.toString(),
                  'icon': Icons.inventory_2_outlined,
                  'color': DramusColors.primaryTeal
                },
                {
                  'label': 'Vues',
                  'value': viewsCount.toString(),
                  'icon': Icons.remove_red_eye_outlined,
                  'color': DramusColors.deepTeal
                },
                {
                  'label': 'Messages',
                  'value': unreadMessages.toString(),
                  'icon': Icons.mail_outline,
                  'color': DramusColors.notificationRed
                },
                {
                  'label': 'Favoris',
                  'value': favoritesCount.toString(),
                  'icon': Icons.favorite_border,
                  'color': DramusColors.premiumYellow
                },
              ];

              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final spacing = AppSpacing.md;
                  // compute card width to have exactly 2 cards per row with spacing
                  final cardWidth =
                      ((maxWidth - spacing) / 2).clamp(140.0, 420.0);

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: cards.map((c) {
                      return SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          context,
                          label: c['label'] as String,
                          value: c['value'] as String,
                          icon: c['icon'] as IconData,
                          color: c['color'] as Color,
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

  Widget _buildQuickActionsSection(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.add_circle_outline,
                  label: 'Publier',
                  color: DramusColors.primaryTeal,
                  onTap: () {},
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.mail_outline,
                  label: 'Messages',
                  color: DramusColors.deepTeal,
                  badge: Consumer<MessageService>(
                    builder: (context, messageService, _) {
                      final unreadCount = messageService.getUnreadCount();
                      return unreadCount > 0
                          ? Text(
                              '$unreadCount',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: DramusColors.notificationRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                            )
                          : SizedBox.shrink();
                    },
                  ),
                  onTap: () {},
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.favorite_outline,
                  label: 'Favoris',
                  color: DramusColors.premiumYellow,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: DramusColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(
            color: DramusColors.border,
            width: 1,
          ),
        ),
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 28,
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: SizedBox(
                        child: badge,
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  label: 'Annonces en vente',
                  value: '1,523',
                  icon: Icons.sell,
                  color: DramusColors.saleGreen,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard(
                  context,
                  label: 'Annonces en location',
                  value: '1,324',
                  icon: Icons.apartment,
                  color: DramusColors.rentYellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
          Builder(
            builder: (context) {
              final recentProperties = _properties.take(2).toList();
              return Column(
                children: recentProperties
                    .map(
                      (property) => Padding(
                        padding: EdgeInsets.only(
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

  // helper card used by the hero section
  Widget _buildDashboardCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    // Use Expanded for the text column and limit lines to avoid RenderFlex overflow.
    return Card(
      color: DramusColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: AppSpacing.md),

            // Make the column flexible so long texts wrap/ellipsis instead of overflowing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: DramusColors.darkText,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DramusColors.secondaryText,
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

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
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
