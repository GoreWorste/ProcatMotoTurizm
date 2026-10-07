/// Базовый URL API задаётся при сборке/запуске, не константой в коде.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

/// true — данные с сервера; false — локальный режим ПР3 (отладка без Node).
const useApiBackend = bool.fromEnvironment(
  'USE_API',
  defaultValue: true,
);

/// Автовыход при неактивности (ПР5, по умолчанию 30 минут).
const inactivityLogoutDuration = Duration(
  minutes: int.fromEnvironment('INACTIVITY_MINUTES', defaultValue: 30),
);
