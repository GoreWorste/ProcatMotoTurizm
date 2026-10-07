import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер не отвечает. Проверьте, что API запущен на порту 8080.',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Недостаточно прав для этого действия.']);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

class ConflictException extends ApiException {
  const ConflictException(super.message);
}

class ValidationException extends ApiException {
  const ValidationException(super.message, this.errors);

  final Map<String, String> errors;
}

class ServerException extends ApiException {
  const ServerException([super.message = 'Ошибка на сервере. Попробуйте позже.']);
}

ApiException mapHttpError(int status, dynamic body) {
  final message = (body is Map && body['message'] is String)
      ? body['message'] as String
      : null;
  return switch (status) {
    401 => UnauthorizedException(message ?? 'Требуется вход в систему.'),
    403 => ForbiddenException(message ?? 'Недостаточно прав для этого действия.'),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(message ?? 'Операция невозможна.'),
    422 => ValidationException(
        message ?? 'Ошибка валидации',
        (body is Map && body['errors'] is Map)
            ? (body['errors'] as Map).map(
                (k, v) => MapEntry('$k', '$v'),
              )
            : const {},
      ),
    _ => ServerException(message ?? 'Неизвестная ошибка (код $status).'),
  };
}

bool _looksLikeCorsInDio(DioException e) {
  final blob = '${e.message} ${e.error}'.toLowerCase();
  return blob.contains('cors') ||
      blob.contains('access-control') ||
      blob.contains('xmlhttprequest');
}

ApiException mapDioError(DioException e) {
  final existing = e.error;
  if (existing is ApiException) return existing;
  if (e.type == DioExceptionType.badResponse && e.response != null) {
    return mapHttpError(
      e.response!.statusCode ?? 500,
      e.response!.data,
    );
  }
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      const NetworkException('Сервер не ответил вовремя.'),
    DioExceptionType.connectionError => NetworkException(
        _looksLikeCorsInDio(e)
            ? 'Запрос к API заблокирован (вероятно CORS). '
                'См. подсказки на экране и консоль F12.'
            : 'Сервер не отвечает (connection refused). '
                'Запустите mock API на порту 8080.',
      ),
    DioExceptionType.cancel => const NetworkException('Запрос отменён.'),
    _ => const ServerException(),
  };
}

Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}

String describeError(Object error) {
  if (error is ApiException) return error.message;
  return error.toString();
}

Object mapLoadError(Object e) {
  if (e is ApiException) return e;
  if (e is DioException) return mapDioError(e);
  return NetworkException(e.toString());
}
