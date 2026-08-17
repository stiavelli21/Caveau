import 'package:flutter/material.dart';
import '../core/services/secure_storage_service.dart';
import '../core/utils/password_generator.dart';
import '../models/vault_item.dart';

class VaultProvider extends ChangeNotifier {
  final SecureStorageService _storageService;

  List<VaultItem> _items = [];
  bool _isLoading = false;
  String _searchQuery = '';
  VaultCategory? _selectedCategory;
  bool _favoritesOnly = false;

  VaultProvider({SecureStorageService? storageService})
      : _storageService = storageService ?? SecureStorageService();

  List<VaultItem> get items => _items;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  VaultCategory? get selectedCategory => _selectedCategory;
  bool get favoritesOnly => _favoritesOnly;

  List<VaultItem> get filteredItems {
    return _items.where((item) {
      // Category filter
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      // Favorites filter
      if (_favoritesOnly && !item.isFavorite) {
        return false;
      }
      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchUser = item.username?.toLowerCase().contains(query) ?? false;
        final matchUrl = item.websiteUrl?.toLowerCase().contains(query) ?? false;
        final matchNotes = item.notes?.toLowerCase().contains(query) ?? false;
        final matchHolder = item.cardHolder?.toLowerCase().contains(query) ?? false;
        return matchTitle || matchUser || matchUrl || matchNotes || matchHolder;
      }
      return true;
    }).toList();
  }

  // --- Security Audit Getters ---
  List<VaultItem> get weakItems {
    return _items.where((item) {
      if (item.password == null || item.password!.isEmpty) return false;
      final strength = PasswordGenerator.evaluateStrength(item.password!);
      return strength == PasswordStrength.veryWeak || strength == PasswordStrength.weak;
    }).toList();
  }

  Map<String, List<VaultItem>> get reusedPasswordsMap {
    final Map<String, List<VaultItem>> map = {};
    for (final item in _items) {
      if (item.password != null && item.password!.isNotEmpty) {
        map.putIfAbsent(item.password!, () => []).add(item);
      }
    }
    // Filter only those with count > 1
    map.removeWhere((_, list) => list.length <= 1);
    return map;
  }

  int get securityScore {
    final passwordItems = _items.where((i) => i.password != null && i.password!.isNotEmpty).toList();
    if (passwordItems.isEmpty) return 100;

    int totalScore = 0;
    final reusedMap = reusedPasswordsMap;

    for (final item in passwordItems) {
      int itemScore = 0;
      final strength = PasswordGenerator.evaluateStrength(item.password!);
      switch (strength) {
        case PasswordStrength.veryWeak:
          itemScore = 20;
          break;
        case PasswordStrength.weak:
          itemScore = 40;
          break;
        case PasswordStrength.medium:
          itemScore = 70;
          break;
        case PasswordStrength.strong:
          itemScore = 90;
          break;
        case PasswordStrength.veryStrong:
          itemScore = 100;
          break;
      }

      // Penalty for reused password
      if (reusedMap.containsKey(item.password)) {
        itemScore = (itemScore * 0.6).toInt();
      }

      totalScore += itemScore;
    }

    return (totalScore / passwordItems.length).round();
  }

  // --- Actions ---
  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    _items = await _storageService.getAllVaultItems();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(VaultItem item) async {
    await _storageService.saveVaultItem(item);
    await loadItems();
  }

  Future<void> updateItem(VaultItem item) async {
    await _storageService.saveVaultItem(item);
    await loadItems();
  }

  Future<void> deleteItem(String id) async {
    await _storageService.deleteVaultItem(id);
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      final updated = _items[index].copyWith(isFavorite: !_items[index].isFavorite);
      await _storageService.saveVaultItem(updated);
      _items[index] = updated;
      _items.sort((a, b) {
        if (a.isFavorite != b.isFavorite) {
          return a.isFavorite ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(VaultCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleFavoritesOnly() {
    _favoritesOnly = !_favoritesOnly;
    notifyListeners();
  }

  Future<String> exportBackup(String password) async {
    return await _storageService.exportEncryptedBackup(password);
  }

  Future<int> importBackup(String backupJson, String password) async {
    final count = await _storageService.importEncryptedBackup(backupJson, password);
    await loadItems();
    return count;
  }

  Future<void> wipeAllData() async {
    await _storageService.clearAllData();
    _items.clear();
    notifyListeners();
  }
}
