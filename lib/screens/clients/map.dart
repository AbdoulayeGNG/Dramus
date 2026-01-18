import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/screens/agence/listings_screen.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/core/state/auth_controller.dart';

class ClientsMapScreen extends StatefulWidget {
  const ClientsMapScreen({super.key});

  @override
  State<ClientsMapScreen> createState() => _ClientsMapScreenState();
}

class _ClientsMapScreenState extends State<ClientsMapScreen> {
  final MapController _mapController = MapController();
  String _typeFilter = 'all';
  double _maxPrice = 10000000;
  int? _selectedListingIndex;
  List<Property> _listings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    try {
      final listingService = context.read<ListingService>();
      // Charger les données seulement si elles ne sont pas déjà en cache
      if (!listingService.isLoaded) {
        await listingService.getListings();
      }
      setState(() {
        _listings = listingService.cachedListings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _listings = [];
        _isLoading = false;
      });
    }
  }

  List<Property> _applyFilters(List<Property> all) {
    final authController = context.read<AuthController>();
    final user = authController.user;

    var list = all;

    // Appliquer le filtrage par rôle utilisateur
    if (user != null) {
      final listingService = context.read<ListingService>();
      list = listingService.getFilteredListingsForUser(user);
    }

    if (_typeFilter != 'all')
      list = list.where((p) => p.type == _typeFilter).toList();
    list = list.where((p) => p.price <= _maxPrice).toList();
    return list;
  }

  void _centerOn(Property property) {
    _mapController.move(
        LatLng(property.location.latitude, property.location.longitude), 15);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Carte des annonces'),
          backgroundColor: DramusColors.darkPetroleum,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final listings = _applyFilters(_listings);

    final markers = listings.map((property) {
      final index = listings.indexOf(property);
      final isSelected = _selectedListingIndex == index;
      return Marker(
        width: 180,
        height: isSelected ? 160 : 48,
        point: LatLng(property.location.latitude, property.location.longitude),
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              // show map popup above the marker and also open a bottom preview
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        ListingDetailScreen(listingId: property.id))),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 160, maxHeight: 140),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8)),
                            child: Image.network(
                              property.images.isNotEmpty
                                  ? property.images.first
                                  : '',
                              height: 60,
                              width: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 60,
                                color: DramusColors.border,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    property.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('${property.price.toStringAsFixed(0)} GNF',
                                    style: TextStyle(
                                        color: DramusColors.primaryTeal,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onTap: () {
                setState(() => _selectedListingIndex = index);
                _centerOn(property);
                // show bottom preview sheet with more info
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) {
                    final maxH = MediaQuery.of(ctx).size.height * 0.6;
                    return SafeArea(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxH),
                          child: Padding(
                            padding: EdgeInsets.only(
                                bottom: MediaQuery.of(ctx).viewInsets.bottom),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: AppSpacing.paddingMd,
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                            property.images.isNotEmpty
                                                ? property.images.first
                                                : '',
                                            width: 120,
                                            height: 80,
                                            fit: BoxFit.cover),
                                      ),
                                      SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(property.title,
                                                style: Theme.of(ctx)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                            SizedBox(height: AppSpacing.xs),
                                            Text(
                                                '${property.location.city}, ${property.location.district} • ${property.type}',
                                                style: Theme.of(ctx)
                                                    .textTheme
                                                    .bodySmall),
                                            SizedBox(height: AppSpacing.sm),
                                            Text(
                                                '${property.price.toStringAsFixed(0)} GNF',
                                                style: Theme.of(ctx)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                        color: DramusColors
                                                            .primaryTeal,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: AppSpacing.paddingMd,
                                  child: Text(property.description,
                                      maxLines: 6,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                SizedBox(height: AppSpacing.md),
                                Padding(
                                  padding: AppSpacing.paddingMd,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          child: const Text('Fermer'),
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  DramusColors.primaryTeal),
                                          onPressed: () {
                                            Navigator.of(ctx).pop();
                                            Navigator.of(context).push(
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        ListingDetailScreen(
                                                            listingId:
                                                                property.id)));
                                          },
                                          child: const Text('Voir détails',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Icon(
                Icons.location_on,
                size: isSelected ? 44 : 36,
                color: isSelected
                    ? DramusColors.primaryTeal
                    : DramusColors.premiumYellow,
              ),
            ),
          ],
        ),
      );
    }).toList();

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: listings.isNotEmpty
                  ? LatLng(listings.first.location.latitude,
                      listings.first.location.longitude)
                  : LatLng(9.5092, -13.7539),
              zoom: 12,
              onTap: (tapPos, latlng) {
                // Deselect marker when tapping on map background
                setState(() => _selectedListingIndex = null);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: markers),
            ],
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Padding(
              padding: AppSpacing.paddingSm,
              child: Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _typeFilter,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tous')),
                        DropdownMenuItem(
                            value: 'Maison', child: Text('Maison')),
                        DropdownMenuItem(
                            value: 'Appartement', child: Text('Appartement')),
                        DropdownMenuItem(
                            value: 'Terrain', child: Text('Terrain')),
                      ],
                      onChanged: (v) =>
                          setState(() => _typeFilter = v ?? 'all'),
                      decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border:
                              OutlineInputBorder(borderSide: BorderSide.none)),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 3,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 2),
                      child: Slider(
                        value: _maxPrice.clamp(0, 5000000),
                        min: 0,
                        max: 5000000,
                        divisions: 10,
                        label: '${(_maxPrice / 1000).round()}K',
                        onChanged: (v) => setState(() => _maxPrice = v),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 96,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: DramusColors.primaryTeal),
                      onPressed: () => setState(() {}),
                      child: const Text('Appliquer',
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.12,
            maxChildSize: 0.6,
            builder: (context, ctrl) {
              return Container(
                decoration: BoxDecoration(
                  color: DramusColors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: ListView.builder(
                  controller: ctrl,
                  padding: EdgeInsets.all(AppSpacing.md),
                  itemCount: listings.length,
                  itemBuilder: (context, i) {
                    final property = listings[i];
                    final selected = _selectedListingIndex == i;
                    return Card(
                      color: selected
                          ? DramusColors.primaryTeal.withOpacity(0.08)
                          : null,
                      child: ListTile(
                        leading: Image.network(property.images.first,
                            width: 72, height: 56, fit: BoxFit.cover),
                        title: Text(property.title),
                        subtitle: Text(
                            '${property.location.city}, ${property.location.district} • ${property.type} • ${property.price.toStringAsFixed(0)} GNF'),
                        onTap: () {
                          setState(() => _selectedListingIndex = i);
                          _centerOn(property);
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  ListingDetailScreen(listingId: property.id)));
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
