import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:dramus/core/api/api_client.dart';
import 'package:dramus/core/api/token_storage.dart';
import 'package:dramus/models/user_model.dart';

class AuthService {
  final Dio _dio = ApiClient.I.dio;
  final TokenStorage _storage = TokenStorage();

  // singleton instance
  static final AuthService instance = AuthService();

  Future<User?> login(String phone, String password) async {
    try {
      debugPrint('AuthService.login called with phone: $phone');
      final res = await _dio.post('/api/auth/login',
          data: {'phone': phone, 'password': password},
          options: Options(headers: {
            'Authorization': null
          })); // Explicitly remove auth header
      debugPrint('AuthService.login response status: ${res.statusCode}');
      debugPrint('AuthService.login response data: ${res.data}');

      // backend wraps payload in { success,message,data: { user, token, refreshToken }}
      final body = res.data as Map<String, dynamic>?;
      final data = body != null && body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : null;

      final access = data != null
          ? (data['token'] ?? data['accessToken']) as String?
          : null;
      final refresh = data != null
          ? (data['refreshToken'] ?? data['refresh']) as String?
          : null;
      final userJson = data != null && data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : null;

      debugPrint(
          'AuthService.login parsed - access: ${access != null}, refresh: ${refresh != null}, user: ${userJson != null}');

      if (access != null && refresh != null) {
        await _storage.saveTokens(accessToken: access, refreshToken: refresh);
      }
      if (userJson != null) {
        await _storage.saveUserJson(userJson);
        final user = User.fromJson(userJson);

        // Fetch complete profile after successful login
        try {
          final updatedUser = await getProfile();
          if (updatedUser != null) {
            debugPrint(
                'AuthService.login: Using updated profile from getProfile');
            return updatedUser;
          }
        } catch (e) {
          debugPrint(
              'AuthService.login: Failed to fetch profile after login: $e');
          // Don't fail the login if profile fetch fails, just log it
        }

        return user;
      }
      return null;
    } catch (e) {
      debugPrint('AuthService.login error: $e');
      if (e is DioException && e.response != null) {
        debugPrint('AuthService.login error response: ${e.response?.data}');
        debugPrint('AuthService.login error status: ${e.response?.statusCode}');
        debugPrint(
            'AuthService.login request headers: ${e.requestOptions.headers}');
        debugPrint('AuthService.login request data: ${e.requestOptions.data}');
      }
      rethrow;
    }
  }

  /*Future<User?> signup(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/api/auth/signup', data: payload);
      final body = res.data as Map<String, dynamic>?;
      final data = body != null && body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : null;

      final access = data != null
          ? (data['token'] ?? data['accessToken']) as String?
          : null;
      final refresh = data != null
          ? (data['refreshToken'] ?? data['refresh']) as String?
          : null;
      final userJson = data != null && data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : null;

      if (access != null && refresh != null) {
        await _storage.saveTokens(accessToken: access, refreshToken: refresh);
      }
      if (userJson != null) {
        await _storage.saveUserJson(userJson);
        return User.fromJson(userJson);
      }
      return null;
    } catch (e) {
      debugPrint('AuthService.signup error: $e');
      rethrow;
    }
  }*/

