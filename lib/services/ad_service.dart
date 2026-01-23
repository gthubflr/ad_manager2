import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:dartdap/dartdap.dart';
import '../models/ad_user.dart';
import '../models/ad_group.dart';
import '../models/ad_computer.dart';
import '../models/ldap_config.dart';

class ADService {
  LdapConnection? _connection;
  LdapConfig? _config;
  SecurityContext? _securityContext;
  Timer? _keepAliveTimer;
  DateTime? _lastActivity;

  bool get isConnected => _connection != null;

  Future<SecurityContext> _createSecurityContext(LdapConfig config) async {
    print('[ADService] Erstelle SecurityContext...');
    final context = SecurityContext(withTrustedRoots: false);
    
    bool certLoaded = false;

    // 1. Lade CA-Zertifikat aus Assets
    if (config.caCertAssetPath != null) {
      try {
        final certData = await rootBundle.load(config.caCertAssetPath!);
        final certBytes = certData.buffer.asUint8List();
        context.setTrustedCertificatesBytes(certBytes);
        certLoaded = true;
      } catch (e) {
        print('[ADService] ⚠️ Fehler beim Laden des Asset CA-Zertifikats: $e');
      }
    }

    // 2. Lade benutzerdefiniertes CA-Zertifikat
    if (config.customCaCert != null && config.customCaCert!.isNotEmpty) {
      try {
        String normalizedCert = config.customCaCert!.trim();
        normalizedCert = normalizedCert.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
        normalizedCert = normalizedCert.split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .join('\n');
        
        if (!normalizedCert.endsWith('\n')) {
          normalizedCert += '\n';
        }
        
        final certBytes = utf8.encode(normalizedCert);
        context.setTrustedCertificatesBytes(certBytes);
        certLoaded = true;
        print('[ADService] ✅ Benutzerdefiniertes CA-Zertifikat geladen');
      } catch (e) {
        throw Exception('Fehler beim Laden des CA-Zertifikats: $e');
      }
    }

    if (!certLoaded) {
      return SecurityContext.defaultContext;
    }
    
    return context;
  }

  Future<bool> connect(LdapConfig config) async {
    _config = config;
    await disconnect();

    final host = config.server;
    final port = config.port ?? (config.useSSL ? 636 : 389);
    final ssl = config.useSSL;
    final bindDN = _buildBindDN(config.username, config.domain);

    try {
      if (ssl) {
        _securityContext = await _createSecurityContext(config);
        
        // Zertifikate auch zum DefaultContext hinzufügen
        if (config.caCertAssetPath != null) {
          try {
            final certData = await rootBundle.load(config.caCertAssetPath!);
            SecurityContext.defaultContext.setTrustedCertificatesBytes(certData.buffer.asUint8List());
          } catch (_) {}
        }
        if (config.customCaCert != null && config.customCaCert!.isNotEmpty) {
          try {
            SecurityContext.defaultContext.setTrustedCertificatesBytes(utf8.encode(config.customCaCert!));
          } catch (_) {}
        }
      }

      _connection = LdapConnection(
        host: host,
        port: port,
        ssl: ssl,
        bindDN: bindDN,
        password: config.password,
      );

      await _connection!.open();
      await _connection!.bind();
      
      // Keep-Alive Timer starten
      _startKeepAlive();
      
      return true;
    } catch (e) {
      print('[ADService] ❌ Fehler: $e');
      await disconnect();
      rethrow;
    }
  }

  // NEU: Keep-Alive Mechanismus
  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _lastActivity = DateTime.now();
    
