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
  Future<void> refreshListings() async {
    debugPrint('Forcing listings refresh...');
    await getListings(forceRefresh: true);
  }

  // Invalider le cache (utile après création/modification/suppression)
  void invalidateCache() {
    _isLoaded = false;
    _lastFetchTime = null;
    debugPrint('Cache invalidated');
  }

  Future<List<Property>> getListings({bool forceRefresh = false}) async {
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
      debugPrint('Fetching listings from API...');
      final response = await _apiClient.dio.get('/api/properties');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;

      _listings = data.map((json) => Property.fromJson(json)).toList();
      _isLoaded = true;
      _lastFetchTime = DateTime.now();

      debugPrint('Fetched ${_listings.length} listings from API');
      return _listings;
    } catch (e) {
      debugPrint('Error fetching listings: $e');
      return _listings; // Retourner les données en cache même en cas d'erreur
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Property?> getListingById(String id) async {
    try {
      final response = await _apiClient.dio.get('/api/properties/$id');
      return Property.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching listing: $e');
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
      final response = await _apiClient.dio
          .put('/api/properties/$id', data: property.toJson());
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating listing: $e');
      return false;
    }
  }

  Future<bool> deleteListing(String id) async {
    try {
      final response = await _apiClient.dio.delete('/api/properties/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting listing: $e');
      return false;
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

  // Filtrer les annonces selon le rôle de l'utilisateur
  List<Property> getFilteredListingsForUser(User user) {
    final allListings = cachedListings;

    switch (user.role.toLowerCase()) {
      case 'client':
        // Client voit toutes les annonces
        return allListings;

      case 'particulier':
      case 'agent':
        // Particulier et agent voient seulement leurs propres annonces
        return allListings
            .where((property) => property.ownerId == user.id)
            .toList();

      case 'agence':
      case 'agency':
        // Agence voit toutes les annonces (temporairement, en attendant la vraie logique agence-agent)
        // TODO: Implémenter la logique pour récupérer les agents de l'agence
        // Pour l'instant, agence voit toutes les annonces comme un client
        return allListings;

      default:
        // Par défaut, voir toutes les annonces
        return allListings;
    }
  }
}
