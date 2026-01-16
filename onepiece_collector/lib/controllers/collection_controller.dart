import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/database/database_helper.dart';
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

  /// Initialize controller and load data
  /// Auto-syncs from API if database is empty
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load sets from local database
      _sets = await _db.getAllSets();

      // If no sets in DB, auto-fetch from API
      if (_sets.isEmpty) {
        await syncSetsFromApi();
      } else {
        // Update completion counts for each set
        await _updateSetCardCounts();
      }
    } catch (e) {
      _error = 'Failed to load sets: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
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
      _error = 'Failed to sync sets: $e';
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

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
