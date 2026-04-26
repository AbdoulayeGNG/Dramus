import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/services/favorites_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/filter_panel.dart';
import 'package:dramus/widgets/header_section.dart';
import 'package:dramus/widgets/property_card.dart';
import 'package:dramus/screens/clients/main_app_screen.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  late List<Property> _filteredListings;
  bool _isLoading = true;
  String _selectedType = 'all';
  int _minPrice = 0;
  int _maxPrice = 500000000000;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredListings = [];
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final listingService = context.read<ListingService>();
      await listingService.getAllListings();
      // Toujours charger les favoris pour s'assurer que les cœurs sont à jour
      if (mounted) {
        await context.read<FavoritesService>().loadFavorites();
      }
      _applyFilters();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    if (_selectedType != 'all') {
      listings = listings.where((p) => p.type == _selectedType).toList();
    }

    listings = listings.where((p) {
      if (p.price < _minPrice || p.price > _maxPrice) return false;
      if (_searchController.text.isNotEmpty &&
          !p.title
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) &&
          !p.location.city
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) &&
          !p.location.district
              .toLowerCase()
              .contains(_searchController.text.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    setState(() {
      _filteredListings = listings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          HeaderSection(
            title: 'Annonces immobilières',
            subtitle: '${_filteredListings.length} propriétés trouvées',
          ),
          SizedBox(height: AppSpacing.lg),
          Padding(
            padding: AppSpacing.paddingMd,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Rechercher par titre ou localisation',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Padding(
            padding: AppSpacing.paddingMd,
            child: FilterPanel(
              onFilterChanged: (type, minPrice, maxPrice) {
                setState(() {
                  _selectedType = type;
                  _minPrice = minPrice;
                  _maxPrice = maxPrice;
                });
                _applyFilters();
              },
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          else if (_filteredListings.isEmpty)
            Center(
              child: Padding(
                padding: AppSpacing.paddingXl,
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      'Essayez d\'ajuster vos critères de recherche',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                      MediaQuery.of(context).size.width > 600 ? 0.8 : 0.9,
                ),
                itemCount: _filteredListings.length,
                itemBuilder: (context, index) {
                  final property = _filteredListings[index];
                  return PropertyCard(
                    property: property,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ListingDetailScreen(
                            listingId: property.id,
                          ),
                        ),
                      );
                    },
                    onFavoriteToggle: (isFavorite) {
                      // TODO: implement
                    },
                    canManage:
                        false, // Les clients ne peuvent pas gérer les annonces
                    onViewIncrement: () async {
                      final listingService = context.read<ListingService>();
                      final success =
                          await listingService.incrementViews(property.id);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vue enregistrée !')),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

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
                        return Image.network(
                          property.images[index],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
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
                          errorBuilder: (context, error, stackTrace) {
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
                      child: Image.network(
                        property.images[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 100,
                            color: Colors.grey[200],
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: DramusColors.primaryTeal,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
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
              child: Text(
                _formatPrice(property.price),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: DramusColors.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Consumer<FavoritesService>(
              builder: (context, favService, _) {
                final isFavorite = favService.isFavorite(property.id);
                return IconButton(
                  onPressed: () async {
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
            Text(
              '${property.location.city}, ${property.location.district}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DramusColors.secondaryText,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context, Property property) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildDetailItem(context, property.type, 'Type'),
        _buildDetailItem(
            context, '${property.surface.toStringAsFixed(0)}m²', 'Surface'),
      ],
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
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: DramusColors.primaryTeal,
                  fontWeight: FontWeight.bold,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vous devez être connecté pour envoyer un message'),
              backgroundColor: DramusColors.notificationRed,
            ),
          );
        }
        return;
      }

      // Naviguer vers le MainAppScreen avec l'onglet Messages sélectionné
      // L'écran de messages gérera la création/récupération de la conversation
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainAppScreen(
            initialTabIndex: 3, // Index de l'onglet Messages
            selectedConversationId: property.ownerId,
            propertyId: property.id,
            ownerName: property.owner.fullName,
            prefilledMessage:
                'Bonjour, je suis intéressé(e) par votre bien "${property.title}". Est-il toujours disponible?',
          ),
        ),
        (route) => false, // Supprimer toutes les routes précédentes
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
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: DramusColors.primaryTeal,
                    backgroundImage:
                        owner.avatar != null && owner.avatar!.isNotEmpty
                            ? NetworkImage(owner.avatar!)
                            : null,
                    child: owner.avatar == null || owner.avatar!.isEmpty
                        ? Text(
                            owner.initials,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: DramusColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          )
                        : null,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          owner.fullName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (owner.phone.isNotEmpty)
                          Text(
                            owner.phone,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: DramusColors.secondaryText,
                                    ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToMessages(context, property),
                      icon: const Icon(Icons.mail),
                      label: const Text('Envoyer un message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
