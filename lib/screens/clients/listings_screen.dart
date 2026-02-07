import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/filter_panel.dart';
import 'package:dramus/widgets/header_section.dart';
import 'package:dramus/widgets/property_card.dart';

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
      // Charger les données seulement si elles ne sont pas déjà en cache
      if (!listingService.isLoaded) {
        await listingService.getAllListings();
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperty();
    });
  }

  Future<void> _loadProperty() async {
    try {
      debugPrint('ListingDetailScreen: Loading property with ID: ${widget.listingId}');
      final listingService = context.read<ListingService>();
      final property = await listingService.getListingById(widget.listingId);
      debugPrint('ListingDetailScreen: Property loaded: ${property?.title ?? "NULL"}');
      
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
        property.images.isNotEmpty
            ? Image.network(
                property.images.first,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        color: DramusColors.primaryTeal,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    width: double.infinity,
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
              )
            : Container(
                height: 300,
                width: double.infinity,
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Aucune image',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
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

  void _showMessageDialog(BuildContext context, Property property) {
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Row(
            children: [
              Icon(Icons.mail_outline, color: DramusColors.primaryTeal),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Envoyer un message',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Concernant: ${property.title}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DramusColors.secondaryText,
                        fontStyle: FontStyle.italic,
                      ),
                ),
                SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Écrivez votre message ici...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: DramusColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: DramusColors.primaryTeal,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un message';
                    }
                    if (value.trim().length < 10) {
                      return 'Le message doit contenir au moins 10 caractères';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                messageController.dispose();
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Annuler',
                style: TextStyle(color: DramusColors.secondaryText),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // TODO: Implémenter l'envoi du message via l'API
                  // Pour l'instant, on simule l'envoi
                  Navigator.of(dialogContext).pop();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text('Message envoyé avec succès !'),
                            ),
                          ],
                        ),
                        backgroundColor: DramusColors.primaryTeal,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    );
                  }
                  
                  messageController.dispose();
                }
              },
              icon: Icon(Icons.send),
              label: Text('Envoyer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DramusColors.primaryTeal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
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
                      onPressed: () => _showMessageDialog(context, property),
                      icon: const Icon(Icons.mail),
                      label: const Text('Message'),
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
