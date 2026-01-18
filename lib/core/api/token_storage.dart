import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles persisting and retrieving auth tokens.
class TokenStorage {
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUser = 'auth_user_json';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAccessToken, accessToken);
      await prefs.setString(_kRefreshToken, refreshToken);
    } catch (e) {
      debugPrint('TokenStorage.saveTokens error: $e');
    }
  }

  Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kAccessToken);
    } catch (e) {
      debugPrint('TokenStorage.getAccessToken error: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kRefreshToken);
    } catch (e) {
      debugPrint('TokenStorage.getRefreshToken error: $e');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAccessToken);
      await prefs.remove(_kRefreshToken);
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
