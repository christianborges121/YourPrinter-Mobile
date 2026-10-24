import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyServerUrl = 'ff_server_url';
  static const String _keyAuthToken = 'ff_auth_token';
  static const String _keyOverride30s = 'ff_camera_override_30s';
  static const String _keyLastContextId = 'ff_last_context_id';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  String getServerUrl({String defaultValue = 'http://192.168.1.50:8080'}) {
    return _prefs.getString(_keyServerUrl) ?? defaultValue;
  }

  Future<bool> setServerUrl(String url) {
    return _prefs.setString(_keyServerUrl, url);
  }

  String? getAuthToken() {
    return _prefs.getString(_keyAuthToken);
  }

  Future<bool> setAuthToken(String? token) {
    if (token == null) {
      return _prefs.remove(_keyAuthToken);
    }
    return _prefs.setString(_keyAuthToken, token);
  }

  bool isStreamTimeoutOverridden() {
    return _prefs.getBool(_keyOverride30s) ?? false;
  }

  Future<bool> setStreamTimeoutOverridden(bool override) {
    return _prefs.setBool(_keyOverride30s, override);
  }

  String? getLastContextId() {
    return _prefs.getString(_keyLastContextId);
  }

  Future<bool> setLastContextId(String contextId) {
    return _prefs.setString(_keyLastContextId, contextId);
  }
}
