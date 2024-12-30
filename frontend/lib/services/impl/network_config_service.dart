// lib/services/network_config_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class NetworkConfigService {
  static const String _externalUrl = 'http://47.151.18.30:8000'; // Update this
  static const String _localUrl = 'http://192.168.4.26:8000'; // Update this
  static const String _prefKey = 'use_external_ip';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final useExternalIp = prefs.getBool(_prefKey) ?? false;
    return useExternalIp ? _externalUrl : _localUrl;
  }

  static Future<void> setUseExternalIp(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }
}
