import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/ldap_config.dart';
import '../services/ad_service.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  
  ADService? _adService;
  String? _errorMessage;
  LdapConfig? config;

  bool get isAuthenticated => _adService != null;
  ADService? get adService => _adService;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadSavedConfig();
  }

  // Diese Methode wird vom LoginScreen beim Start aufgerufen
// providers/auth_provider.dart

Future<void> loadPersistedConfig() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final server = prefs.getString('ldap_server');
    final domain = prefs.getString('ldap_domain');
    final username = prefs.getString('ldap_username');
    
    if (server != null && domain != null && username != null) {
      final password = await _storage.read(key: 'ldap_password');
      
      config = LdapConfig(
        server: server,
        domain: domain,
        username: username,
        password: password ?? '',
        useSSL: prefs.getBool('ldap_use_ssl') ?? true,
        validateCertificate: prefs.getBool('ldap_validate_cert') ?? true,
        port: prefs.getInt('ldap_port'),
        customCaCert: prefs.getString('ldap_custom_ca'),
      );
      print("Daten erfolgreich geladen: ${config!.server}");
      notifyListeners();
    }
  } catch (e) {
    print("Fehler beim Laden: $e");
  }
}

  Future<void> _loadSavedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final server = prefs.getString('ldap_server');
      final domain = prefs.getString('ldap_domain');
      final username = prefs.getString('ldap_username');
      final useSSL = prefs.getBool('ldap_use_ssl') ?? true;
      final validateCert = prefs.getBool('ldap_validate_cert') ?? true;
      final port = prefs.getInt('ldap_port');
      final customCaCert = prefs.getString('ldap_custom_ca');

      if (server != null && domain != null && username != null) {
        // Passwort aus dem Secure Storage lesen
        final password = await _storage.read(key: 'ldap_password');
        
        config = LdapConfig(
          server: server,
          domain: domain,
          username: username,
          password: password ?? '',
          useSSL: useSSL,
          validateCertificate: validateCert,
          port: port,
          customCaCert: customCaCert,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AuthProvider] Fehler beim Laden der Konfiguration: $e');
    }
  }

Future<void> _saveConfig(LdapConfig ldapConfig, {bool savePassword = false}) async {
  final prefs = await SharedPreferences.getInstance();
  
  // 1. Grundlegende Server-Einstellungen speichern
  await prefs.setString('ldap_server', ldapConfig.server);
  await prefs.setString('ldap_domain', ldapConfig.domain);
  await prefs.setString('ldap_username', ldapConfig.username);
  await prefs.setBool('ldap_use_ssl', ldapConfig.useSSL);
  await prefs.setBool('ldap_validate_cert', ldapConfig.validateCertificate);
  
  // 2. Passwort IMMER löschen (Sicherheitsrichtlinie)
  await _storage.delete(key: 'ldap_password'); 
  
  // 3. Port-Logik
  if (ldapConfig.port != null) {
    await prefs.setInt('ldap_port', ldapConfig.port!);
  } else {
    await prefs.remove('ldap_port');
  }
  
  // 4. Zertifikats-Logik
  if (ldapConfig.customCaCert != null) {
    await prefs.setString('ldap_custom_ca', ldapConfig.customCaCert!);
  } else {
    await prefs.remove('ldap_custom_ca');
  }
  
  // Die alten "if (savePassword)" Blöcke haben wir komplett entfernt,
  // da wir das Passwort grundsätzlich nicht mehr persistent speichern.
}

  Future<bool> login(LdapConfig ldapConfig, {bool savePassword = false}) async {
    _errorMessage = null;
    notifyListeners();

    final service = ADService();
    try {
      // Versuch der Verbindung zum AD
      final success = await service.connect(ldapConfig);
      
      if (success) {
        _adService = service;
        config = ldapConfig;
        
        // Bei Erfolg speichern wir die Konfiguration persistent
        await _saveConfig(ldapConfig, savePassword: savePassword);
        
        notifyListeners();
        return true;
      }
      
      _errorMessage = 'Verbindung fehlgeschlagen. Bitte prüfen Sie Server, Port und Logindaten.';
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _adService?.disconnect();
    _adService = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}