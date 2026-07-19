import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles persisting and retrieving auth tokens securely.
class TokenStorage {
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUser = 'auth_user_json';

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {
    try {
      await _secureStorage.write(key: _kAccessToken, value: accessToken);
      await _secureStorage.write(key: _kRefreshToken, value: refreshToken);
    } catch (e) {
      debugPrint('TokenStorage.saveTokens error: $e');
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _kAccessToken);
    } catch (e) {
      debugPrint('TokenStorage.getAccessToken error: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _kRefreshToken);
    } catch (e) {
      debugPrint('TokenStorage.getRefreshToken error: $e');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _secureStorage.delete(key: _kAccessToken);
      await _secureStorage.delete(key: _kRefreshToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUser);
    } catch (e) {
      debugPrint('TokenStorage.clear error: $e');
    }
  }

  Future<void> saveUserJson(Map<String, dynamic> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUser, jsonEncode(json));
    } catch (e) {
      debugPrint('TokenStorage.saveUserJson error: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserJson() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kUser);
      if (raw == null) return null;
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) return map;
      return null;
    } catch (e) {
      debugPrint('TokenStorage.getUserJson error: $e');
      return null;
    }
  }
}
