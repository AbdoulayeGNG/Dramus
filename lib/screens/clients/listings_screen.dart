import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/favorites_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/header_section.dart';
import 'package:dramus/widgets/property_card.dart';
import 'package:dramus/screens/clients/listing_detail_screen.dart';

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
    const expectedEndpoint = '/api/properties';
    final listingService = context.read<ListingService>();
    // Afficher immédiatement le cache s'il correspond aux annonces publiques
    if (listingService.isLoaded &&
        listingService.cachedListings.isNotEmpty &&
        listingService.isCacheValidFor(expectedEndpoint)) {
      _filteredListings = _filterListings(listingService.cachedListings);
      _isLoading = false;
    } else {
      _filteredListings = [];
      _isLoading = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final listingService = context.read<ListingService>();
      if (!listingService.isLoaded ||
          !listingService.isCacheValidFor(expectedEndpoint)) {
        await listingService.getAllListings();
        // Charger les favoris uniquement pour les utilisateurs connectés
        if (mounted) {
          final authController = context.read<AuthController>();
          if (authController.user != null) {
            await context.read<FavoritesService>().loadFavorites();
          }
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
                            builder: (_) => ListingDetailScreen(
                              listingId: property.id,
                            ),
                          ),
                        );
                      },
                      onFavoriteToggle: (isFavorite) {
                        // TODO: implement
                      },
                      canManage: false,
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
