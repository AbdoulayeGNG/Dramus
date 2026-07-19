import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/models/property_constants.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/theme.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property? property;
  final String? propertyId;

  const PropertyDetailScreen({super.key, this.property, this.propertyId})
      : assert(property != null || propertyId != null,
            'Either property or propertyId must be provided');

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  Property? _property;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    // Si la propriété est déjà passée, l'utiliser directement
    if (widget.property != null) {
      setState(() {
        _property = widget.property;
        _isLoading = false;
      });
      return;
    }

    // Sinon, charger depuis l'API
    final listingService = context.read<ListingService>();
    final property = await listingService.getListingById(widget.propertyId!);

    if (mounted) {
      setState(() {
        _property = property;
        _isLoading = false;
      });
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          title: const Text('Détails de l\'annonce'),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_property == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          title: const Text('Détails de l\'annonce'),
          elevation: 0,
        ),
        body: const Center(
          child: Text('Annonce non trouvée'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: const Text('Détails de l\'annonce'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image gallery
            _buildImageGallery(_property!),

            // Content
            Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and title
                  _buildPriceSection(_property!),

                  SizedBox(height: AppSpacing.xl),

                  // Property details
                  _buildPropertyDetails(_property!),

                  SizedBox(height: AppSpacing.xl),

                  // Description
                  _buildDescriptionSection(_property!),

                  SizedBox(height: AppSpacing.xl),

                  // Location
                  _buildLocationSection(_property!),

                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(Property property) {
    if (property.images.isEmpty) {
      return Container(
        height: 250,
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 64,
            color: DramusColors.secondaryText,
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: property.images.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: property.images[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 64,
                  color: DramusColors.secondaryText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceSection(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _formatPrice(property.price),
            maxLines: 1,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: DramusColors.primaryTeal,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          property.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildPropertyDetails(Property property) {
    final List<Widget> detailsItems = [
      _buildDetailItem(Icons.category, 'Type', property.type),
      _buildDetailItem(Icons.location_city, 'Ville', property.location.city),
      _buildDetailItem(
          Icons.location_on, 'Quartier', property.location.district),
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
        detailsItems.add(_buildDetailItem(
            PropertyConstants.getIcon(config.icon), config.label, displayVal));
      }
    }

    // Grouper par ligne de 2.
    final List<Widget> rows = [];
    for (int i = 0; i < detailsItems.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: detailsItems[i]),
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

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: rows,
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: DramusColors.primaryTeal, size: 20),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DramusColors.secondaryText,
                    ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(Property property) {
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

  Widget _buildLocationSection(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localisation',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.md),
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: DramusColors.primaryTeal,
                size: 24,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  '${property.location.city}, ${property.location.district}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
