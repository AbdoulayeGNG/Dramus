import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/favorites_service.dart';
import 'package:dramus/theme.dart';
import 'badge_widget.dart';

class PropertyCard extends StatefulWidget {
  final Property property;
  final VoidCallback onTap;
  final Function(bool)? onFavoriteToggle;
  final VoidCallback? onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canManage; // Indique si l'utilisateur peut gérer cette annonce
  final VoidCallback? onViewIncrement; // Callback pour incrémenter les vues

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
  late bool _isFavorite;
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    // Initialiser l'état favori à partir du service
    _isFavorite = widget.property.isFavorite;
  }

  @override
  void didUpdateWidget(PropertyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mettre à jour si la propriété change
    _isFavorite = widget.property.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final favoritesService =
          Provider.of<FavoritesService>(context, listen: false);

      final success = await favoritesService.toggleFavorite(widget.property.id);

      if (success && mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        widget.onFavoriteToggle?.call(_isFavorite);

        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris',
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
              // Handle pour fermer
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: DramusColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Options du menu
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

  String _formatPrice(num price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M GNF';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K GNF';
    }
    return '${price.toStringAsFixed(0)} GNF';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        color: DramusColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(
            color: DramusColors.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                  ),
                  child: widget.property.images.isNotEmpty
                      ? Image.network(
                          widget.property.images.first,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: DramusColors.primaryTeal,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.home_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Image non disponible',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: AppSpacing.sm),
                              Text(
                                'Aucune image',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bouton favori seulement (moreVert déplacé en bas)
                      GestureDetector(
                        onTap: _toggleFavorite,
                        child: Container(
                          decoration: BoxDecoration(
                            color: DramusColors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          padding: AppSpacing.paddingSm,
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite
                                ? DramusColors.notificationRed
                                : DramusColors.secondaryText,
                            size: 20,
                          ),
                        ),
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
                        type: BadgeType.sale, // Use sale type for now
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
                  // Prix et bouton moreVert sur la même ligne
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatPrice(widget.property.price),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: DramusColors.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      // Bouton de gestion (moreVert) - seulement si l'utilisateur peut gérer
                      if (widget.canManage)
                        GestureDetector(
                          onTap: () => _showManagementMenu(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: DramusColors.lightGray,
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            padding: AppSpacing.paddingSm,
                            child: Icon(
                              Icons.more_vert,
                              color: DramusColors.secondaryText,
                              size: 20,
                            ),
                          ),
                        )
                      // Bouton de vues pour les clients
                      else
                        GestureDetector(
                          onTap: () {
                            widget.onViewIncrement?.call();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: DramusColors.primaryTeal
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.xl),
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
                                Text(
                                  '${widget.property.views}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: DramusColors.primaryTeal,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.property.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: DramusColors.darkText,
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
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(
                        Icons.square_foot_outlined,
                        size: 16,
                        color: DramusColors.deepTeal,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        '${widget.property.surface.toStringAsFixed(0)}m²',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
