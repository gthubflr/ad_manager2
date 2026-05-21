import 'package:flutter/foundation.dart';
import '../models/ad_computer.dart';
import '../models/bitlocker_info.dart';
import '../services/ad_service.dart';

class ComputerProvider with ChangeNotifier {
  ADService? _adService;
  List<ADComputer> _computers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  // BitLocker: Cache pro Computer-DN
  final Map<String, List<BitLockerInfo>> _bitLockerCache = {};
  final Map<String, bool> _bitLockerLoading = {};
  final Map<String, String?> _bitLockerErrors = {};

  List<ADComputer> get computers {
    if (_searchQuery.isEmpty) return _computers;
    
    final query = _searchQuery.toLowerCase();
    return _computers.where((c) {
      final nameMatch = c.name.toLowerCase().contains(query);
      final dnsMatch = (c.dnsHostName ?? '').toLowerCase().contains(query);
      final osMatch = (c.operatingSystem ?? '').toLowerCase().contains(query);
      final ouMatch = (c.organizationalUnit ?? '').toLowerCase().contains(query);
      
      return nameMatch || dnsMatch || osMatch || ouMatch;
    }).toList();
  }
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setADService(ADService? service) {
    _adService = service;
    if (_adService != null && _computers.isEmpty) {
      loadComputers();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadComputers() async {
    if (_adService == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _computers = await _adService!.getComputers();
    } catch (e) {
      _errorMessage = 'Fehler beim Laden der Computer: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== BITLOCKER ====================

  /// Gibt gecachte BitLocker-Einträge für einen Computer zurück.
  /// Liefert eine leere Liste, solange noch nicht geladen wurde.
  List<BitLockerInfo> getBitLockerInfoFor(String computerDN) =>
      _bitLockerCache[computerDN] ?? [];

  /// True, solange die BitLocker-Daten für diesen Computer geladen werden.
  bool isBitLockerLoading(String computerDN) =>
      _bitLockerLoading[computerDN] ?? false;

  /// Fehlermeldung beim Laden der BitLocker-Daten, oder null.
  String? getBitLockerError(String computerDN) =>
      _bitLockerErrors[computerDN];

  /// Lädt die BitLocker-Recovery-Einträge für den angegebenen Computer-DN
  /// aus dem AD und speichert sie im Cache.
  /// Wird ein zweites Mal aufgerufen, wird der Cache geleert und neu befüllt
  /// (ermöglicht manuelles Aktualisieren).
  Future<void> loadBitLockerInfo(String computerDN, {bool forceRefresh = false}) async {
    if (_adService == null) return;

    // Bereits geladen und kein Refresh gewünscht → nichts tun
    if (!forceRefresh &&
        _bitLockerCache.containsKey(computerDN) &&
        !(_bitLockerLoading[computerDN] ?? false)) {
      return;
    }

    _bitLockerLoading[computerDN] = true;
    _bitLockerErrors[computerDN] = null;
    notifyListeners();

    try {
      final infos = await _adService!.getBitLockerInfo(computerDN);
      _bitLockerCache[computerDN] = infos;
    } catch (e) {
      _bitLockerErrors[computerDN] = 'Fehler beim Laden der BitLocker-Daten: $e';
      _bitLockerCache[computerDN] = [];
    } finally {
      _bitLockerLoading[computerDN] = false;
      notifyListeners();
    }
  }

  /// Löscht den BitLocker-Cache für alle Computer (z.B. nach Logout).
  void clearBitLockerCache() {
    _bitLockerCache.clear();
    _bitLockerLoading.clear();
    _bitLockerErrors.clear();
    notifyListeners();
  }
}
