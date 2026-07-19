import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dramus/models/user_model.dart';
import 'package:dramus/core/api/token_storage.dart';
import 'package:dramus/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController();

  final TokenStorage _storage = TokenStorage();
  User? _user;
  bool _initialized = false;
  bool _isLoading = false;
  bool _isOffline = false;
  final List<VoidCallback> _signOutListeners = [];

  User? get user => _user;
  String? get role => _user?.role;
  bool get isInitialized => _initialized;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;

  void setOffline(bool value) {
    _isOffline = value;
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _isLoading = true;
    notifyListeners();
    try {
      await loadFromStorage();
      await checkAuthStatus();
    } finally {
      _isLoading = false;
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> loadFromStorage() async {
    final json = await _storage.getUserJson();
    if (json != null) {
      _user = User.fromJson(json);
      notifyListeners();
    }
  }

  Future<bool> checkAuthStatus() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      await signOut(skipServerLogout: true);
      return false;
    }

    try {
      final connectivity = await Connectivity().checkConnectivity();
      final hasNetwork = connectivity.isNotEmpty &&
          !connectivity.contains(ConnectivityResult.none);

      if (!hasNetwork) {
        _isOffline = true;
        notifyListeners();
        return true; // keep cached session
      }

      final user = await AuthService.instance.getProfile();
      if (user != null) {
        _user = user;
        _isOffline = false;
        await _storage.saveUserJson(user.toJson());
        notifyListeners();
        return true;
      }
      await signOut(skipServerLogout: true);
      return false;
    } on DioException catch (e) {
      debugPrint('AuthController.checkAuthStatus DioException: $e');
      if (e.response?.statusCode == 401) {
        await signOut(skipServerLogout: true);
        return false;
      }
      // Network/server error but token exists: keep cached session.
      _isOffline = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthController.checkAuthStatus error: $e');
      // Any other error while a token exists is treated as offline.
      _isOffline = true;
      notifyListeners();
      return true;
    }
  }

  Future<bool> restoreSession() => checkAuthStatus();

  void setUser(User? u) {
    _user = u;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  /// Register a callback that will be called every time [signOut] runs.
  /// Used by services to clear their in-memory caches.
  void addSignOutListener(VoidCallback listener) {
    _signOutListeners.add(listener);
  }

  void removeSignOutListener(VoidCallback listener) {
    _signOutListeners.remove(listener);
  }

  Future<void> signOut({bool skipServerLogout = false}) async {
    try {
      _user = null;
      await AuthService.instance.logout(skipServerLogout);
    } catch (e) {
      debugPrint('AuthController.signOut error: $e');
    } finally {
      // Notify every registered service that it should clear its cache.
      for (final listener in _signOutListeners) {
        try {
          listener();
        } catch (e) {
          debugPrint('AuthController.signOut listener error: $e');
        }
      }
      notifyListeners();
    }
  }

  Future<void> logout() => signOut();
}
