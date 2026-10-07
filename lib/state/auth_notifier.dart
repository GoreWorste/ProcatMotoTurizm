import 'package:flutter/foundation.dart';

import '../api/auth_api.dart';
import '../core/api_exceptions.dart';
import '../core/config.dart';
import '../models/app_user.dart';
import '../models/role.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';

  AuthNotifier(this._prefs, this._api);

  final SharedPreferences _prefs;
  final AuthApi _api;

  AppUser? _user;
  String? _accessToken;
  bool _restoring = false;

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => !useApiBackend || _user != null;
  bool get isRestoring => _restoring;

  bool has(Role role) {
    if (!useApiBackend) return true;
    return _user != null && _user!.role.level >= role.level;
  }

  Future<void> restore() async {
    if (!useApiBackend) return;
    _restoring = true;
    notifyListeners();

    final access = _prefs.getString(_kAccess);
    final refresh = _prefs.getString(_kRefresh);
    if (access == null) {
      _restoring = false;
      notifyListeners();
      return;
    }

    _accessToken = access;
    try {
      _user = await _api.me(access);
    } on UnauthorizedException {
      if (refresh != null) {
        try {
          await _refreshWith(refresh);
        } catch (_) {
          await logout();
        }
      } else {
        await logout();
      }
    } catch (_) {
      // Сеть недоступна: оставляем токен, пользователь увидит ошибки списков.
    }

    _restoring = false;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await _api.login(username, password);
    await _applyTokens(result);
  }

  Future<void> register({
    required String username,
    required String password,
    String? displayName,
  }) async {
    final result = await _api.register(
      username: username,
      password: password,
      displayName: displayName,
    );
    await _applyTokens(result);
  }

  Future<void> logout() async {
    _user = null;
    _accessToken = null;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    notifyListeners();
  }

  /// Обновление access по refresh (Dio interceptor и restore).
  Future<bool> refreshTokens() async {
    final refresh = _prefs.getString(_kRefresh);
    if (refresh == null) return false;
    try {
      await _refreshWith(refresh);
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> _refreshWith(String refreshToken) async {
    final result = await _api.refresh(refreshToken);
    await _applyTokens(result);
  }

  Future<void> _applyTokens(AuthTokens result) async {
    _accessToken = result.accessToken;
    _user = result.user;
    await _prefs.setString(_kAccess, result.accessToken);
    await _prefs.setString(_kRefresh, result.refreshToken);
    notifyListeners();
  }
}
