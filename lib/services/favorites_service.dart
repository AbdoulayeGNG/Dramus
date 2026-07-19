import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dramus/core/api/api_client.dart';

class FavoritesService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient.I;

  // List de favoris (IDs des propriétés)
  Set<String> _favoriteIds = {};
  bool _isLoading = false;

  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;

  /// Vérifie si une propriété est favorite
  bool isFavorite(String propertyId) {
    return _favoriteIds.contains(propertyId);
  }

  /// Ajouter une propriété aux favoris
  Future<bool> addFavorite(String propertyId) async {
    try {
      debugPrint('FavoritesService: Adding favorite property: $propertyId');
      _isLoading = true;
      notifyListeners();

      final response = await _apiClient.dio.post(
        '/api/favorites/$propertyId',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _favoriteIds.add(propertyId);
        debugPrint('FavoritesService: Successfully added favorite: $propertyId');
        notifyListeners();
        return true;
      }

      debugPrint(
          'FavoritesService: Failed to add favorite - Status: ${response.statusCode}');
      return false;
    } on DioException catch (e) {
      debugPrint(
          'FavoritesService: Error adding favorite: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retirer une propriété des favoris
  Future<bool> removeFavorite(String propertyId) async {
    try {
      debugPrint('FavoritesService: Removing favorite property: $propertyId');
      _isLoading = true;
      notifyListeners();

      final response = await _apiClient.dio.delete(
        '/api/favorites/$propertyId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _favoriteIds.remove(propertyId);
        debugPrint(
            'FavoritesService: Successfully removed favorite: $propertyId');
        notifyListeners();
        return true;
      }

      debugPrint(
          'FavoritesService: Failed to remove favorite - Status: ${response.statusCode}');
      return false;
    } on DioException catch (e) {
      debugPrint(
          'FavoritesService: Error removing favorite: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Bascule l'état favori d'une propriété
  Future<bool> toggleFavorite(String propertyId) async {
    if (isFavorite(propertyId)) {
      return removeFavorite(propertyId);
    } else {
      return addFavorite(propertyId);
    }
  }

  /// Récupérer la liste des favoris de l'utilisateur
  Future<void> loadFavorites() async {
    try {
      debugPrint('FavoritesService: Loading user favorites');
      _isLoading = true;
      notifyListeners();

      final response = await _apiClient.dio.get('/api/favorites');

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> favorites = [];

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          favorites = data['data'] as List<dynamic>;
        } else if (data is List<dynamic>) {
          favorites = data;
        }

        _favoriteIds = favorites
            .map((fav) {
              if (fav is Map<String, dynamic>) {
                return fav['propertyId']?.toString() ??
                    fav['_id']?.toString() ??
                    fav['id']?.toString() ??
                    '';
              }
              return fav.toString();
            })
            .where((id) => id.isNotEmpty)
            .toSet();

        debugPrint(
            'FavoritesService: Loaded ${_favoriteIds.length} favorites');
        notifyListeners();
      }
    } on DioException catch (e) {
      debugPrint(
          'FavoritesService: Error loading favorites: ${e.message}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Réinitialiser les favoris (par exemple lors de la déconnexion)
  void clearFavorites() {
    _favoriteIds.clear();
    _isLoading = false;
    notifyListeners();
  }
}
