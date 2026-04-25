import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:dramus/core/api/token_storage.dart';

/// Centralized Dio client with JWT and refresh-token interceptor.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get I => _instance;
  // Alias pour la compatibilité si utilisé ailleurs
  static ApiClient get instance => _instance;

  late final Dio dio;
  final TokenStorage _storage = TokenStorage();
  bool _isRefreshing = false;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment('API_BASE_URL',
            defaultValue: 'https://dramus-api.onrender.com'),
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Allow request to proceed without token if it's explicitly public or refresh
        if (options.headers.containsKey('Authorization') &&
            options.headers['Authorization'] == null) {
          options.headers.remove('Authorization');
          return handler.next(options);
        }

        // Add token if not present
        if (!options.headers.containsKey('Authorization')) {
          final token = await _storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        // Handle 401 Unauthorized
        if (e.response?.statusCode == 401) {
          final path = e.requestOptions.path;

          // If the error comes from the refresh endpoint itself, or login, fail immediately
          if (path.contains('refresh-token') || path.contains('login')) {
            if (path.contains('refresh-token')) {
              await _storage.clear(); // Session expired
            }
            return handler.next(e);
          }

          // Avoid multiple concurrent refreshes
          if (_isRefreshing) {
            // Simplified: fail concurrent requests, or implement a queue/completer system
            // For now, we propagate error to avoid deadlock
            return handler.next(e);
          }

          _isRefreshing = true;
          try {
            final refreshed = await _refreshToken();
            _isRefreshing = false;

            if (refreshed) {
              // Retry original request with new token
              final opts = e.requestOptions;
              final newToken = await _storage.getAccessToken();

              opts.headers['Authorization'] = 'Bearer $newToken';

              try {
                final cloneReq = await dio.request(
                  opts.path,
                  options: Options(
                    method: opts.method,
                    headers: opts.headers,
                  ),
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                );
                return handler.resolve(cloneReq);
              } catch (retryError) {
                // If retry fails, return original error or retry error
                return handler.next(e);
              }
            } else {
              // Refresh failed
              await _storage.clear();
            }
          } catch (refreshError) {
            _isRefreshing = false;
            await _storage.clear();
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      // Use a temporary Dio instance to avoid interceptor loops
      final tempDio = Dio(dio.options);
      // Remove auth header for refresh request
      tempDio.options.headers.remove('Authorization');

      debugPrint('Attempting refresh token...');
      final response = await tempDio.post(
        '/api/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse response
        final body = response.data;
        // Adapt based on API response structure.
        // Assuming: { success: true, data: { accessToken: "...", refreshToken: "..." } }
        // OR direct: { accessToken: "...", refreshToken: "..." }

        Map<String, dynamic> data;
        if (body is Map<String, dynamic>) {
          if (body.containsKey('data') && body['data'] is Map) {
            data = body['data'];
          } else {
            data = body;
          }
        } else {
          return false;
        }

        final newAccessToken = data['accessToken'] ?? data['token'];
        final newRefreshToken = data['refreshToken'];

        if (newAccessToken != null) {
          debugPrint('Token refresh successful');
          await _storage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken ?? refreshToken,
          );
          return true;
        }
      }
      debugPrint('Token refresh failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }
}
