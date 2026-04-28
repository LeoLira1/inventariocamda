import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  static const _dbUrlKey = 'turso_db_url';
  static const _tokenKey = 'turso_auth_token';

  Future<String> getDbUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dbUrlKey) ?? '';
  }

  Future<void> saveDbUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dbUrlKey, value);
  }

  Future<String> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) ?? '';
  }

  Future<void> saveAuthToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, value);
  }
}
