import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../data/database/database_helper.dart';
import '../data/models/card_model.dart';
import '../data/services/api_service.dart';

/// Controller for card operations
/// Handles CRUD, camera capture, Base64 encoding, and price fetching
class CardController extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final ApiService _api = ApiService();

  List<CardModel> _rareCards = [];
  List<CardModel> _expensiveCards = [];
  CardModel? _currentCard;
  bool _isLoading = false;
  String? _error;
  String? _capturedImageBase64;
  double _totalCollectionValue = 0.0;

  // Getters
  List<CardModel> get rareCards => _rareCards;
  List<CardModel> get expensiveCards => _expensiveCards;
  CardModel? get currentCard => _currentCard;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get capturedImageBase64 => _capturedImageBase64;
  double get totalCollectionValue => _totalCollectionValue;

  /// Load rare and expensive cards (top 20 each for preview)
  Future<void> loadRareAndExpensive() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final allRare = await _db.getRareCards();
      // Limit to top 20 for display
      _rareCards = allRare.take(20).toList();
      _expensiveCards = await _db.getExpensiveCards(limit: 20);
      _totalCollectionValue = await _db.getTotalCollectionValue();
    } catch (e) {
      _error = 'Failed to load cards: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load ALL rare cards (for "See All" page)
  Future<void> loadAllRareCards() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rareCards = await _db.getRareCards();
    } catch (e) {
      _error = 'Failed to load rare cards: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load ALL expensive cards sorted by price (for "See All" page)
  Future<void> loadAllExpensiveCards() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get all priced cards without limit
      _expensiveCards = await _db.getExpensiveCards(limit: 1000);
    } catch (e) {
      _error = 'Failed to load expensive cards: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get card by code (from DB or API)
  Future<CardModel?> getCard(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try local first
      _currentCard = await _db.getCardByCode(code);

      // If not found, try API
      if (_currentCard == null) {
        _currentCard = await _api.getCardByCode(code);
      }

      return _currentCard;
    } catch (e) {
      _error = 'Failed to get card: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add card to collection
  Future<bool> addCard(CardModel card) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if card already exists
      final existing = await _db.getCardByCode(card.code);
      if (existing != null) {
        _error = 'Card ${card.code} already in collection';
        return false;
      }

      await _db.insertCard(card);

      // Update set completion
      await _db.updateSetCompletion(card.setCode);

      return true;
    } catch (e) {
      _error = 'Failed to add card: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add card by code
  Future<bool> addCardByCode(String code) async {
    // Validate code format (e.g., OP01-001)
    if (!_validateCardCode(code)) {
      _error = 'Invalid card code format. Expected: OP01-001';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch card info from API
      CardModel? card = await _api.getCardByCode(code);

      if (card == null) {
        // Create basic card if API fails
        card = CardModel(
          code: code,
          name: 'Card $code',
        );
      }

      // Add captured image if available
      if (_capturedImageBase64 != null) {
        card = card.copyWith(imageBase64: _capturedImageBase64);
      }

      return await addCard(card);
    } catch (e) {
      _error = 'Failed to add card: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update card
  Future<bool> updateCard(CardModel card) async {
    try {
      await _db.updateCard(card);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update card: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete card
  Future<bool> deleteCard(int id) async {
    try {
      await _db.deleteCard(id);
      await loadRareAndExpensive();
      return true;
    } catch (e) {
      _error = 'Failed to delete card: $e';
      notifyListeners();
      return false;
    }
  }

  /// Fetch and update card price
  Future<void> updateCardPrice(CardModel card) async {
    try {
      final price = await _api.getCardPrice(card.code);
      if (price != null && card.id != null) {
        final updated = card.copyWith(price: price);
        await _db.updateCard(updated);
        await loadRareAndExpensive();
      }
    } catch (e) {
      // Price update is optional, don't show error
    }
  }

  /// Update prices for all expensive cards
  Future<void> refreshPrices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final cards = await _db.getAllCards();
      for (final card in cards) {
        await updateCardPrice(card);
      }
    } finally {
      _isLoading = false;
      await loadRareAndExpensive();
    }
  }

  /// Set captured image from camera
  void setCapturedImage(Uint8List imageBytes) {
    _capturedImageBase64 = base64Encode(imageBytes);
    notifyListeners();
  }

  /// Clear captured image
  void clearCapturedImage() {
    _capturedImageBase64 = null;
    notifyListeners();
  }

  /// Identify card from captured image
  Future<CardModel?> identifyFromImage() async {
    if (_capturedImageBase64 == null) {
      _error = 'No image captured';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final card = await _api.identifyCardFromImage(_capturedImageBase64!);
      _currentCard = card;
      return card;
    } catch (e) {
      _error = 'Failed to identify card: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validate card code format (e.g., OP01-001, ST01-001)
  bool _validateCardCode(String code) {
    final pattern = RegExp(r'^[A-Z]{2,3}\d{2}-\d{3}[a-zA-Z]?$');
    return pattern.hasMatch(code.toUpperCase());
  }

  /// Search cards
  Future<List<CardModel>> searchCards(String query) async {
    try {
      return await _db.searchCards(query);
    } catch (e) {
      _error = 'Search failed: $e';
      notifyListeners();
      return [];
    }
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