  Future<User?> getProfile() async {
    try {
      debugPrint('AuthService.getProfile called');
      final res = await _dio.get('/api/users/me');
      debugPrint('AuthService.getProfile response status: ${res.statusCode}');
      debugPrint('AuthService.getProfile response data: ${res.data}');

      // backend wraps payload in { success,message,data: { user }}
      final body = res.data as Map<String, dynamic>?;
      final data = body != null && body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : null;

      final userJson = data != null && data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : (data != null
              ? data
              : body); // fallback if user is directly in data or body

      if (userJson != null) {
        await _storage.saveUserJson(userJson);
        return User.fromJson(userJson);
      }
      return null;
    } catch (e) {
      debugPrint('AuthService.getProfile error: $e');
      if (e is DioException && e.response != null) {
        debugPrint(
            'AuthService.getProfile error response: ${e.response?.data}');
        debugPrint(
            'AuthService.getProfile error status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  Future<User?> me() async {
    try {
      final res = await _dio.get('/api/users/me');
      final data = res.data as Map<String, dynamic>;
      await _storage.saveUserJson(data);
      return User.fromJson(data);
    } catch (e) {
      debugPrint('AuthService.me error: $e');
      return null;
    }
  }

  Future<Response> register({
    required Map<String, dynamic> data,
    File? avatar,
    bool isAgency = false,
  }) async {
    try {
      final endpoint = isAgency ? '/api/agencies' : '/api/auth/signup';
      debugPrint(
          'AuthService.register outgoing payload: $data, avatar: ${avatar?.path}, endpoint: $endpoint');

      Response res;

      // If there's no avatar, many backends expect JSON rather than multipart.
      if (avatar == null) {
        res = await _dio.post(endpoint,
            data: data, options: Options(validateStatus: (status) => true));
      } else {
        final form = FormData();
        data.forEach((key, value) {
          if (value != null) form.fields.add(MapEntry(key, value.toString()));
        });
        final fileName = avatar.path.split('/').last;
        form.files.add(MapEntry('avatar',
            MultipartFile.fromFileSync(avatar.path, filename: fileName)));

        res = await _dio.post(endpoint,
            data: form,
            options: Options(
                contentType: 'multipart/form-data',
                validateStatus: (status) => true));
      }

      debugPrint('AuthService.register status: ${res.statusCode}');

      // Persist tokens/user only on success (2xx)
      if (res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300) {
        try {
          final body = res.data;
          if (body is Map<String, dynamic>) {
            // Le backend enveloppe la réponse dans { success, data: { user, token, refreshToken } }
            final data = body['data'] is Map<String, dynamic>
                ? body['data'] as Map<String, dynamic>
                : body;
            // Le backend retourne 'token' (pas 'accessToken')
            final access = (data['token'] ?? data['accessToken']) as String?;
            final refresh =
                (data['refreshToken'] ?? data['refresh']) as String?;
            final userJson = data['user'] is Map<String, dynamic>
                ? data['user'] as Map<String, dynamic>
                : null;
            if (access != null && refresh != null) {
              await _storage.saveTokens(
                  accessToken: access, refreshToken: refresh);
              debugPrint(
                  'AuthService.register: Tokens sauvegardés avec succès');
            }
            if (userJson != null) {
              await _storage.saveUserJson(userJson);
              debugPrint(
                  'AuthService.register: User JSON sauvegardé avec succès');
            }
          }
        } catch (e) {
          debugPrint('AuthService.register response handling error: $e');
        }
      } else {
        // Log error body for debugging
        debugPrint('AuthService.register error body: ${res.data}');
      }

      return res;
    } on DioException catch (e) {
      debugPrint('AuthService.register DioException: $e');
      if (e.response != null) return e.response!;
      rethrow;
    } catch (e) {
      debugPrint('AuthService.register error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('AuthService.logout called');
      // Optionally call logout endpoint on server
      try {
        await _dio.post('/api/auth/logout');
        debugPrint('AuthService.logout: Server logout successful');
      } catch (e) {
        debugPrint('AuthService.logout: Server logout failed: $e');
        // Continue with local logout even if server logout fails
      }

      // Clear local tokens and user data
      await _storage.clear();
      debugPrint('AuthService.logout: Local data cleared');
    } catch (e) {
      debugPrint('AuthService.logout error: $e');
      // Still clear local data even if there was an error
      await _storage.clear();
      rethrow;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      final res =
          await _dio.post('/api/auth/forgot-password', data: {'email': email});
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('AuthService.forgotPassword error: $e');
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      final res = await _dio.post('/api/auth/reset-password',
          data: {'otp': token, 'password': newPassword});
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('AuthService.resetPassword error: $e');
      return false;
    }
  }

  Future<bool> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      final res = await _dio.put('/api/auth/update-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('AuthService.updatePassword error: $e');
      return false;
    }
  }
}
