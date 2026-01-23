import 'package:flutter/foundation.dart';
import '../models/ad_computer.dart';
import '../services/ad_service.dart';

class ComputerProvider with ChangeNotifier {
  ADService? _adService;
  List<ADComputer> _computers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<ADComputer> get computers {
    if (_searchQuery.isEmpty) return _computers;
    
    final query = _searchQuery.toLowerCase();
    return _computers.where((c) {
      // FIX: Suche nur in existierenden Computer-Feldern (KEIN displayName)
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
    // Wenn der Service gesetzt wird, laden wir die Computer automatisch (optional)
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
}