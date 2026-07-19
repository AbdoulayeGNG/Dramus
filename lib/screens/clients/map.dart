import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/screens/clients/listing_detail_screen.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/core/state/auth_controller.dart';

class ClientsMapScreen extends StatefulWidget {
  const ClientsMapScreen({super.key});

  @override
  State<ClientsMapScreen> createState() => _ClientsMapScreenState();
}

class _ClientsMapScreenState extends State<ClientsMapScreen> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  String _typeFilter = 'all';
  double _maxPrice = 1000000000000; // Illimité par défaut (1 Trillion)
  int? _selectedListingIndex;
  List<Property> _listings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadListings();
    });
  }

  Future<void> _loadListings() async {
    try {
      final listingService = context.read<ListingService>();
      final authController = context.read<AuthController>();
      final user = authController.user;

      String? expectedEndpoint;
      if (user != null &&
          (user.role.toLowerCase() == 'particulier' ||
              user.role.toLowerCase() == 'agent')) {
        expectedEndpoint = '/api/properties/user/${user.id}';
      } else {
        expectedEndpoint = '/api/properties';
      }

      // Charger les données si le cache est absent ou ne correspond pas à l'utilisateur
      if (!listingService.isLoaded ||
          !listingService.isCacheValidFor(expectedEndpoint,
              targetId: user?.id)) {
        if (user != null &&
            (user.role.toLowerCase() == 'particulier' ||
                user.role.toLowerCase() == 'agent')) {
          await listingService.getUserListings(user.id);
        } else {
          await listingService.getAllListings();
        }
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
    var list = all;

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
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final listings = _applyFilters(_listings);
    final screenWidth = MediaQuery.of(context).size.width;
    final popupWidth = screenWidth * 0.42;
    final markerWidth = popupWidth + 20;
    const markerHeight = 220.0;

    final markers = listings.map((property) {
      final index = listings.indexOf(property);
      final isSelected = _selectedListingIndex == index;
      return Marker(
        width: markerWidth,
        height: isSelected ? markerHeight : 48,
        point: LatLng(property.location.latitude, property.location.longitude),
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              // Popup card above marker
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        ListingDetailScreen(listingId: property.id))),
                child: Container(
                  width: popupWidth,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: property.images.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: property.images.first,
                                height: 70,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                progressIndicatorBuilder:
                                    (context, url, downloadProgress) {
                                  return Container(
                                    height: 70,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: downloadProgress.progress,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorWidget: (_, __, ___) => Container(
                                  height: 70,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  child: Icon(Icons.home,
                                      size: 32,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                ),
                              )
                            : Container(
                                height: 70,
                                color: Colors.grey[200],
                                child: Icon(Icons.home,
                                    size: 32, color: Colors.grey[400]),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(property.price / 1000000).toStringAsFixed(1)}M GNF',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListingDetailScreen(listingId: property.id),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_on,
                  size: isSelected ? 36 : 32,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : DramusColors.premiumYellow,
                ),
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
              center: const LatLng(9.5370, -13.6740),
              zoom: 11.0,
              onTap: (tapPos, latlng) {
                // Deselect marker when tapping on map background
                setState(() => _selectedListingIndex = null);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=ADVNv1Seo0Ebifgx85sn',
                additionalOptions: {
                  'apiKey': 'ADVNv1Seo0Ebifgx85sn', // Gardez-la sécurisée
                },
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
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  // Filtre Type
                  Expanded(
                    flex: 2,
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _typeFilter,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tous')),
                        DropdownMenuItem(
                            value: 'Maison', child: Text('Maison')),
                        DropdownMenuItem(
                            value: 'Appartement', child: Text('Appart.')),
                        DropdownMenuItem(
                            value: 'Terrain', child: Text('Terrain')),
                        DropdownMenuItem(
                            value: 'Bureau', child: Text('Bureau')),
                      ],
                      onChanged: (v) =>
                          setState(() => _typeFilter = v ?? 'all'),
                    ),
                  ),
                  Container(
                    height: 24,
                    width: 1,
                    color: Theme.of(context).dividerColor,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  // Filtre Prix (Slider)
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _maxPrice >= 1000000000
                              ? 'Max: ∞'
                              : 'Max: ${(_maxPrice / 1000000).toStringAsFixed(0)}M',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12),
                          ),
                          child: Slider(
                            value: _maxPrice.clamp(0.0, 1000000000.0),
                            min: 0,
                            max: 1000000000, // 1 Milliard
                            divisions: 20,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (v) => setState(() => _maxPrice = v),
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
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 1.0,
              builder: (context, ctrl) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: ListView.builder(
                    controller: ctrl,
                    padding: EdgeInsets.all(AppSpacing.md),
                    itemCount: listings.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        // Header
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${listings.length} annonce${listings.length > 1 ? 's' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }

                      final property = listings[i - 1];
                      final selected = _selectedListingIndex == (i - 1);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.08)
                            : null,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: property.images.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: property.images.first,
                                    width: 72,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    progressIndicatorBuilder:
                                        (context, url, downloadProgress) {
                                      return Container(
                                        width: 72,
                                        height: 56,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value: downloadProgress.progress,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    errorWidget: (_, __, ___) => Container(
                                      width: 72,
                                      height: 56,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: Icon(Icons.home,
                                          size: 24,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                    ),
                                  )
                                : Container(
                                    width: 72,
                                    height: 56,
                                    color: Colors.grey[200],
                                    child: Icon(Icons.home,
                                        size: 24, color: Colors.grey[400]),
                                  ),
                          ),
                          title: Text(
                            property.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${property.location.city}, ${property.location.district} • ${property.type}\n${(property.price / 1000000).toStringAsFixed(1)}M GNF',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          onTap: () {
                            setState(() => _selectedListingIndex = i - 1);
                            _centerOn(property);
                            // Réduire la liste pour que l'annonce soit plus visible sur la carte
                            _sheetController.animateTo(
                              0.2,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
