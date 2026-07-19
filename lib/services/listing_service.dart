import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/models/user_model.dart';
import 'package:dramus/core/api/api_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class ListingService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient.I;

  // Cache des données
  List<Property> _listings = [];
  bool _isLoading = false;
  bool _isLoaded = false;
  DateTime? _lastFetchTime;
  int _sessionId = 0; // Pour éviter les race conditions lors de la déconnexion
  String? _cachedOwnerId; // Pour identifier à qui appartient ce cache

  // Pagination states
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String _currentEndpoint = '';
  String? _cachedEndpoint; // Pour invalider le cache si l'endpoint change

  // Getters pour accéder aux données en cache
  List<Property> get cachedListings => _listings;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoaded => _isLoaded;
  bool get hasMore => _hasMore;

  // Durée de validité du cache (5 minutes)
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  // Vérifier si le cache est encore valide
  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration;
  }

  bool get isCacheValid => _isCacheValid();

  String? get cachedOwnerId => _cachedOwnerId;
  String? get cachedEndpoint => _cachedEndpoint;

  /// Vérifie si le cache correspond à l'endpoint et à l'utilisateur cible
  bool isCacheValidFor(String endpoint, {String? targetId}) {
    return _isCacheValid() &&
        _cachedEndpoint == endpoint &&
        _cachedOwnerId == targetId;
  }

  // Forcer le rafraîchissement du cache
  Future<void> refreshListings({User? user}) async {
    debugPrint('Forcing listings refresh...');
    if (user != null) {
      final role = user.role.toLowerCase();
      if (role == 'client') {
        await getAllListings(forceRefresh: true);
      } else if (role == 'agence' || role == 'agency') {
        await getAgencyListings(user.id, forceRefresh: true);
      } else if (role == 'particulier' || role == 'agent') {
        await getUserListings(user.id, forceRefresh: true);
      } else {
        await getAllListings(forceRefresh: true);
      }
    } else {
      await getAllListings(forceRefresh: true);
    }
  }

  // Invalider le cache (utile après création/modification/suppression)
  void invalidateCache() {
    _listings = [];
    _isLoaded = false;
    _lastFetchTime = null;
    _currentPage = 1;
    _hasMore = true;
    _currentEndpoint = '';
    debugPrint('ListingService: Cache invalidated and cleared');
    notifyListeners();
  }

  // Réinitialisation complète pour déconnexion
  void reset() {
    _sessionId++; // Incrémenter pour ignorer les requêtes en cours
    invalidateCache();
    _cachedOwnerId = null;
    _cachedEndpoint = null;
    _isLoading = false;
    _isLoadingMore = false;
  }

  Future<Property?> getListingById(String id) async {
    try {
      debugPrint(
          'ListingService.getListingById: Fetching property with ID: $id');
      debugPrint(
          'ListingService.getListingById: Making GET request to /api/properties/$id');

      final response = await _apiClient.dio.get('/api/properties/$id');

      debugPrint(
          'ListingService.getListingById: Response status code: ${response.statusCode}');
      debugPrint(
          'ListingService.getListingById: Response headers: ${response.headers}');
      debugPrint(
          'ListingService.getListingById: Raw response data: ${response.data}');
      debugPrint(
          'ListingService.getListingById: Response data type: ${response.data.runtimeType}');

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        debugPrint(
            'ListingService.getListingById: Response contains "data" key, using response.data["data"]');
        final data = response.data['data'];
        debugPrint('ListingService.getListingById: Data content: $data');
        debugPrint(
            'ListingService.getListingById: Data type: ${data.runtimeType}');

        if (data is Map<String, dynamic>) {
          final property = Property.fromJson(data);
          debugPrint(
              'ListingService.getListingById: Successfully parsed property from data: ${property.title}');
          return property;
        } else {
          debugPrint(
              'ListingService.getListingById: Data is not a Map<String, dynamic>, cannot parse');
          return null;
        }
      } else if (response.data is Map<String, dynamic>) {
        debugPrint(
            'ListingService.getListingById: Response is a Map, attempting to parse...');
        final property = Property.fromJson(response.data);
        debugPrint(
            'ListingService.getListingById: Successfully parsed property: ${property.title}');
        return property;
      } else {
        debugPrint('ListingService.getListingById: Unexpected response format');
        return null;
      }
    } catch (e) {
      debugPrint('ListingService.getListingById: Error fetching listing: $e');
      if (e is DioException) {
        debugPrint('ListingService.getListingById: DioException details:');
        debugPrint('  - Type: ${e.type}');
        debugPrint('  - Message: ${e.message}');
        debugPrint('  - Status Code: ${e.response?.statusCode}');
        debugPrint('  - Response Data: ${e.response?.data}');
        debugPrint(
            '  - Request: ${e.requestOptions.method} ${e.requestOptions.path}');
      }
      return null;
    }
  }

  Future<bool> createListing(Property property,
      {List<XFile>? imageFiles}) async {
    try {
      debugPrint('ListingService.createListing: Starting to create listing');

      Response response;

      if (imageFiles != null && imageFiles.isNotEmpty) {
        debugPrint(
            'ListingService.createListing: Creating multipart request with ${imageFiles.length} images');

        final Map<String, dynamic> propertyData = property.toJson();
        // Remove images field from JSON if we are sending files
        propertyData.remove('images');

        final formData = FormData.fromMap(propertyData);

        // Add files
        for (var file in imageFiles) {
          final fileName = p.basename(file.path);
          formData.files.add(MapEntry(
            'images',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ));
        }

        response = await _apiClient.dio.post('/api/properties', data: formData);
      } else {
        debugPrint(
            'ListingService.createListing: Property data: ${property.toJson()}');
        response = await _apiClient.dio
            .post('/api/properties', data: property.toJson());
      }

      debugPrint(
          'ListingService.createListing: Response status: ${response.statusCode}');
      debugPrint(
          'ListingService.createListing: Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Invalider le cache pour forcer le rechargement des données
        invalidateCache();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ListingService.createListing: Error creating listing: $e');
      if (e is DioException && e.response != null) {
        debugPrint(
            'ListingService.createListing: Error response: ${e.response?.data}');
        debugPrint(
            'ListingService.createListing: Error status: ${e.response?.statusCode}');
        debugPrint(
            'ListingService.createListing: Request headers: ${e.requestOptions.headers}');
      }
      return false;
    }
  }

  Future<bool> updateListing(String id, Property property) async {
    try {
      debugPrint(
          'ListingService.updateListing: Updating property with ID: $id');
      debugPrint(
          'ListingService.updateListing: Property data: ${property.toJson()}');
      debugPrint(
          'ListingService.updateListing: Making PUT request to /api/properties/$id');

      final response = await _apiClient.dio
          .put('/api/properties/$id', data: property.toJson());

      debugPrint(
          'ListingService.updateListing: Response status code: ${response.statusCode}');
      debugPrint(
          'ListingService.updateListing: Response headers: ${response.headers}');
      debugPrint(
          'ListingService.updateListing: Response data: ${response.data}');

      if (response.statusCode == 200) {
        // Invalider le cache après mise à jour
        invalidateCache();
        notifyListeners();
        debugPrint(
            'ListingService.updateListing: Successfully updated property');
        return true;
      } else {
        debugPrint(
            'ListingService.updateListing: Unexpected status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('ListingService.updateListing: Error updating listing: $e');
      if (e is DioException) {
        debugPrint('ListingService.updateListing: DioException details:');
        debugPrint('  - Type: ${e.type}');
        debugPrint('  - Message: ${e.message}');
        debugPrint('  - Status Code: ${e.response?.statusCode}');
        debugPrint('  - Response Data: ${e.response?.data}');
        debugPrint(
            '  - Request: ${e.requestOptions.method} ${e.requestOptions.path}');
        debugPrint('  - Request Data: ${e.requestOptions.data}');
      }
      return false;
    }
  }

  Future<bool> deleteListing(String id) async {
    try {
      debugPrint(
          'ListingService.deleteListing: Deleting property with ID: $id');
      debugPrint(
          'ListingService.deleteListing: Making DELETE request to /api/properties/$id');

      final response = await _apiClient.dio.delete('/api/properties/$id');

      debugPrint(
          'ListingService.deleteListing: Response status code: ${response.statusCode}');
      debugPrint(
          'ListingService.deleteListing: Response headers: ${response.headers}');
      debugPrint(
          'ListingService.deleteListing: Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Invalider le cache après suppression
        invalidateCache();
        notifyListeners();
        debugPrint(
            'ListingService.deleteListing: Successfully deleted property');
        return true;
      } else {
        debugPrint(
            'ListingService.deleteListing: Unexpected status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('ListingService.deleteListing: Error deleting listing: $e');
      if (e is DioException) {
        debugPrint('ListingService.deleteListing: DioException details:');
        debugPrint('  - Type: ${e.type}');
        debugPrint('  - Message: ${e.message}');
        debugPrint('  - Status Code: ${e.response?.statusCode}');
        debugPrint('  - Response Data: ${e.response?.data}');
        debugPrint(
            '  - Request: ${e.requestOptions.method} ${e.requestOptions.path}');
      }
      return false;
    }
  }

  Future<bool> incrementViews(String id) async {
    try {
      debugPrint(
          'ListingService.incrementViews: Incrementing views for property: $id');
      final response = await _apiClient.dio.patch('/api/properties/$id/views');

      debugPrint(
          'ListingService.incrementViews: Response status code: ${response.statusCode}');
      debugPrint(
          'ListingService.incrementViews: Response headers: ${response.headers}');
      debugPrint(
          'ListingService.incrementViews: Response data: ${response.data}');

      if (response.statusCode == 200) {
        // Invalider le cache pour forcer le rechargement des données
        invalidateCache();
        notifyListeners();
        debugPrint(
            'ListingService.incrementViews: Successfully incremented views');
        return true;
      } else {
        debugPrint(
            'ListingService.incrementViews: Unexpected status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('ListingService.incrementViews: Error incrementing views: $e');
      if (e is DioException) {
        debugPrint('ListingService.incrementViews: DioException details:');
        debugPrint('  - Type: ${e.type}');
        debugPrint('  - Message: ${e.message}');
        debugPrint('  - Status Code: ${e.response?.statusCode}');
        debugPrint('  - Response Data: ${e.response?.data}');
        debugPrint(
            '  - Request: ${e.requestOptions.method} ${e.requestOptions.path}');
      }
      return false;
    }
  }

  // Récupérer toutes les annonces (pour les clients)
  Future<List<Property>> getAllListings({bool forceRefresh = false}) async {
    return await _fetchListings('/api/properties', forceRefresh: forceRefresh);
  }

  // Récupérer les annonces d'un utilisateur spécifique (pour agents et particuliers)
  Future<List<Property>> getUserListings(String userId,
      {bool forceRefresh = false}) async {
    return await _fetchListings('/api/properties/user/$userId',
        forceRefresh: forceRefresh);
  }

  // Récupérer les annonces d'une agence via l'endpoint utilisateur
  Future<List<Property>> getAgencyListings(String agencyId,
      {bool forceRefresh = false}) async {
    return await _fetchListings('/api/properties/user/$agencyId',
        forceRefresh: forceRefresh);
  }

  Future<List<Property>> _fetchListings(String endpoint,
      {bool forceRefresh = false, int page = 1}) async {
    // Identifier l'entité propriétaire via l'endpoint (user ID ou agency ID)
    String? currentTargetId;
    if (endpoint.contains('/user/')) {
      currentTargetId = endpoint.split('/user/').last;
    } else if (endpoint.contains('/agency/')) {
      currentTargetId = endpoint.split('/agency/').last;
    }

    // Si la cible ou l'endpoint change, on force le rafraîchissement
    if (_cachedOwnerId != currentTargetId || _cachedEndpoint != endpoint) {
      debugPrint(
          'ListingService: Target/endpoint changed from $_cachedOwnerId@$_cachedEndpoint to $currentTargetId@$endpoint. Forcing refresh.');
      forceRefresh = true;
      _cachedOwnerId = currentTargetId;
      _cachedEndpoint = endpoint;
      _lastFetchTime = null;
      _isLoaded = false;
      _currentPage = 1;
      _hasMore = true;
    }

    _currentEndpoint = endpoint; // Save endpoint for loadMore

    // Si les données sont déjà chargées et le cache est valide (et page 1), retourner le cache
    if (_isLoaded && !forceRefresh && _isCacheValid() && page == 1) {
      debugPrint(
          'Returning cached listings for $_cachedOwnerId (${_listings.length} items)');
      return _listings;
    }

    // Éviter les chargements multiples simultanés
    if (_isLoading || _isLoadingMore) {
      debugPrint('Listings already loading, waiting...');
      // Attendre que le chargement en cours se termine
      while (_isLoading || _isLoadingMore) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _listings;
    }

    if (page == 1) {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    } else {
      _isLoadingMore = true;
    }
    notifyListeners();

    final capturedSessionId = _sessionId; // Capturer la session actuelle

    try {
      debugPrint('Fetching listings from API: $endpoint?page=$page&limit=10');
      final response = await _apiClient.dio
          .get(endpoint, queryParameters: {'page': page, 'limit': 10});

      // Vérifier si la session est toujours la même après l'async
      if (capturedSessionId != _sessionId) {
        debugPrint(
            'Aborting listings update: session changed (logout occurred)');
        return _listings;
      }

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;

      final newItems = data.map((json) => Property.fromJson(json)).toList();

      if (page == 1) {
        _listings = newItems;
      } else {
        _listings.addAll(newItems);
      }

      _isLoaded = true;
      _lastFetchTime = DateTime.now();
      _currentPage = page;

      // Check if there are more items to load
      if (newItems.length < 10) {
        _hasMore = false;
      }

      debugPrint(
          'Fetched ${newItems.length} listings from $endpoint (Total: ${_listings.length}, hasMore: $_hasMore)');
      return _listings;
    } catch (e) {
      debugPrint('Error fetching listings from $endpoint: $e');
      if (page == 1 && forceRefresh) {
        // En cas d'échec sur refresh, on peut choisir de vider ou pas.
        // On conserve l'existant.
      }
      return _listings;
    } finally {
      if (capturedSessionId == _sessionId) {
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreListings() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _currentEndpoint.isEmpty)
      return;
    await _fetchListings(_currentEndpoint, page: _currentPage + 1);
  }

  Future<List<Property>> getListingsByType(String type) async {
    try {
      final response = await _apiClient.dio
          .get('/api/properties', queryParameters: {'type': type});
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;
      return data.map((json) => Property.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching listings by type: $e');
      return [];
    }
  }
}
