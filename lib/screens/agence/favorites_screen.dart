import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/favorites_service.dart';

import 'package:dramus/theme.dart';
import 'package:dramus/widgets/header_section.dart';
import 'package:dramus/widgets/property_card.dart';
import 'package:dramus/screens/agence/property_detail_screen.dart';
import 'package:dramus/screens/agence/edit_property_screen.dart';
import 'package:dramus/widgets/delete_confirmation_dialog.dart';

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
    final favoritesService = context.read<FavoritesService>();
    final listingService = context.read<ListingService>();

    setState(() => _isLoadingProperties = true);

    // 1. Charger les IDs des favoris
    await favoritesService.loadFavorites();

    // 2. Récupérer les objets Property correspondants
    final Set<String> favIds = favoritesService.favoriteIds;
    final List<Property> loadedProps = [];

    // On check d'abord dans le cache du ListingService pour éviter des appels inutiles
    // (Suppose que ListingService a déjà chargé des listing, sinon on peut tenter de tout charger ou charger par ID)
    // Pour être sûr, on peut charger tous les listings "publics" ou chercher par ID.
    // L'idéal serait listingService.getPropertiesByIds(favIds), mais ça n'existe pas.

    // On va itérer sur les IDs et chercher/fetcher
    for (String id in favIds) {
      // Chercher dans le cache
      try {
        Property? prop = listingService.cachedListings.firstWhere(
          (p) => p.id == id,
          orElse: () => Property.empty(), // Marqueur temporaire
        );

        if (prop.id.isEmpty) {
          // Pas en cache, on tente de le fetcher
          prop = await listingService.getListingById(id);
        }

        if (prop != null) {
          // On force isFavorite à true pour l'affichage dans cet écran
          prop = prop.copyWith(isFavorite: true);
          loadedProps.add(prop);
        }
      } catch (e) {
        debugPrint('Erreur lors du chargement du favori $id: $e');
      }
    }

    if (mounted) {
      setState(() {
        _favoriteProperties = loadedProps;
        _isLoadingProperties = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si le service change (ajout/suppression ailleurs), on recharge la liste locale ?
    // Pas idéal car ça ferait clignoter. On compte sur onFavoriteToggle pour le local.
    // context.watch<FavoritesService>(); // Juste pour le rebuild, mais pas pour recharger _favoriteProperties auto.

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mes Favoris',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: _isLoadingProperties
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
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
                    child: Center(
                      child: Padding(
                        padding: AppSpacing.paddingXl,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            SizedBox(height: AppSpacing.lg),
                            Text(
                              'Aucun favori pour le moment',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'Explorez les annonces et ajoutez-les à vos favoris en cliquant sur le cœur.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                                  builder: (context) =>
                                      PropertyDetailScreen(property: property),
                                ),
                              );
                            },
                            onFavoriteToggle: (isFavorite) async {
                              if (!isFavorite) {
                                await context
                                    .read<FavoritesService>()
                                    .removeFavorite(property.id);
                                setState(() {
                                  _favoriteProperties.removeAt(index);
                                });
                              }
                            },
                            canManage: false,
                            onViewDetails: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PropertyDetailScreen(property: property),
                                ),
                              );
                            },
                            onEdit: () {},
                            onDelete: () {},
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
    );
  }
}
