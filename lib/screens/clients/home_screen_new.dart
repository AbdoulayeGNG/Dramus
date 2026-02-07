import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/services/favorites_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/property_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Property> _filteredListings;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredListings = []; // Initialiser la liste vide
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final listingService = context.read<ListingService>();
      // Charger les données seulement si elles ne sont pas déjà en cache
      if (!listingService.isLoaded) {
        await listingService.getAllListings();
      }
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final listingService = context.read<ListingService>();
    final authController = context.read<AuthController>();
    final user = authController.user;

    List<Property> listings = listingService.cachedListings;
    listings = listings.where((p) => p.status == 'published').toList();

    if (_searchController.text.isNotEmpty) {
      listings = listings.where((p) {
        return p.title
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            p.location.city
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            p.location.district
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredListings = listings;
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
          //_buildStatisticsSection(context),
          _buildFeaturedListingsSection(context),
        ],
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingMd,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _applyFilters(),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Rechercher par titre ou localisation',
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.white,
          ),
          filled: true,
          fillColor: DramusColors.saleGreen,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: const BorderSide(
              color: DramusColors.saleGreen,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: const BorderSide(
              color: DramusColors.saleGreen,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DramusColors.darkPetroleum,
            DramusColors.deepTeal,
          ],
        ),
      ),
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour 👋',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: DramusColors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Trouvez votre bien idéal',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: DramusColors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Découvrez les plus belles propriétés de Guinée',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: DramusColors.lightGray,
                ),
          ),
          SizedBox(height: AppSpacing.xl),
          _buildSearchSection(context),
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
                  badge: Consumer<FavoritesService>(
                    builder: (context, favoritesService, _) {
                      final favoritesCount = favoritesService.favoriteIds.length;
                      return favoritesCount > 0
                          ? Text(
                              '$favoritesCount',
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
            'Annonces premiums',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppSpacing.lg),
          if (_filteredListings.isEmpty)
            Center(
              child: Padding(
                padding: AppSpacing.paddingXl,
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: DramusColors.secondaryText,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      'Aucune propriété trouvée',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Essayez d\'ajuster votre recherche',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DramusColors.secondaryText,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            Consumer<ListingService>(
              builder: (context, listingService, _) {
                return Column(
                  children: _filteredListings
                      .take(5)
                      .map(
                        (listing) => Padding(
                          padding: EdgeInsets.only(
                            bottom: AppSpacing.lg,
                          ),
                          child: PropertyCard(
                            property: listing,
                            onTap: () {},
                            onFavoriteToggle: (isFavorite) {
                              // TODO: implement favorite toggle
                            },
                            canManage:
                                false, // Les clients ne peuvent pas gérer les annonces
                            onViewIncrement: () async {
                              final listingService =
                                  context.read<ListingService>();
                              final success = await listingService
                                  .incrementViews(listing.id);
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Vue enregistrée !')),
                                );
                              }
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
}
