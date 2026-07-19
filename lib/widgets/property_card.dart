import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/favorites_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/screens/auth/login_screen.dart';
import 'package:dramus/theme.dart';
import 'badge_widget.dart';

class PropertyCard extends StatefulWidget {
  final Property property;
  final VoidCallback onTap;
  final Function(bool)? onFavoriteToggle;
  final VoidCallback? onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canManage;
  final VoidCallback? onViewIncrement;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.onFavoriteToggle,
    this.onViewDetails,
    this.onEdit,
    this.onDelete,
    this.canManage = false,
    this.onViewIncrement,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(PropertyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    if (authController.user == null) {
      _showLoginRequiredDialog(context);
      return;
    }

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final favoritesService =
          Provider.of<FavoritesService>(context, listen: false);

      final success = await favoritesService.toggleFavorite(widget.property.id);

      if (success && mounted) {
        widget.onFavoriteToggle
            ?.call(!favoritesService.isFavorite(widget.property.id));

        final isNowFavorite = favoritesService.isFavorite(widget.property.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNowFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: DramusColors.primaryTeal,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour du favori'),
            backgroundColor: DramusColors.notificationRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  void _showManagementMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading:
                    Icon(Icons.visibility, color: DramusColors.primaryTeal),
                title: Text('Voir les détails'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onViewDetails?.call();
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: DramusColors.deepTeal),
                title: Text('Modifier l\'annonce'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onEdit?.call();
                },
              ),
              Divider(),
              ListTile(
                leading:
                    Icon(Icons.delete, color: DramusColors.notificationRed),
                title: Text('Supprimer l\'annonce'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmation(context);
                },
              ),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text('Confirmer la suppression'),
          content: Text(
              'Êtes-vous sûr de vouloir supprimer cette annonce ? Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete?.call();
              },
              style: TextButton.styleFrom(
                foregroundColor: DramusColors.notificationRed,
              ),
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Connexion requise'),
        content: const Text(
            'Vous devez être connecté pour ajouter une annonce à vos favoris.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DramusColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(num price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M GNF';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K GNF';
    }
    return '${price.toStringAsFixed(0)} GNF';
  }

  List<Widget> _buildCaracteristiquesWidgets(
      BuildContext context, Property property) {
    final List<Widget> widgets = [];
    final carac = property.caracteristiques;
    if (carac.isEmpty) return widgets;

    Widget buildChip(IconData icon, String text) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DramusColors.deepTeal),
          SizedBox(width: AppSpacing.xs),
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      );
    }

    String resolveBool(dynamic value) {
      if (value == true || value == 'true') return 'Oui';
      return 'Non';
    }

    // 1. Surface (Commun à tous si présent)
    if (carac['surface'] != null) {
      widgets
          .add(buildChip(Icons.square_foot_outlined, '${carac['surface']}m²'));
    }

    final type = property.type.toLowerCase();

    // 2. Éléments spécifiques selon le type
    if (type == 'appartement') {
      if (carac['chambres'] != null)
        widgets
            .add(buildChip(Icons.king_bed_outlined, '${carac['chambres']} Ch'));
      if (carac['sallesDeBain'] != null)
        widgets.add(
            buildChip(Icons.bathtub_outlined, '${carac['sallesDeBain']} Sdb'));
      if (carac['etage'] != null)
        widgets.add(buildChip(Icons.stairs_outlined, 'Ét. ${carac['etage']}'));
      if (carac['ascenseur'] != null)
        widgets.add(buildChip(Icons.elevator_outlined,
            'Asc. ${resolveBool(carac['ascenseur'])}'));
      if (carac['balcon'] != null)
        widgets.add(buildChip(
            Icons.balcony_outlined, 'Balc. ${resolveBool(carac['balcon'])}'));
    } else if (type == 'maison') {
      if (carac['chambres'] != null)
        widgets
            .add(buildChip(Icons.king_bed_outlined, '${carac['chambres']} Ch'));
      if (carac['sallesDeBain'] != null)
        widgets.add(
            buildChip(Icons.bathtub_outlined, '${carac['sallesDeBain']} Sdb'));
      if (carac['garage'] != null)
        widgets.add(buildChip(
            Icons.garage_outlined, 'Gar. ${resolveBool(carac['garage'])}'));
      if (carac['jardin'] != null)
        widgets.add(buildChip(
            Icons.grass_outlined, 'Jar. ${resolveBool(carac['jardin'])}'));
      if (carac['piscine'] != null)
        widgets.add(buildChip(
            Icons.pool_outlined, 'Pisc. ${resolveBool(carac['piscine'])}'));
    } else if (type == 'terrain') {
      if (carac['viabilise'] != null)
        widgets.add(buildChip(Icons.electric_meter_outlined,
            'Viab. ${resolveBool(carac['viabilise'])}'));
      if (carac['cloture'] != null)
        widgets.add(buildChip(
            Icons.fence_outlined, 'Clôt. ${resolveBool(carac['cloture'])}'));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: widget.property.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.property.images.first,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          progressIndicatorBuilder:
                              (context, url, downloadProgress) {
                            return Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    DramusColors.darkPetroleum,
                                    DramusColors.primaryTeal,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: downloadProgress.progress,
                                  color: DramusColors.primaryTeal,
                                ),
                              ),
                            );
                          },
                          errorWidget: (context, url, error) {
                            return _buildImagePlaceholder(
                                context, 'Image non disponible');
                          },
                        )
                      : _buildImagePlaceholder(context, 'Aucune image'),
                ),
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer<FavoritesService>(
                        builder: (context, favoritesService, _) {
                          final isFavorite =
                              favoritesService.isFavorite(widget.property.id);
                          return GestureDetector(
                            onTap: _toggleFavorite,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withValues(alpha: 0.95),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xl),
                              ),
                              padding: AppSpacing.paddingSm,
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite
                                    ? DramusColors.notificationRed
                                    : DramusColors.secondaryText,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BadgeWidget(
                        label: widget.property.type,
                        type: BadgeType.sale,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Action widget (more_vert or views counter)
                      final Widget actionWidget = widget.canManage
                          ? GestureDetector(
                              onTap: () => _showManagementMenu(context),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.xl),
                                ),
                                padding: AppSpacing.paddingSm,
                                child: Icon(
                                  Icons.more_vert,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: () {
                                widget.onViewIncrement?.call();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: DramusColors.primaryTeal
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.xl),
                                  border: Border.all(
                                    color: DramusColors.primaryTeal
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                padding: AppSpacing.paddingSm,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.visibility,
                                      color: DramusColors.primaryTeal,
                                      size: 16,
                                    ),
                                    SizedBox(width: AppSpacing.xs),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 80),
                                      child: Text(
                                        '${widget.property.views}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: DramusColors.primaryTeal,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                      // Si l'espace est critique (très petites grilles < 130px),
                      // on wrap pour éviter tout overflow horizontal.
                      if (constraints.maxWidth < 130) {
                        return Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _formatPrice(widget.property.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: DramusColors.primaryTeal,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            actionWidget,
                          ],
                        );
                      }

                      // Affichage normal et robuste avec flex 3/2
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              _formatPrice(widget.property.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: DramusColors.primaryTeal,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Flexible(
                            flex: 2,
                            child: actionWidget,
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.property.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: DramusColors.secondaryText,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '${widget.property.location.city}, ${widget.property.location.district}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: DramusColors.secondaryText,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.property.caracteristiques.isNotEmpty)
                    SizedBox(height: AppSpacing.md),
                  if (widget.property.caracteristiques.isNotEmpty)
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: _buildCaracteristiquesWidgets(
                          context, widget.property),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DramusColors.darkPetroleum,
            DramusColors.primaryTeal,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 64,
            color: DramusColors.white.withValues(alpha: 0.5),
          ),
          SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DramusColors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          )
        ],
      ),
    );
  }
}
