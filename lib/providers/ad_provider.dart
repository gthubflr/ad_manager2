import 'package:flutter/foundation.dart';
import '../models/ad_user.dart';
import '../services/ad_service.dart';

class ADProvider with ChangeNotifier {
  ADService? _adService;
  List<ADUser> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<ADUser> get users => _searchQuery.isEmpty
      ? _users
      : _users.where((u) => 
          u.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setADService(ADService? service) {
    _adService = service;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Alias für getUsers(), damit es zum Schema der anderen Provider passt
  Future<void> loadUsers() async {
    if (_adService == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _users = await _adService!.getUsers();
    } catch (e) {
      _errorMessage = 'Fehler beim Laden der Benutzer: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kompatibilitäts-Methode falls du irgendwo getUsers() direkt aufrufst
  Future<void> getUsers() => loadUsers();

  Future<bool> resetPassword(String username, String newPassword) async {
    if (_adService == null) return false;
    try {
      final success = await _adService!.resetPassword(username, newPassword);
      if (!success) {
        _errorMessage = 'Kennwort konnte nicht gesetzt werden.';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> lockUser(String username) async {
    if (_adService == null) return false;
    try {
      final success = await _adService!.lockUser(username);
      if (success) _updateLocalUser(username, (u) => u.copyWith(isLocked: true));
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> unlockUser(String username) async {
    if (_adService == null) return false;
    try {
      final success = await _adService!.unlockUser(username);
      if (success) _updateLocalUser(username, (u) => u.copyWith(isLocked: false));
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> enableUser(String username) async {
    if (_adService == null) return false;
    try {
      final success = await _adService!.enableUser(username);
      if (success) _updateLocalUser(username, (u) => u.copyWith(isEnabled: true));
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> disableUser(String username) async {
    if (_adService == null) return false;
    try {
      final success = await _adService!.disableUser(username);
      if (success) _updateLocalUser(username, (u) => u.copyWith(isEnabled: false));
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _updateLocalUser(String username, ADUser Function(ADUser) updateFn) {
    final index = _users.indexWhere((u) => u.username == username);
    if (index != -1) {
      _users[index] = updateFn(_users[index]);
      notifyListeners();
    }
  }
}