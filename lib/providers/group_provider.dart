import 'package:flutter/foundation.dart';
import '../models/ad_group.dart';
import '../services/ad_service.dart';

class GroupProvider with ChangeNotifier {
  ADService? _adService;
  List<ADGroup> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Getter für die (gefilterte) Gruppenliste - JETZT SICHER
  List<ADGroup> get groups {
    if (_searchQuery.isEmpty) return _groups;
    
    final query = _searchQuery.toLowerCase();
    return _groups.where((g) {
      // Sicherer Check: Wir nutzen den null-aware Zugriff und Fallback
      final name = (g.name).toLowerCase();
      // Hier nutzen wir ?. und ?? '', falls g.displayName aus irgendeinem Grund null/unzugänglich ist
      final dName = (g.displayName).toLowerCase();
      final desc = (g.description).toLowerCase();
      
      final matchesInfo = name.contains(query) || 
                          dName.contains(query) || 
                          desc.contains(query);
      
      final matchesMembers = g.members.any((m) => m.toLowerCase().contains(query));
      
      return matchesInfo || matchesMembers;
    }).toList();
  }
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setADService(ADService? service) {
    _adService = service;
    // Automatisch Gruppen laden, wenn Service gesetzt wird
    if (_adService != null && _groups.isEmpty) {
      loadGroups();
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

  ADGroup? getGroupByDN(String dn) {
    try {
      return _groups.firstWhere((g) => g.distinguishedName == dn);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadGroups() async {
    if (_adService == null) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _groups = await _adService!.getGroups();
    } catch (e) {
      _errorMessage = 'Fehler beim Laden der Gruppen: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addUserToGroup(String userDN, String groupDN) async {
    if (_adService == null) return false;
    try {
      final success = await _adService!.addUserToGroup(userDN, groupDN);
      if (success) await loadGroups();
      return success;
    } catch (e) {
      _errorMessage = 'Fehler beim Hinzufügen: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeUserFromGroup(String userDN, String groupDN) async {
    if (_adService == null) return false;
    try {
      final success = await _adService!.removeUserFromGroup(userDN, groupDN);
      if (success) await loadGroups();
      return success;
    } catch (e) {
      _errorMessage = 'Fehler beim Entfernen: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addGroupToGroup(String memberGroupDN, String parentGroupDN) async {
    return addUserToGroup(memberGroupDN, parentGroupDN);
  }

  Future<bool> removeGroupFromGroup(String memberGroupDN, String parentGroupDN) async {
    return removeUserFromGroup(memberGroupDN, parentGroupDN);
  }
}