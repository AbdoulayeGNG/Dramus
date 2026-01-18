import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:dramus/core/api/token_storage.dart';

/// Centralized Dio client with JWT and refresh-token interceptor.
class ApiClient {
  ApiClient._(this._dio);

  final Dio _dio;
  static final TokenStorage _storage = TokenStorage();

  static ApiClient? _instance;
  static ApiClient get I => _instance ??= ApiClient._(_createDio());

  Dio get dio => _dio;

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        // Use an environment variable name and a sensible default base URL.
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
        final token = await _storage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        // Attempt refresh on 401
        if (e.response?.statusCode == 401) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            try {
              final reqOptions = e.requestOptions;
              final response = await dio.request(
                reqOptions.path,
                data: reqOptions.data,
                queryParameters: reqOptions.queryParameters,
                options: Options(
                  method: reqOptions.method,
                  headers: reqOptions.headers,
                ),
              );
              return handler.resolve(response);
            } catch (e2) {
              debugPrint('Retry after refresh failed: $e2');
            }
          }
        }
        return handler.next(e);
      },
    ));
    return dio;
  }

  static Future<bool> _tryRefresh() async {
    try {
      final refresh = await _storage.getRefreshToken();
      if (refresh == null || refresh.isEmpty) return false;
      final res = await ApiClient.I._dio
          .post('/api/auth/refresh-token', data: {'refreshToken': refresh});
      final data = res.data as Map<String, dynamic>;
      final access = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String? ?? refresh;
      if (access == null) return false;
      await _storage.saveTokens(accessToken: access, refreshToken: newRefresh);
      return true;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      await _storage.clear();
      return false;
    }
  }
}
