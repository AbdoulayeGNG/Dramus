import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/favorites_service.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/header_section.dart';
import 'package:dramus/widgets/property_card.dart';
import 'package:dramus/screens/clients/listing_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoadingProperties = false;
  List<Property> _favoriteProperties = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    final favoritesService = context.read<FavoritesService>();
    final listingService = context.read<ListingService>();

    setState(() => _isLoadingProperties = true);

    try {
      // 1. Charger les IDs des favoris depuis le serveur
      await favoritesService.loadFavorites();

      // 2. Récupérer les objets Property correspondants
      final Set<String> favIds = favoritesService.favoriteIds;
      final List<Property> loadedProps = [];

      for (String id in favIds) {
        try {
          // Chercher d'abord dans le cache du ListingService
          Property? prop = listingService.cachedListings.firstWhere(
            (p) => p.id == id,
            orElse: () => Property.empty(),
          );

          if (prop.id.isEmpty) {
            // Pas en cache, on le fetcher depuis l'API
            prop = await listingService.getListingById(id);
          }

          if (prop != null) {
            // S'assurer que le flag isFavorite est cohérent pour l'affichage
            loadedProps.add(prop.copyWith(isFavorite: true));
          }
        } catch (e) {
          debugPrint('Erreur lors du chargement du favori $id: $e');
        }
      }

      if (mounted) {
        setState(() {
          _favoriteProperties = loadedProps;
        });
      }
    } catch (e) {
      debugPrint('Erreur globale lors du chargement des favoris: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProperties = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mes Favoris',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoadingProperties
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadFavorites,
              color: Theme.of(context).colorScheme.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: HeaderSection(
                      title: 'Vos coups de cœur',
                      subtitle:
                          '${_favoriteProperties.length} propriétés sauvegardées',
                    ),
                  ),
                  if (_favoriteProperties.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: AppSpacing.paddingMd,
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 600 ? 2 : 1,
                          crossAxisSpacing: AppSpacing.lg,
                          mainAxisSpacing: AppSpacing.lg,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final property = _favoriteProperties[index];

                            return PropertyCard(
                              property: property,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ListingDetailScreen(
                                        listingId: property.id),
                                  ),
                                );
                              },
                              onFavoriteToggle: (isFavorite) async {
                                if (!isFavorite) {
                                  // Retirer de la liste visuelle immédiatement
                                  setState(() {
                                    _favoriteProperties.removeAt(index);
                                  });
                                  // L'appel au service est géré par PropertyCard ou on peut le forcer
                                  await context
                                      .read<FavoritesService>()
                                      .removeFavorite(property.id);
                                }
                              },
                            );
                          },
                          childCount: _favoriteProperties.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 48),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Aucun favori pour le moment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Explorez les annonces et ajoutez-les à vos favoris pour les retrouver ici.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
