import 'package:flutter/foundation.dart';
import '../data/database/database_helper.dart';
import '../data/models/card_model.dart';
import '../data/models/set_model.dart';
import '../data/services/api_service.dart';

/// Controller for set detail page
/// Handles card pagination (3x3 grid), filtering, and set information
/// Shows ALL cards in the set from API, highlighting collected vs missing
class SetController extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final ApiService _api = ApiService();

  SetModel? _currentSet;
  List<CardModel> _allSetCards = [];       // All cards in set from API
  Set<String> _collectedCardUniqueIds = {}; // UniqueIds (code_rarity) of cards in user's collection
  List<CardModel> _filteredCards = [];     // Filtered cards for display
  int _currentPage = 0;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Pagination config
  static const int cardsPerPage = 9; // 3x3 grid

  // Getters
  SetModel? get currentSet => _currentSet;
  List<CardModel> get allCards => _filteredCards;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  /// Total pages based on all cards in set
  int get totalPages => (_filteredCards.length / cardsPerPage).ceil();

  /// Get cards for current page with collected status
  /// Returns a list of CardSlot objects indicating if card is collected
  /// Uses uniqueId (code+rarity) to properly track variant cards
  List<CardSlot> get currentPageCards {
    final startIndex = _currentPage * cardsPerPage;
    final endIndex = startIndex + cardsPerPage;

    // Create list of 9 slots
    List<CardSlot> pageCards = [];

    for (int i = startIndex; i < endIndex; i++) {
      if (i < _filteredCards.length) {
        final card = _filteredCards[i];
        // Use uniqueId (code_rarity) to check collection status
        final isCollected = _collectedCardUniqueIds.contains(card.uniqueId);
        pageCards.add(CardSlot(card: card, isCollected: isCollected));
      } else {
        // Empty slot (beyond set size)
        pageCards.add(CardSlot(card: null, isCollected: false));
      }
    }

    return pageCards;
  }

  /// Load set and ALL its cards from API
  Future<void> loadSet(String setCode) async {
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _searchQuery = '';
    notifyListeners();

    try {
      // Get set info from local DB
      _currentSet = await _db.getSetByCode(setCode);

      // Get all cards in this set from API
      _allSetCards = await _api.getCardsBySet(setCode);
      
      // Sort cards by code in ascending order
      _allSetCards.sort((a, b) => a.code.compareTo(b.code));

      // Get collected card uniqueIds (code+rarity) from local DB
      _collectedCardUniqueIds = await _db.getCollectedCardUniqueIds(setCode);

      // Update filtered cards
      _filteredCards = List.from(_allSetCards);
      // Update set's total cards count
      if (_allSetCards.isNotEmpty) {
        await _db.updateSetTotalCards(setCode, _allSetCards.length);
      }
    } catch (e) {
      _error = 'Failed to load set: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh collected cards status
  Future<void> refreshCollectedStatus() async {
    if (_currentSet == null) return;
    
    _collectedCardUniqueIds = await _db.getCollectedCardUniqueIds(_currentSet!.code);
    notifyListeners();
  }

  /// Check if a card is collected (by uniqueId)
  bool isCardCollected(CardModel card) {
    return _collectedCardUniqueIds.contains(card.uniqueId);
  }

  /// Go to next page
  void nextPage() {
    if (_currentPage < totalPages - 1) {
      _currentPage++;
      notifyListeners();
    }
  }

  /// Go to previous page
  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  /// Go to specific page
  void goToPage(int page) {
    if (page >= 0 && page < totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  /// Filter cards by name or code
  void search(String query) {
    _searchQuery = query;
    _currentPage = 0;

    if (query.isEmpty) {
      _filteredCards = List.from(_allSetCards);
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredCards = _allSetCards.where((card) {
        return card.name.toLowerCase().contains(lowerQuery) ||
            card.code.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    search('');
  }

  /// Add card to collection
  Future<bool> addCard(CardModel card) async {
    try {
      await _db.insertCard(card);
      _collectedCardUniqueIds.add(card.uniqueId);
      
      // Update set completion
      if (_currentSet != null) {
        await _db.updateSetCompletion(_currentSet!.code);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add card: $e';
      notifyListeners();
      return false;
    }
  }

  /// Add multiple cards to collection (batch)
  Future<int> addCards(List<CardModel> cards) async {
    int addedCount = 0;
    try {
      for (final card in cards) {
        if (!isCardCollected(card)) {
          await _db.insertCard(card);
          _collectedCardUniqueIds.add(card.uniqueId);
          addedCount++;
        }
      }
      
      // Update set completion
      if (_currentSet != null) {
        await _db.updateSetCompletion(_currentSet!.code);
      }
      
      notifyListeners();
      return addedCount;
    } catch (e) {
      _error = 'Failed to add cards: $e';
      notifyListeners();
      return addedCount;
    }
  }

  /// Remove card from collection
  Future<void> removeCard(CardModel card) async {
    try {
      // Find the card in DB by name and code (uniqueId)
      await _db.deleteCardByNameAndCode(card.name, card.code);
      _collectedCardUniqueIds.remove(card.uniqueId);
      
      // Update set completion
      if (_currentSet != null) {
        await _db.updateSetCompletion(_currentSet!.code);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove card: $e';
      notifyListeners();
    }
  }

  /// Get set completion percentage
  double get completionPercentage {
    if (_allSetCards.isEmpty) return 0;
    return (_collectedCardUniqueIds.length / _allSetCards.length) * 100;
  }

  /// Get collected cards count
  int get collectedCount => _collectedCardUniqueIds.length;

  /// Get total cards count
  int get totalCardsCount => _allSetCards.length;

  /// Get all cards in the set (for bulk operations)
  List<CardModel> get allSetCards => _allSetCards;

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

/// Represents a card slot in the grid
/// Contains the card data and whether it's in the user's collection
class CardSlot {
  final CardModel? card;
  final bool isCollected;

  CardSlot({this.card, required this.isCollected});
}
