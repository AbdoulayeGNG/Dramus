import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/header_section.dart';
import 'package:dramus/widgets/property_card.dart';
import 'package:dramus/screens/agence/property_detail_screen.dart';
import 'package:dramus/screens/agence/edit_property_screen.dart';
import 'package:dramus/widgets/delete_confirmation_dialog.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  late List<Property> _filteredListings;
  bool _isLoading = true;
  String _selectedType = 'all';
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final listingService = context.read<ListingService>();
    final authController = context.read<AuthController>();
    final user = authController.user!;
    final role = user.role.toLowerCase();
    final expectedEndpoint = '/api/properties/user/${user.id}';

    // Afficher immédiatement le cache s'il correspond à cet utilisateur
    if (listingService.isLoaded &&
        listingService.cachedListings.isNotEmpty &&
        listingService.isCacheValidFor(expectedEndpoint, targetId: user.id)) {
      _filteredListings = _filterListings(listingService.cachedListings);
      _isLoading = false;
    } else {
      _filteredListings = [];
      _isLoading = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final listingService = context.read<ListingService>();
      if (!listingService.isLoaded ||
          !listingService.isCacheValidFor(expectedEndpoint,
              targetId: user.id)) {
        if (role == 'agence' || role == 'agency') {
          await listingService.getAgencyListings(user.id);
        } else {
          // Pour particuliers et agents
          await listingService.getUserListings(user.id);
        }
      }
      _applyFilters();
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final listingService = context.read<ListingService>();
      if (!listingService.isLoading &&
          !listingService.isLoadingMore &&
          listingService.hasMore) {
        listingService.loadMoreListings().then((_) {
          if (mounted) _applyFilters();
        });
      }
    }
  }

  List<Property> _filterListings(List<Property> listings) {
    if (_selectedType != 'all') {
      listings = listings.where((p) => p.type == _selectedType).toList();
    }

    listings = listings.where((p) {
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

    return listings;
  }

  void _applyFilters() {
    final listingService = context.read<ListingService>();
    setState(() {
      _filteredListings = _filterListings(listingService.cachedListings);
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 300;
    final headerExtent = (isNarrow ? 180 : 150) + statusBarHeight;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _FixedHeaderDelegate(
            extent: headerExtent,
            child: HeaderSection(
              title: 'Annonces immobilières',
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: statusBarHeight + AppSpacing.sm,
                bottom: AppSpacing.sm,
              ),
              child: _buildFilterCard(),
            ),
          ),
        ),
        if (_isLoading)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
          )
        else if (_filteredListings.isEmpty)
          SliverToBoxAdapter(
            child: Center(
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
            ),
          )
        else
          SliverPadding(
            padding: AppSpacing.paddingMd,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final property = _filteredListings[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg),
                    child: PropertyCard(
                      property: property,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PropertyDetailScreen(property: property),
                          ),
                        );
                      },
                      onFavoriteToggle: (isFavorite) {
                        // Non applicable dans l'espace agence
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
                  );
                },
                childCount: _filteredListings.length,
              ),
            ),
          ),
        // Indicator for loading more at the bottom
        if (context.watch<ListingService>().isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterCard() {
    final typeDropdown = DropdownButton<String>(
      isExpanded: true,
      value: _selectedType,
      underline: const SizedBox(),
      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Tous')),
        DropdownMenuItem(value: 'Maison', child: Text('Maison')),
        DropdownMenuItem(value: 'Appartement', child: Text('Appart.')),
        DropdownMenuItem(value: 'Terrain', child: Text('Terrain')),
        DropdownMenuItem(value: 'Bureau', child: Text('Bureau')),
        DropdownMenuItem(value: 'Chambre', child: Text('Chambre')),
        DropdownMenuItem(value: 'Magasin', child: Text('Magasin')),
        DropdownMenuItem(value: 'Villa', child: Text('Villa')),
        DropdownMenuItem(value: 'Studio', child: Text('Studio')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedType = value);
          _applyFilters();
        }
      },
    );

    final searchField = TextField(
      controller: _searchController,
      onChanged: (_) => _applyFilters(),
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'Rechercher',
        hintStyle: TextStyle(fontSize: 13),
        prefixIcon: Icon(
          Icons.search,
          size: 18,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 300;

          if (narrow) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  typeDropdown,
                  const SizedBox(height: 4),
                  searchField,
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(flex: 2, child: typeDropdown),
                Container(
                  height: 22,
                  width: 1,
                  color: Theme.of(context).dividerColor,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Expanded(flex: 3, child: searchField),
              ],
            ),
          );
        },
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
      // Recharger les données depuis le cache/service
      final authController = context.read<AuthController>();
      final user = authController.user;
      if (!listingService.isLoaded) {
        final role = user!.role.toLowerCase();
        if (role == 'agence' || role == 'agency') {
          await listingService.getAgencyListings(user.id);
        } else {
          await listingService.getUserListings(user.id);
        }
      }
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

class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double extent;

  _FixedHeaderDelegate({
    required this.child,
    required this.extent,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => extent;

  @override
  double get minExtent => extent;

  @override
  bool shouldRebuild(covariant _FixedHeaderDelegate oldDelegate) => true;
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
    final listingService = context.read<ListingService>();
    final property = await listingService.getListingById(widget.listingId);
    setState(() {
      _property = property;
    });
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
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
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
                          placeholder: (context, url) => Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          ),
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
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: Icon(Icons.home,
                    size: 100, color: Theme.of(context).colorScheme.outline),
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
                            ? DramusColors.primaryTeal
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
                        placeholder: (context, url) => Container(
                          width: 100,
                          color: Colors.grey[200],
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image),
                        ),
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
            Text(
              _formatPrice(property.price),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: DramusColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Icon(
              Icons.favorite_border,
              color: DramusColors.notificationRed,
              size: 28,
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
              color: DramusColors.primaryTeal,
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
        _buildDetailItem(context,
            '${property.caracteristiques['surface'] ?? 0}m²', 'Surface'),
      ],
    );
  }

  Widget _buildDetailItem(BuildContext context, String value, String label) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
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

  Widget _buildContactSection(BuildContext context, Property property) {
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
            color: Theme.of(context).colorScheme.surfaceVariant,
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
                    backgroundImage: CachedNetworkImageProvider(
                      'https://i.pravatar.cc/150?img=10',
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Propriétaire',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'ID: ${property.ownerId}',
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
                      onPressed: () {},
                      icon: const Icon(Icons.phone),
                      label: const Text('Appeler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DramusColors.primaryTeal,
                        foregroundColor: DramusColors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.mail),
                      label: const Text('Envoyer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DramusColors.deepTeal,
                        foregroundColor: DramusColors.white,
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
