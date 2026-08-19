import 'package:flutter/material.dart';
import '../core/services/secure_storage_service.dart';
import '../core/utils/password_generator.dart';
import '../models/vault_item.dart';

/// State management provider for in-memory vault items, search queries,
/// category filters, favorites, security audit scoring, and backup operations.
class VaultProvider extends ChangeNotifier {
  final SecureStorageService _storageService;

  List<VaultItem> _items = [];
  bool _isLoading = false;
  String _searchQuery = '';
  VaultCategory? _selectedCategory;
  bool _favoritesOnly = false;

  /// Creates a [VaultProvider] instance with optional storage injection.
  VaultProvider({SecureStorageService? storageService})
      : _storageService = storageService ?? SecureStorageService();

  /// All decrypted vault items currently loaded in memory.
  List<VaultItem> get items => _items;

  /// Whether vault items are currently being loaded from secure storage.
  bool get isLoading => _isLoading;

  /// Current search keyword filter.
  String get searchQuery => _searchQuery;

  /// Currently selected category filter, or null if showing all categories.
  VaultCategory? get selectedCategory => _selectedCategory;

  /// Whether the items list is restricted to pinned favorite items only.
  bool get favoritesOnly => _favoritesOnly;

  /// Returns items filtered by category, favorites toggle, and search keyword.
  List<VaultItem> get filteredItems {
    return _items.where((item) {
      // Apply category filter if active
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }

      // Apply favorites-only filter if active
      if (_favoritesOnly && !item.isFavorite) {
        return false;
      }

      // Apply search query across title, username, URL, notes, and card holder
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

  // ===========================================================================
  // SECURITY AUDIT & HEALTH METRICS
  // ===========================================================================

  /// Returns all items whose stored passwords evaluate to weak or very weak strength.
  List<VaultItem> get weakItems {
    return _items.where((item) {
      if (item.password == null || item.password!.isEmpty) return false;
      final strength = PasswordGenerator.evaluateStrength(item.password!);
      return strength == PasswordStrength.veryWeak || strength == PasswordStrength.weak;
    }).toList();
  }

  /// Groups items by shared plaintext password to detect password reuse vulnerabilities.
  Map<String, List<VaultItem>> get reusedPasswordsMap {
    final Map<String, List<VaultItem>> map = {};
    for (final item in _items) {
      if (item.password != null && item.password!.isNotEmpty) {
        map.putIfAbsent(item.password!, () => []).add(item);
      }
    }
    // Retain only passwords that appear in more than one vault item
    map.removeWhere((_, list) => list.length <= 1);
    return map;
  }

  /// Calculates an overall security score from 0 to 100 based on individual
  /// password strengths and reuse penalties across the entire vault.
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

      // Apply a 40% penalty if the password is reused across accounts
      if (reusedMap.containsKey(item.password)) {
        itemScore = (itemScore * 0.6).toInt();
      }

      totalScore += itemScore;
    }

    return (totalScore / passwordItems.length).round();
  }

  // ===========================================================================
  // VAULT MUTATIONS & DISPATCH
  // ===========================================================================

  /// Asynchronously reloads all vault items from secure storage into memory.
  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    _items = await _storageService.getAllVaultItems();
    _isLoading = false;
    notifyListeners();
  }

  /// Persists a new [item] to secure storage and refreshes the in-memory list.
  Future<void> addItem(VaultItem item) async {
    await _storageService.saveVaultItem(item);
    await loadItems();
  }

  /// Updates an existing [item] in secure storage and refreshes the in-memory list.
  Future<void> updateItem(VaultItem item) async {
    await _storageService.saveVaultItem(item);
    await loadItems();
  }

  /// Deletes an item by [id] from secure storage and updates the in-memory list.
  Future<void> deleteItem(String id) async {
    await _storageService.deleteVaultItem(id);
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  /// Toggles the favorite status of the item identified by [id].
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

  /// Sets the active text search query.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Filters items by the specified category (or null to show all).
  void setCategory(VaultCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Toggles the favorites-only filter mode.
  void toggleFavoritesOnly() {
    _favoritesOnly = !_favoritesOnly;
    notifyListeners();
  }

  /// Exports all vault items into a password-protected JSON backup string.
  Future<String> exportBackup(String password) async {
    return await _storageService.exportEncryptedBackup(password);
  }

  /// Imports and restores items from an encrypted backup envelope using [password].
  Future<int> importBackup(String backupJson, String password) async {
    final count = await _storageService.importEncryptedBackup(backupJson, password);
    await loadItems();
    return count;
  }

  /// Completely wipes all data from secure storage and clears in-memory items.
  Future<void> wipeAllData() async {
    await _storageService.clearAllData();
    _items.clear();
    notifyListeners();
  }
}
