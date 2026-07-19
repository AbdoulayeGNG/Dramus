import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/favorites_service.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/models/property_constants.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/screens/clients/messages_screen.dart';
import 'package:dramus/screens/auth/login_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  Property? _property;
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperty();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProperty() async {
    try {
      debugPrint(
          'ListingDetailScreen: Loading property with ID: ${widget.listingId}');
      final listingService = context.read<ListingService>();
      final property = await listingService.getListingById(widget.listingId);
      debugPrint(
          'ListingDetailScreen: Property loaded: ${property?.title ?? "NULL"}');

      if (mounted) {
        setState(() {
          _property = property;
        });
      }
    } catch (e) {
      debugPrint('ListingDetailScreen: Error loading property: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement de l\'annonce'),
            backgroundColor: DramusColors.notificationRed,
          ),
        );
      }
    }
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
    if (_property == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: DramusColors.darkPetroleum,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(context, _property!),
            Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceSection(context, _property!),
                  SizedBox(height: AppSpacing.xxl),
                  _buildDetailsSection(context, _property!),
                  SizedBox(height: AppSpacing.xxl),
                  _buildDescriptionSection(context, _property!),
                  SizedBox(height: AppSpacing.xxl),
                  _buildContactSection(context, _property!),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context, Property property) {
    return Column(
      children: [
        property.images.isNotEmpty
            ? Stack(
                children: [
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemCount: property.images.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: property.images[index],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          progressIndicatorBuilder:
                              (context, url, downloadProgress) {
                            return Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            );
                          },
                          errorWidget: (context, url, error) {
                            return Container(
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Image non disponible',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (property.images.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${property.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DramusColors.darkPetroleum.withValues(alpha: 0.08),
                      DramusColors.primaryTeal.withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 72,
                      color: DramusColors.primaryTeal.withValues(alpha: 0.5),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Aucune photo disponible',
                      style: TextStyle(
                        color: DramusColors.secondaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Le propriétaire n\'a pas ajouté de photos',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
        if (property.images.length > 1)
          Container(
            height: 100,
            margin: EdgeInsets.all(AppSpacing.md),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: property.images.length,
              itemBuilder: (context, index) {
                final isSelected = _currentImageIndex == index;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: CachedNetworkImage(
                        imageUrl: property.images[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) {
                          return Container(
                            width: 100,
                            color: Colors.grey[200],
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: downloadProgress.progress,
                                  color: DramusColors.primaryTeal,
                                ),
                              ),
                            ),
                          );
                        },
                        errorWidget: (context, url, error) {
                          return Container(
                            width: 100,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey[400],
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPriceSection(BuildContext context, Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatPrice(property.price),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: DramusColors.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            Consumer<FavoritesService>(
              builder: (context, favService, _) {
                final isFavorite = favService.isFavorite(property.id);
                return IconButton(
                  onPressed: () async {
                    final authController = context.read<AuthController>();
                    if (authController.user == null) {
                      _showLoginRequiredDialog(context);
                      return;
                    }
                    await favService.toggleFavorite(property.id);
                  },
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: DramusColors.notificationRed,
                    size: 28,
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          property.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${property.location.city}, ${property.location.district}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DramusColors.secondaryText,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context, Property property) {
    final List<Widget> detailsItems = [
      _buildDetailItem(context, property.type, 'Type'),
    ];

    final configs =
        PropertyConstants.characteristicsByType[property.type] ?? [];
    for (var config in configs) {
      final value = property.caracteristiques[config.key];
      if (value != null) {
        String displayVal = value.toString();
        if (config.type == 'boolean') {
          displayVal = (value == true || value == 'true') ? 'Oui' : 'Non';
        } else if (config.key == 'surface') {
          displayVal = '${value}m²';
        }
        detailsItems.add(_buildDetailItem(context, displayVal, config.label));
      }
    }

    final List<Widget> rows = [];
    for (int i = 0; i < detailsItems.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: detailsItems[i]),
            SizedBox(width: AppSpacing.md),
            if (i + 1 < detailsItems.length)
              Expanded(child: detailsItems[i + 1])
            else
              Expanded(child: const SizedBox.shrink()),
          ],
        ),
      );
      if (i + 2 < detailsItems.length) {
        rows.add(SizedBox(height: AppSpacing.md));
      }
    }

    return Column(
      children: rows,
    );
  }

  Widget _buildDetailItem(BuildContext context, String value, String label) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: DramusColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: DramusColors.secondaryText,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context, Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          property.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Future<void> _navigateToMessages(
      BuildContext context, Property property) async {
    try {
      final authController = context.read<AuthController>();

      // Vérifier que l'utilisateur est connecté
      if (authController.user == null) {
        if (mounted) {
          context.read<MessageService>().setPendingConversation(
                conversationId: property.ownerId,
                propertyId: property.id,
                ownerName: property.owner.fullName,
                prefilledMessage:
                    'Bonjour, votre annonce "${property.title}" m\'intéresse. Est-elle toujours disponible ? Merci d\'avance.',
              );
          _showLoginRequiredDialog(context);
        }
        return;
      }

      // Naviguer directement vers l'écran de messages
      // L'écran de messages gérera la création/récupération de la conversation
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MessagesScreen(
            preselectedConversationId: property.ownerId,
            propertyId: property.id,
            ownerName: property.owner.fullName,
            prefilledMessage:
                'Bonjour, votre annonce "${property.title}" m\'intéresse. Est-elle toujours disponible ? Merci d\'avance.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to messages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de la messagerie'),
            backgroundColor: DramusColors.notificationRed,
          ),
        );
      }
    }
  }

  Widget _buildContactSection(BuildContext context, Property property) {
    final owner = property.owner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contacter l\'annonceur',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.lg),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      backgroundImage:
                          (owner.avatar != null && owner.avatar!.isNotEmpty)
                              ? CachedNetworkImageProvider(owner.avatar!)
                              : null,
                      child: (owner.avatar == null || owner.avatar!.isEmpty)
                          ? Text(
                              owner.initials,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            owner.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToMessages(context, property),
                        icon: const Icon(Icons.mail_outline),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DramusColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
        content:
            const Text('Vous devez être connecté pour effectuer cette action.'),
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
}
