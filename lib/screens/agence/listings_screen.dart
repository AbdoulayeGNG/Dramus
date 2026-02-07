import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/filter_panel.dart';
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
  String _selectedType = 'all';
  int _minPrice = 0;
  int _maxPrice = 5000000;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredListings = []; // Initialiser la liste vide
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final listingService = context.read<ListingService>();
      final authController = context.read<AuthController>();
      final user = authController.user;
      // Charger les données seulement si elles ne sont pas déjà en cache
      if (!listingService.isLoaded) {
        final role = user!.role.toLowerCase();
        if (role == 'agence' || role == 'agency') {
          await listingService.getAgencyListings(user.id);
        } else {
          // Pour particuliers et agents
          await listingService.getUserListings(user.id);
        }
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
                  color: DramusColors.secondaryText,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(
                    color: DramusColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(
                    color: DramusColors.border,
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
                      'Essayez d\'ajuster vos critères de recherche',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      MediaQuery.of(context).size.width > 600 ? 0.8 : 1,
                ),
                itemCount: _filteredListings.length,
                itemBuilder: (context, index) {
                  final property = _filteredListings[index];
                  return PropertyCard(
                    property: property,
                    onTap: () {
                      // TODO: navigate to detail
                    },
                    onFavoriteToggle: (isFavorite) {
                      // TODO: implement
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
                  );
                },
              ),
            ),
          SizedBox(height: AppSpacing.xxl),
        ],
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

class ListingDetailScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  Property? _property;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperty();
    });
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
          backgroundColor: DramusColors.darkPetroleum,
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
        Image.network(
          property.images.isNotEmpty ? property.images.first : '',
          height: 300,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        if (property.images.length > 1)
          Container(
            height: 100,
            margin: EdgeInsets.all(AppSpacing.md),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: property.images.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: DramusColors.border,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.network(
                      property.images[index],
                      width: 100,
                      fit: BoxFit.cover,
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
        _buildDetailItem(
            context, '${property.surface.toStringAsFixed(0)}m²', 'Surface'),
      ],
    );
  }

  Widget _buildDetailItem(BuildContext context, String value, String label) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: DramusColors.lightBackground,
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
            color: DramusColors.lightBackground,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: DramusColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(
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
