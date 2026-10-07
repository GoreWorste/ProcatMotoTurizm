import 'package:dio/dio.dart';

import 'api_exceptions.dart';
import 'config.dart';

/// Тексты для экрана ошибки списка (сервер / CORS).
class ApiErrorPresentation {
  const ApiErrorPresentation({
    required this.title,
    required this.summary,
    required this.serverChecks,
    required this.corsChecks,
  });

  final String title;
  final String summary;
  final List<String> serverChecks;
  final List<String> corsChecks;
}

bool isConnectionFailure(Object? error) {
  if (error is NetworkException) return true;
  if (error is DioException) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }
  final text = error?.toString().toLowerCase() ?? '';
  return text.contains('cors') ||
      text.contains('connection') ||
      text.contains('socket') ||
      text.contains('network');
}

bool _looksLikeCors(DioException e) {
  final blob = '${e.message} ${e.error}'.toLowerCase();
  return blob.contains('cors') ||
      blob.contains('access-control') ||
      blob.contains('xmlhttprequest');
}

ApiErrorPresentation connectionFailurePresentation(Object? error) {
  final summary = describeError(error ?? 'Ошибка сети');
  final corsLikely = error is DioException && _looksLikeCors(error);

  final title = corsLikely
      ? 'Ошибка CORS: браузер заблокировал запрос к API'
      : 'Сервер не отвечает';

  final healthUrl = apiBaseUrl.endsWith('/')
      ? '${apiBaseUrl}__health'
      : '$apiBaseUrl/__health';

  return ApiErrorPresentation(
    title: title,
    summary: summary,
    serverChecks: [
      'Запустите API: .\\scripts\\run_api_server.ps1',
      'В браузере откройте: $healthUrl',
      'Должен открыться JSON с "ok": true',
      'После запуска нажмите «Повторить»',
    ],
    corsChecks: [
      'Клиент (Flutter Web): http://localhost:5555',
      'API: порт 8080, параметр --origin http://localhost:5555',
      'Адрес API в приложении: $apiBaseUrl',
      'В DevTools (F12) → Console ищите "CORS" / "blocked by CORS policy"',
    ],
  );
}
