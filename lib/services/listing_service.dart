import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/models/user_model.dart';
import 'package:dramus/core/api/api_client.dart';

class ListingService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient.I;

  // Cache des données
  List<Property> _listings = [];
  bool _isLoading = false;
  bool _isLoaded = false;
  DateTime? _lastFetchTime;

  // Getters pour accéder aux données en cache
  List<Property> get cachedListings => _listings;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;

  // Durée de validité du cache (5 minutes)
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  // Vérifier si le cache est encore valide
  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration;
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
    _isLoaded = false;
    _lastFetchTime = null;
    debugPrint('Cache invalidated');
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

      // Check for wrapped response first (with 'data' key)
      if (response.data is Map && response.data.containsKey('data')) {
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

  Future<bool> createListing(Property property) async {
    try {
      debugPrint('ListingService.createListing: Starting to create listing');
      debugPrint(
          'ListingService.createListing: Property data: ${property.toJson()}');

      final response =
          await _apiClient.dio.post('/api/properties', data: property.toJson());

      debugPrint(
          'ListingService.createListing: Response status: ${response.statusCode}');
      debugPrint(
          'ListingService.createListing: Response data: ${response.data}');

      if (response.statusCode == 201) {
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

  // Récupérer les annonces pour une agence (toutes les annonces pour l'instant)
  Future<List<Property>> getAgencyListings(String agencyId,
      {bool forceRefresh = false}) async {
    // Les agences voient les annonces de leurs agents
    return await _fetchListings('/api/properties/agency/$agencyId',
        forceRefresh: forceRefresh);
  }

  // Méthode privée pour factoriser la logique de récupération
  Future<List<Property>> _fetchListings(String endpoint,
      {bool forceRefresh = false}) async {
    // Si les données sont déjà chargées et le cache est valide, retourner les données en cache
    if (_isLoaded && !forceRefresh && _isCacheValid()) {
      debugPrint('Returning cached listings (${_listings.length} items)');
      return _listings;
    }

    // Éviter les chargements multiples simultanés
    if (_isLoading) {
      debugPrint('Listings already loading, waiting...');
      // Attendre que le chargement en cours se termine
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _listings;
    }

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Fetching listings from API: $endpoint');
      final response = await _apiClient.dio.get(endpoint);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;

      _listings = data.map((json) => Property.fromJson(json)).toList();
      _isLoaded = true;
      _lastFetchTime = DateTime.now();

      debugPrint('Fetched ${_listings.length} listings from $endpoint');
      return _listings;
    } catch (e) {
      debugPrint('Error fetching listings from $endpoint: $e');
      return _listings; // Retourner les données en cache même en cas d'erreur
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
