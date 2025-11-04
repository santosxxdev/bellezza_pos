import 'package:shared_preferences/shared_preferences.dart';
import 'package:bellezza_pos/config/app_config.dart';

class SharedPreferencesService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String getBaseUrl() {
    return _prefs.getString('baseUrl') ?? AppConfig.defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    await _prefs.setString('baseUrl', url);
  }

  static bool get isConfigured {
    final currentUrl = getBaseUrl();
    return currentUrl != AppConfig.defaultBaseUrl && currentUrl.isNotEmpty;
  }

}