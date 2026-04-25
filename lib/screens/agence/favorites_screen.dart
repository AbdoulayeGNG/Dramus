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
      backgroundColor: DramusColors.lightBackground,
      appBar: AppBar(
        title: const Text('Mes Favoris',
            style: TextStyle(
                color: DramusColors.darkText, fontWeight: FontWeight.bold)),
        backgroundColor: DramusColors.white,
        foregroundColor: DramusColors.darkText,
        elevation: 1,
      ),
      body: _isLoadingProperties
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  HeaderSection(
                    title: 'Vos coups de cœur',
                    subtitle:
                        '${_favoriteProperties.length} propriétés sauvegardées',
                  ),
                  SizedBox(height: AppSpacing.lg),
                  if (_favoriteProperties.isEmpty)
                    Center(
                      child: Padding(
                        padding: AppSpacing.paddingXl,
                        child: Column(
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 64,
                              color: DramusColors.secondaryText
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
                                    color: DramusColors.secondaryText,
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
                                    color: DramusColors.secondaryText,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: AppSpacing.paddingMd,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 600 ? 2 : 1,
                          crossAxisSpacing: AppSpacing.lg,
                          mainAxisSpacing: AppSpacing.lg,
                          childAspectRatio:
                              MediaQuery.of(context).size.width > 600
                                  ? 0.8
                                  : 0.9,
                        ),
                        itemCount: _favoriteProperties.length,
                        itemBuilder: (context, index) {
                          final property = _favoriteProperties[index];
                          // Hack pour forcer l'affichage 'Favori' même si le modèle dit false
                          // On ne peut pas facilement modifier property ici si c'est final.
                          // Espérons que PropertyCard checke le service, ou alors on modifiera PropertyCard.
                          // Spoiler: PropertyCard checke widget.property.isFavorite.
                          // On va modifier PropertyCard juste après pour être robuste.

                          return PropertyCard(
                            property: property,
                            // isFavorite est géré en interne par PropertyCard ou on peut forcer true
                            // PropertyCard checke le service normalement.
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PropertyDetailScreen(property: property),
                                ),
                              );
                            },
                            onFavoriteToggle: (isFavorite) async {
                              // Si on décoche, on devrait peut-être le retirer de la liste locale ?
                              // Le service gère l'appel API.
                              // Si on veut une maj immédiate :
                              if (!isFavorite) {
                                // Attendre la fin de l'anim ou refresh
                                // On laisse le service faire, et au prochain rebuild ou chargement ça partira
                                // Mais FavoritesService notifyListeners, donc PropertyCard changera d'état.
                                // Si on veut le retirer de la liste VISUELLE :
                                await context
                                    .read<FavoritesService>()
                                    .removeFavorite(property.id);
                                setState(() {
                                  _favoriteProperties.removeAt(index);
                                });
                              }
                            },
                            canManage:
                                false, // On ne gère pas ses favoris comme ses propres annonces (edit/delete)
                            onViewDetails: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PropertyDetailScreen(property: property),
                                ),
                              );
                            },
                            // Edit/Delete désactivés pour les favoris (sauf si c'est NOS propriétés ?)
                            // Généralement on ne modifie pas depuis l'écran favoris
                            onEdit: () {},
                            onDelete: () {},
                          );
                        },
                      ),
                    ),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
    );
  }
}
