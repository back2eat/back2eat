import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userMobileKey = 'user_mobile';
  static const _userRoleKey = 'user_role';

  final SharedPreferences _prefs;
  TokenStorage(this._prefs);

  // In-memory access token (faster reads)
  String? _accessToken;
  String? get accessToken => _accessToken ?? _prefs.getString(_accessKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    await _prefs.setString(_accessKey, accessToken);
    await _prefs.setString(_refreshKey, refreshToken);
  }

  Future<void> saveUser({
    required String id,
    String? name,
    required String mobile,
    required String role,
  }) async {
    await _prefs.setString(_userIdKey, id);
    await _prefs.setString(_userMobileKey, mobile);
    await _prefs.setString(_userRoleKey, role);
    if (name != null) await _prefs.setString(_userNameKey, name);
  }

  String? get refreshToken => _prefs.getString(_refreshKey);
  String? get userId => _prefs.getString(_userIdKey);
  String? get userName => _prefs.getString(_userNameKey);
  String? get userMobile => _prefs.getString(_userMobileKey);
  String? get userRole => _prefs.getString(_userRoleKey);

  bool get isLoggedIn => accessToken != null;

  Future<void> clear() async {
    _accessToken = null;
    await _prefs.remove(_accessKey);
    await _prefs.remove(_refreshKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userNameKey);
    await _prefs.remove(_userMobileKey);
    await _prefs.remove(_userRoleKey);
  }
}