    // Alle 2 Minuten prüfen, ob Verbindung noch aktiv ist
    _keepAliveTimer = Timer.periodic(Duration(minutes: 2), (_) async {
      await _ensureConnection();
    });
  }

  // NEU: Stelle sicher, dass Verbindung noch aktiv ist
  Future<void> _ensureConnection() async {
    if (_connection == null || _config == null) return;
    
    try {
      // Teste Verbindung mit einfacher Search-Query
      final result = await _connection!.search(
        _getBaseDN(),
        Filter.present('objectClass'),
        ['cn'],
      ).timeout(Duration(seconds: 5));
      
      // Stream konsumieren (aber nicht verarbeiten)
      await for (var _ in result.stream.take(1)) {
        break;
      }
      
      _lastActivity = DateTime.now();
      print('[ADService] ✅ Verbindung aktiv');
    } catch (e) {
      print('[ADService] ⚠️ Verbindung verloren, reconnect...');
      await _reconnect();
    }
  }

  // NEU: Automatischer Reconnect
  Future<void> _reconnect() async {
    if (_config == null) return;
    
    try {
      await disconnect();
      await connect(_config!);
      print('[ADService] ✅ Erfolgreich wiederverbunden');
    } catch (e) {
      print('[ADService] ❌ Reconnect fehlgeschlagen: $e');
    }
  }

  // NEU: Wrapper für alle API-Calls mit Auto-Reconnect
  Future<T> _executeWithReconnect<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      _lastActivity = DateTime.now();
      return result;
    } catch (e) {
      // Bei Verbindungsfehler: Reconnect und nochmal versuchen
      if (e.toString().contains('closed') || 
          e.toString().contains('connection') ||
          e.toString().contains('socket')) {
        print('[ADService] 🔄 Verbindungsfehler erkannt, reconnect...');
        await _reconnect();
        
        // Nochmal versuchen
        final result = await operation();
        _lastActivity = DateTime.now();
        return result;
      }
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    
    try {
      if (_connection != null) await _connection!.close();
    } catch (e) {
      print('[ADService] Fehler beim Schließen: $e');
    } finally {
      _connection = null;
      _securityContext = null;
    }
  }

  // ==================== BENUTZER-VERWALTUNG ====================

  Future<List<ADUser>> getUsers({String? searchBase}) async {
    return _executeWithReconnect(() async {
      if (_connection == null) throw Exception('Nicht mit LDAP verbunden');
      
      final baseDN = searchBase ?? _getBaseDN();
      
      final userFilter = Filter.and([
        Filter.equals('objectClass', 'user'),
        Filter.equals('objectCategory', 'person'),
        Filter.present('sAMAccountName'),
      ]);

      final searchResult = await _connection!.search(baseDN, userFilter, [
        '*', 
        'sAMAccountName', 
        'displayName', 
        'mail', 
        'userAccountControl',
        'lockoutTime', 
        'lastLogon', 
        'distinguishedName', 
        'cn',
        'telephoneNumber',
        'memberOf'
      ]);

      final users = <ADUser>[];
      await for (var entry in searchResult.stream) {
        final a = entry.attributes;
        
        final username = _getAttributeValue(a, 'sAMAccountName');
        if (username == null || username.isEmpty) continue; 

        final uac = int.tryParse(_getAttributeValue(a, 'userAccountControl') ?? '0') ?? 0;
        final lockout = int.tryParse(_getAttributeValue(a, 'lockoutTime') ?? '0') ?? 0;

        final attributesMap = <String, dynamic>{};
        a.forEach((key, value) {
          attributesMap[key] = value.values.map((v) => v.toString()).toList();
        });

        users.add(ADUser(
          username: username,
          displayName: _getAttributeValue(a, 'displayName') ?? _getAttributeValue(a, 'cn') ?? username,
          email: _getAttributeValue(a, 'mail') ?? '',
          isEnabled: (uac & 0x02) == 0,
          isLocked: lockout > 0,
          lastLogon: _convertFileTimeToDateTime(_getAttributeValue(a, 'lastLogon') ?? '0'),
          distinguishedName: _getAttributeValue(a, 'distinguishedName') ?? '',
          samAccountName: username,
          mail: _getAttributeValue(a, 'mail'),
          telephoneNumber: _getAttributeValue(a, 'telephoneNumber'),
          attributes: attributesMap,
        ));
      }
      
      users.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      return users;
    });
  }

  Future<bool> lockUser(String username) async => 
    _executeWithReconnect(() => _adModify(username, 'lockoutTime', ['1']));
    
  Future<bool> unlockUser(String username) async => 
    _executeWithReconnect(() => _adModify(username, 'lockoutTime', ['0']));

  Future<bool> enableUser(String username) async {
    return _executeWithReconnect(() async {
      final dn = await _getUserDN(username);
      if (dn == null) return false;
      final uac = await _getUserAccountControl(dn);
      return _adModify(username, 'userAccountControl', [(uac & ~0x02).toString()]);
    });
  }

  Future<bool> disableUser(String username) async {
    return _executeWithReconnect(() async {
      final dn = await _getUserDN(username);
      if (dn == null) return false;
      final uac = await _getUserAccountControl(dn);
      return _adModify(username, 'userAccountControl', [(uac | 0x02).toString()]);
    });
  }

  Future<bool> resetPassword(String username, String newPassword) async {
    return _executeWithReconnect(() async {
      if (_connection == null) return false;
      
      final dn = await _getUserDN(username);
      if (dn == null) return false;
      final quotedPassword = '"$newPassword"';
      final units = <int>[];
      for (var i = 0; i < quotedPassword.length; i++) {
        final code = quotedPassword.codeUnitAt(i);
        units.add(code & 0xFF);
        units.add((code >> 8) & 0xFF);
      }
      await _connection!.modify(dn, [
        Modification.replace('unicodePwd', [String.fromCharCodes(units)])
      ]);
      return true;
    });
  }

  Future<bool> _adModify(String username, String attr, List<String> values) async {
    if (_connection == null) return false;
    final dn = await _getUserDN(username);
    if (dn == null) return false;
    await _connection!.modify(dn, [Modification.replace(attr, values)]);
    return true;
  }

  Future<String?> _getUserDN(String username) async {
    if (_connection == null) return null;
    final result = await _connection!.search(_getBaseDN(), 
      Filter.and([Filter.equals('objectClass', 'user'), Filter.equals('sAMAccountName', username)]), 
      ['distinguishedName']);
    await for (var entry in result.stream) return _getAttributeValue(entry.attributes, 'distinguishedName');
    return null;
  }

  Future<int> _getUserAccountControl(String dn) async {
    if (_connection == null) return 0;
    final result = await _connection!.search(dn, Filter.present('objectClass'), ['userAccountControl']);
    await for (var entry in result.stream) return int.tryParse(_getAttributeValue(entry.attributes, 'userAccountControl') ?? '0') ?? 0;
    return 0;
  }

  String _buildBindDN(String user, String dom) => user.contains('@') ? user : '$user@$dom';
  String _getBaseDN() => _config?.domain.split('.').map((p) => 'DC=$p').join(',') ?? '';
  
  String? _getAttributeValue(Map<String, Attribute> attrs, String name) {
    final attr = attrs[name];
    return (attr != null && attr.values.isNotEmpty) ? attr.values.first.toString() : null;
  }

  String? _convertFileTimeToDateTime(String fileTime) {
    final ft = int.tryParse(fileTime) ?? 0;
    if (ft <= 0) return null;
    return DateTime.utc(1601, 1, 1).add(Duration(microseconds: ft ~/ 10)).toLocal().toIso8601String();
  }

  // ==================== GRUPPEN-VERWALTUNG ====================

  Future<List<ADGroup>> getGroups({String? searchBase}) async {
    return _executeWithReconnect(() async {
      if (_connection == null) throw Exception('Nicht mit LDAP verbunden');
      
      final baseDN = searchBase ?? _getBaseDN();
      final searchResult = await _connection!.search(baseDN, Filter.equals('objectClass', 'group'), [
        '*', 'cn', 'displayName', 'description', 'distinguishedName', 'groupType', 'member'
      ]);

      final groups = <ADGroup>[];
      await for (var entry in searchResult.stream) {
        final a = entry.attributes;
        final name = _getAttributeValue(a, 'cn') ?? _getAttributeValue(a, 'sAMAccountName') ?? '';
        if (name.isEmpty) continue;

        final members = a['member']?.values.map((v) => v.toString()).toList() ?? <String>[];
        final attributes = <String, dynamic>{};
        a.forEach((key, value) {
          attributes[key] = value.values.map((v) => v.toString()).toList();
        });

        groups.add(ADGroup(
          name: name,
          displayName: _getAttributeValue(a, 'displayName') ?? name,
          description: _getAttributeValue(a, 'description') ?? '',
          distinguishedName: _getAttributeValue(a, 'distinguishedName') ?? '',
          groupType: _getAttributeValue(a, 'groupType') ?? '',
          members: members,
          attributes: attributes,
        ));
      }
      groups.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return groups;
    });
  }

  Future<bool> addUserToGroup(String userDN, String groupDN) async {
    return _executeWithReconnect(() async {
      if (_connection == null) return false;
      try {
        await _connection!.modify(groupDN, [Modification.add('member', [userDN])]);
        return true;
      } catch (_) { return false; }
    });
  }

  Future<bool> removeUserFromGroup(String userDN, String groupDN) async {
    return _executeWithReconnect(() async {
      if (_connection == null) return false;
      try {
        await _connection!.modify(groupDN, [Modification.delete('member', [userDN])]);
        return true;
      } catch (_) { return false; }
    });
  }

  // ==================== COMPUTER-VERWALTUNG ====================

  Future<List<ADComputer>> getComputers({String? searchBase}) async {
    return _executeWithReconnect(() async {
      if (_connection == null) throw Exception('Nicht mit LDAP verbunden');
      
      final baseDN = searchBase ?? _getBaseDN();
      final filter = Filter.and([Filter.equals('objectClass', 'computer'), Filter.equals('objectCategory', 'computer')]);
      final searchResult = await _connection!.search(baseDN, filter, [
        '*', 'cn', 'dNSHostName', 'operatingSystem', 'operatingSystemVersion', 'distinguishedName', 'userAccountControl', 'lastLogon'
      ]);

      final List<ADComputer> computers = [];
      await for (var entry in searchResult.stream) {
        final a = entry.attributes;
        final name = _getAttributeValue(a, 'cn') ?? _getAttributeValue(a, 'sAMAccountName') ?? '';
        if (name.isEmpty) continue;

        final uac = int.tryParse(_getAttributeValue(a, 'userAccountControl') ?? '0') ?? 0;
        final attributesMap = <String, dynamic>{};
        a.forEach((key, value) {
          attributesMap[key] = value.values.map((v) => v.toString()).toList();
        });

        computers.add(ADComputer(
          name: name,
          dnsHostName: _getAttributeValue(a, 'dNSHostName'),
          operatingSystem: _getAttributeValue(a, 'operatingSystem') ?? 'Unbekannt',
          operatingSystemVersion: _getAttributeValue(a, 'operatingSystemVersion'),
          distinguishedName: _getAttributeValue(a, 'distinguishedName') ?? entry.dn ?? '',
          organizationalUnit: _extractOUFromDN(_getAttributeValue(a, 'distinguishedName') ?? entry.dn ?? ''),
          isEnabled: (uac & 0x02) == 0,
          lastLogon: _convertFileTimeToDateTime(_getAttributeValue(a, 'lastLogon') ?? '0'),
          attributes: attributesMap,
        ));
      }
      computers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return computers;
    });
  }

  String _extractOUFromDN(String dn) {
    if (dn.isEmpty) return '';
    final parts = dn.split(',');
    final ouParts = parts.where((p) => p.trim().toUpperCase().startsWith('OU=')).toList();
    return ouParts.isNotEmpty ? ouParts.join(',') : 'Root';
  }
}