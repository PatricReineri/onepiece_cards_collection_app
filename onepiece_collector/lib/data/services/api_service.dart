import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';
import '../models/set_model.dart';

/// API service for One Piece TCG Card API
/// Base endpoint: https://www.optcgapi.com/api
/// 
/// Available endpoints:
/// - GET /allSets/ - Get all sets
/// - GET /sets/{set-id}/ - Get all cards in a set
/// - GET /sets/card/{card_set_id}/ - Get a specific card by ID
/// - GET /sets/card/twoweeks/{card_set_id}/ - Get card with 2-week pricing data
class ApiService {
  static const String _baseUrl = 'https://www.optcgapi.com/api';
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch all available sets
  /// Endpoint: GET /allSets/
  Future<List<SetModel>> getAllSets() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/allSets/'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => SetModel.fromJson(item)).toList();
      } else {
        throw ApiException('Failed to fetch sets: ${response.statusCode}');
      }
    } on TimeoutException {
      throw ApiException('Request timeout while fetching sets');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Fetch all cards from a specific set
  /// Endpoint: GET /sets/{set-id}/
  /// Example: /sets/OP-01/
  Future<List<CardModel>> getCardsBySet(String setId) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/sets/$setId/'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => CardModel.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw ApiException('Failed to fetch set cards: ${response.statusCode}');
      }
    } on TimeoutException {
      throw ApiException('Request timeout while fetching set');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Fetch card information by card_set_id
  /// Endpoint: GET /sets/card/{card_set_id}/
  /// Example: /sets/card/OP01-001/
  /// Note: Can return multiple cards (regular + variants/parallels)
  Future<List<CardModel>> getCardById(String cardSetId) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/sets/card/$cardSetId/'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => CardModel.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw ApiException('Failed to fetch card: ${response.statusCode}');
      }
    } on TimeoutException {
      throw ApiException('Request timeout while fetching card');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Fetch single card (first match) by card_set_id
  /// Convenience method that returns the first card or null
  Future<CardModel?> getCardByCode(String code) async {
    try {
      final cards = await getCardById(code);
      return cards.isNotEmpty ? cards.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch card with 2-week pricing data
  /// Endpoint: GET /sets/card/twoweeks/{card_set_id}/
  /// Example: /sets/card/twoweeks/OP01-001/
  Future<List<CardModel>> getCardWithPricingHistory(String cardSetId) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/sets/card/twoweeks/$cardSetId/'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => CardModel.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw ApiException('Failed to fetch card pricing: ${response.statusCode}');
      }
    } on TimeoutException {
      throw ApiException('Request timeout while fetching card pricing');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Fetch card price (market_price)
  /// Returns the market_price for the specified card
  Future<double?> getCardPrice(String cardSetId) async {
    try {
      final cards = await getCardById(cardSetId);
      if (cards.isNotEmpty) {
        return cards.first.price;
      }
      return null;
    } catch (e) {
      // Price fetch is optional, fail silently
      return null;
    }
  }

  /// Search cards by querying all cards in a set and filtering
  /// Note: The API doesn't have a search endpoint, so we fetch all cards and filter
  Future<List<CardModel>> searchCards(String query, {String? setId}) async {
    try {
      if (setId != null) {
        // Search within a specific set
        final allCards = await getCardsBySet(setId);
        final lowerQuery = query.toLowerCase();
        return allCards.where((card) {
          return card.name.toLowerCase().contains(lowerQuery) ||
                 card.code.toLowerCase().contains(lowerQuery);
        }).toList();
      } else {
        // If no set specified, try to extract set from query (e.g., "OP01-xxx")
        final match = RegExp(r'(OP-?\d+)').firstMatch(query.toUpperCase());
        if (match != null) {
          String extractedSetId = match.group(1)!;
          // Ensure proper format OP-01 (with hyphen)
          if (!extractedSetId.contains('-')) {
            extractedSetId = '${extractedSetId.substring(0, 2)}-${extractedSetId.substring(2)}';
          }
          final allCards = await getCardsBySet(extractedSetId);
          final lowerQuery = query.toLowerCase();
          return allCards.where((card) {
             return card.name.toLowerCase().contains(lowerQuery) ||
                    card.code.toLowerCase().contains(lowerQuery);
          }).toList();
        }
        
        // Fallback: Global search (iteraties over all sets)
        return await searchGlobal(query);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Search failed: $e');
    }
  }

  /// Global search across ALL sets
  /// WARNING: This is resource intensive as it fetches cards from all sets
  Future<List<CardModel>> searchGlobal(String query) async {
    try {
      final sets = await getAllSets();
      final List<Future<List<CardModel>>> futures = [];
      final lowerQuery = query.toLowerCase();

      // Optimize: Limit concurrent requests or just fire all (it's about 20-30 sets)
      // For now, fire all but handle errors gracefully
      for (final set in sets) {
        futures.add(getCardsBySet(set.code).catchError((_) => <CardModel>[]));
      }

      final results = await Future.wait(futures);
      final List<CardModel> matches = [];

      for (final setCards in results) {
        matches.addAll(setCards.where((card) {
          return card.name.toLowerCase().contains(lowerQuery) ||
                 card.code.toLowerCase().contains(lowerQuery);
        }));
      }

      // Sort by code ??
      return matches;
    } catch (e) {
      throw ApiException('Global search failed: $e');
    }
  }

  /// Get all rare cards from a set
  Future<List<CardModel>> getRareCardsBySet(String setId) async {
    try {
      final cards = await getCardsBySet(setId);
      return cards.where((card) => card.isRare).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch rare cards: $e');
    }
  }

  /// Get expensive cards from a set (sorted by price descending)
  Future<List<CardModel>> getExpensiveCardsBySet(String setId, {int limit = 10}) async {
    try {
      final cards = await getCardsBySet(setId);
      final cardsWithPrice = cards.where((card) => card.price != null && card.price! > 0).toList();
      cardsWithPrice.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
      return cardsWithPrice.take(limit).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch expensive cards: $e');
    }
  }

  /// Get all rare and expensive cards across all sets
  /// This fetches cards from multiple sets - use with caution (rate limiting)
  Future<List<CardModel>> getAllRareAndExpensiveCards({
    List<String>? setIds,
    int expensiveLimit = 20,
    double priceThreshold = 10.0,
  }) async {
    final List<CardModel> rareCards = [];
    final List<CardModel> expensiveCards = [];
    
    // If no sets provided, fetch the set list first
    final sets = setIds ?? (await getAllSets()).map((s) => s.code).toList();
    
    // Limit to first 5 sets to avoid too many requests
    final setsToFetch = sets.take(5).toList();
    
    for (final setId in setsToFetch) {
      try {
        final cards = await getCardsBySet(setId);
        
        // Collect rare cards
        rareCards.addAll(cards.where((card) => card.isRare));
        
        // Collect expensive cards
        expensiveCards.addAll(cards.where((card) => 
          card.price != null && card.price! >= priceThreshold
        ));
      } catch (e) {
        // Continue with other sets if one fails
        continue;
      }
    }
    
    // Sort expensive cards by price
    expensiveCards.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
    
    // Combine unique cards
    final allCards = <String, CardModel>{};
    for (final card in rareCards) {
      allCards[card.code] = card;
    }
    for (final card in expensiveCards.take(expensiveLimit)) {
      allCards[card.code] = card;
    }
    
    return allCards.values.toList();
  }

  /// Identify card from image (dummy endpoint for camera scan)
  /// Note: This API doesn't support image identification
  /// This is a placeholder for future implementation
  Future<CardModel?> identifyCardFromImage(String base64Image) async {
    // The optcgapi.com doesn't have an image identification endpoint
    // This would require a different service (e.g., custom ML model)
    return null;
  }

  /// Download image from URL and return as base64 string
  /// Used to cache card images for offline viewing
  Future<String?> downloadImageAsBase64(String imageUrl) async {
    try {
      final response = await _client
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
      return null;
    } catch (e) {
      // Image download failed, return null
      return null;
    }
  }

  /// Dispose client
  void dispose() {
    _client.close();
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
