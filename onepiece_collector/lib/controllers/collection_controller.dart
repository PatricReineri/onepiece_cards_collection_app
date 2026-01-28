import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/database/database_helper.dart';
import '../data/models/card_model.dart';
import '../data/models/set_model.dart';
import '../data/services/api_service.dart';

/// Controller for managing the card collection
/// Handles sets list, import/export, and collection statistics
class CollectionController extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final ApiService _api = ApiService();

  List<SetModel> _sets = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<SetModel> get sets => _sets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static bool _isFirstLaunch = true;

  /// Initialize controller and load data
  /// Auto-syncs from API on first launch, otherwise loads from DB
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_isFirstLaunch) {
        _isFirstLaunch = false;
        // First launch: sync from API to get latest sets
        try {
          // Try to sync, but if it fails (offline), fall back to DB
          await syncSetsFromApi();
        } catch (e) {
          _error = 'Network unavailable, loading offline data';
          await loadSets();
        }
      } else {
        // Subsequent navigations: load from local DB
        await loadSets();
      }
    } catch (e) {
      _error = 'Failed to load sets: $e';
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Load all sets from database
  Future<void> loadSets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sets = await _db.getAllSets();
      
      // Update completion counts for each set
      await _updateSetCardCounts();
    } catch (e) {
      _error = 'Failed to load sets: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update card counts (collected/total) for all sets
  Future<void> _updateSetCardCounts() async {
    List<SetModel> updatedSets = [];
    
    for (int i = 0; i < _sets.length; i++) {
      final set = _sets[i];
      
      // Update collected cards count from local DB
      await _db.updateSetCompletion(set.code);
      
      // If total cards is not set, try to fetch from API
      if (set.totalCards == null || set.totalCards == 0) {
        try {
          final apiCards = await _api.getCardsBySet(set.code);
          if (apiCards.isNotEmpty) {
            await _db.updateSetTotalCards(set.code, apiCards.length);
          }
        } catch (e) {
          // Ignore API errors for individual sets
        }
      }
    }
    
    // Reload sets with updated counts
    _sets = await _db.getAllSets();
    
    // Calculate completion status for each set
    for (int i = 0; i < _sets.length; i++) {
      final set = _sets[i];
      
      // Estimate main set size based on set code type
      // OP sets typically have 121 main cards, ST sets have ~20
      int estimatedMainCards = 121;
      if (set.code.startsWith('ST')) {
        estimatedMainCards = 20;
      } else if (set.code.startsWith('EB')) {
        estimatedMainCards = 80;
      }
      
      try {
        final status = await _db.getSetCompletionStatus(set.code, estimatedMainCards);
        updatedSets.add(set.copyWith(
          isRareComplete: status['isRareComplete'] ?? false,
          isMainSetComplete: status['isMainSetComplete'] ?? false,
          isFullyComplete: status['isFullyComplete'] ?? false,
        ));
      } catch (e) {
        updatedSets.add(set);
      }
    }
    
    _sets = updatedSets;
  }

  /// Fetch sets from API and save to database
  Future<void> syncSetsFromApi() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch all sets from API
      final apiSets = await _api.getAllSets();
      for (final set in apiSets) {
        await _db.insertSet(set);
      }
      
      // Load sets from DB
      _sets = await _db.getAllSets();
      
      // Update card counts for each set
      await _updateSetCardCounts();
    } catch (e) {
      // If sync fails, we still want to show what we have in DB
      _error = 'Network error: showing offline data';
      await loadSets();
      rethrow; // Rethrow to let init know it failed
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new set
  Future<void> addSet(SetModel set) async {
    try {
      await _db.insertSet(set);
      await loadSets();
    } catch (e) {
      _error = 'Failed to add set: $e';
      notifyListeners();
    }
  }

  /// Delete a set
  Future<void> deleteSet(int id) async {
    try {
      await _db.deleteSet(id);
      await loadSets();
    } catch (e) {
      _error = 'Failed to delete set: $e';
      notifyListeners();
    }
  }

  /// Get total collection statistics
  Future<Map<String, dynamic>> getStats() async {
    final allCards = await _db.getAllCards();
    final rareCards = await _db.getRareCards();
    final expensiveCards = await _db.getExpensiveCards(limit: 10);

    double totalValue = 0;
    for (final card in allCards) {
      totalValue += card.price ?? 0;
    }

    return {
      'totalCards': allCards.length,
      'totalSets': _sets.length,
      'rareCards': rareCards.length,
      'totalValue': totalValue,
      'mostExpensive': expensiveCards.isNotEmpty ? expensiveCards.first : null,
    };
  }

  /// Export collection to JSON string
  Future<String> exportCollection() async {
    final data = await _db.exportData();
    return jsonEncode(data);
  }

  /// Import collection from JSON string
  /// Returns the number of cards imported
  Future<int> importCollection(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate schema
      if (!_validateImportSchema(data)) {
        _error = 'Invalid import file format';
        notifyListeners();
        return 0;
      }

      final count = await _db.importData(data);
      await loadSets();
      return count;
    } catch (e) {
      _error = 'Import failed: $e';
      notifyListeners();
      return 0;
    }
  }

  /// Validate import JSON schema
  bool _validateImportSchema(Map<String, dynamic> data) {
    // Check for required fields
    if (!data.containsKey('cards') && !data.containsKey('sets')) {
      return false;
    }

    // Validate cards array
    if (data['cards'] != null && data['cards'] is! List) {
      return false;
    }

    // Validate sets array
    if (data['sets'] != null && data['sets'] is! List) {
      return false;
    }

    return true;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Global search for cards
  Future<List<CardModel>> searchGlobal(String query) async {
    try {
      return await _api.searchCards(query);
    } catch (e) {
      _error = 'Search failed: $e';
      notifyListeners();
      return [];
    }
  }

  /// Check if a card is collected (by name and code)
  Future<bool> isCardCollected(CardModel card) async {
    return await _db.isCardCollected(card.name, card.code);
  }

  /// Get all collected cards grouped by Set
  /// Returns a Map where key is SetModel and value is List of cards in that set
  Future<Map<SetModel, List<CardModel>>> getCheckpointData() async {
    final allCards = await _db.getAllCards();
    final Map<SetModel, List<CardModel>> groupedData = {};

    // Helper map to find set by code quickly
    final Map<String, SetModel> setMap = {for (var s in _sets) s.code: s};

    for (final card in allCards) {
      final setId = card.setId ?? _extractSetCode(card.code);
      
      SetModel? set = setMap[setId];
      // Try finding by fuzzy match if explicit match fails (e.g. OP-01 vs OP01)
      if (set == null) {
         final normalizedId = setId.replaceAll('-', '');
         set = _sets.cast<SetModel?>().firstWhere(
           (s) => s?.code.replaceAll('-', '') == normalizedId,
           orElse: () => null,
         );
      }

      // If set still not found, create a dummy one or skip (or group in "Unknown")
      if (set == null) {
        // Create a placeholder set for grouping
        set = SetModel(
          code: setId,
          name: card.setName ?? 'Unknown Set',
          totalCards: 0, 
        );
        // Add to map for future reference in this loop
        setMap[setId] = set;
      }

      if (!groupedData.containsKey(set)) {
        groupedData[set] = [];
      }
      groupedData[set]!.add(card);
    }
    
    // Sort cards within each set by code
    for (final key in groupedData.keys) {
      groupedData[key]!.sort((a, b) => a.code.compareTo(b.code));
    }

    return groupedData;
  }

  String _extractSetCode(String cardCode) {
    if (cardCode.contains('-')) {
      return cardCode.split('-')[0];
    }
    return 'Unknown';
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
