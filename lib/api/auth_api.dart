import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/config.dart';
import '../models/app_user.dart';

class AuthApi {
  AuthApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: apiBaseUrl,
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 12),
                headers: {'Content-Type': 'application/json'},
                validateStatus: (s) => s != null && s < 500,
              ),
            );

  final Dio _dio;

  Future<AuthTokens> login(String username, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    return _parseAuthResponse(response);
  }

  Future<AuthTokens> register({
    required String username,
    required String password,
    String? displayName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'username': username,
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'displayName': displayName,
      },
    );
    return _parseAuthResponse(response);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return _parseAuthResponse(response);
  }

  Future<AppUser> me(String accessToken) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    _throwIfBad(response);
    return AppUser.fromJson(response.data ?? {});
  }

  Future<List<AppUser>> listUsers(String accessToken) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/users',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    _throwIfBad(response);
    final items = response.data?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  AuthTokens _parseAuthResponse(Response<Map<String, dynamic>> response) {
    _throwIfBad(response);
    final data = response.data ?? {};
    return AuthTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  void _throwIfBad(Response<Map<String, dynamic>> response) {
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: mapHttpError(status, response.data),
      );
    }
  }
}
