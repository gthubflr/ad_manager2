import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyServer = 'ad_server';
  static const String _keyDomain = 'ad_domain';
  static const String _keyUser = 'ad_user';
  static const String _keyPort = 'ad_port';
  static const String _keySSL = 'ad_ssl';
  static const String _keySave = 'ad_save_credentials';

  // Daten speichern (außer Passwort!)
  static Future<void> saveLoginData({
    required String server,
    required String domain,
    required String user,
    required String port,
    required bool useSSL,
    required bool shouldSave,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySave, shouldSave);
    
    if (shouldSave) {
      await prefs.setString(_keyServer, server);
      await prefs.setString(_keyDomain, domain);
      await prefs.setString(_keyUser, user);
      await prefs.setString(_keyPort, port);
      await prefs.setBool(_keySSL, useSSL);
    } else {
      // Wenn "Speichern" abgewählt wird, Daten löschen
      await prefs.clear();
    }
  }

  // Daten laden
  static Future<Map<String, dynamic>> loadLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'server': prefs.getString(_keyServer) ?? '',
      'domain': prefs.getString(_keyDomain) ?? '',
      'user': prefs.getString(_keyUser) ?? '',
      'port': prefs.getString(_keyPort) ?? '636',
      'ssl': prefs.getBool(_keySSL) ?? true,
      'shouldSave': prefs.getBool(_keySave) ?? false,
    };
  }
}