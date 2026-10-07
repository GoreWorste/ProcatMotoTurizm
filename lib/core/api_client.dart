import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

typedef RefreshTokensCallback = Future<bool> Function();

Dio buildDio({
  String? Function()? tokenProvider,
  RefreshTokensCallback? onRefreshTokens,
}) {
  late final Dio dio;
  dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        if (kDebugMode) {
          debugPrint(
            '[API] ${response.requestOptions.method} '
            '${response.requestOptions.uri} → $status',
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint(
            '[API] сбой ${error.requestOptions.uri}: ${error.type}',
          );
        }
        return handler.next(error);
      },
    ),
  );

  if (onRefreshTokens != null) {
    dio.interceptors.add(
      _AuthRefreshInterceptor(
        dio: dio,
        tokenProvider: tokenProvider,
        onRefreshTokens: onRefreshTokens,
      ),
    );
  }

  return dio;
}

class _AuthRefreshInterceptor extends QueuedInterceptor {
  _AuthRefreshInterceptor({
    required this.dio,
    required this.tokenProvider,
    required this.onRefreshTokens,
  });

  final Dio dio;
  final String? Function()? tokenProvider;
  final RefreshTokensCallback onRefreshTokens;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    if (status == 401 && !path.contains('/auth/')) {
      try {
        final ok = await onRefreshTokens();
        if (ok) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer ${tokenProvider?.call()}';
          final response = await dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (_) {
        // logout внутри onRefreshTokens
      }
    }
    return handler.next(err);
  }
}
