/// Card model representing a One Piece TCG card
/// Maps to the 'cards' SQLite table
/// API reference: https://www.optcgapi.com/api/sets/{set-id}/
class CardModel {
  final int? id;
  final String code;           // card_set_id from API (e.g., "OP07-015")
  final String name;           // card_name from API
  final String? imageUrl;      // card_image from API
  final String? imageBase64;   // locally stored base64 image
  final String? color;         // card_color from API
  final String? rarity;        // rarity from API (SR, L, C, etc.)
  final double? price;         // market_price from API
  final double? inventoryPrice; // inventory_price from API
  final String? setId;         // set_id from API (e.g., "OP-07")
  final String? setName;       // set_name from API
  final String? cardType;      // card_type from API (Character, Leader, etc.)
  final String? cardText;      // card_text from API
  final String? cardCost;      // card_cost from API
  final String? cardPower;     // card_power from API
  final String? life;          // life from API
  final String? subTypes;      // sub_types from API
  final int? counterAmount;    // counter_amount from API
  final String? attribute;     // attribute from API
  final String? cardImageId;   // card_image_id from API

  CardModel({
    this.id,
    required this.code,
    required this.name,
    this.imageUrl,
    this.imageBase64,
    this.color,
    this.rarity,
    this.price,
    this.inventoryPrice,
    this.setId,
    this.setName,
    this.cardType,
    this.cardText,
    this.cardCost,
    this.cardPower,
    this.life,
    this.subTypes,
    this.counterAmount,
    this.attribute,
    this.cardImageId,
  });

  /// Create CardModel from SQLite map
  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String,
      imageUrl: map['image_url'] as String?,
      imageBase64: map['image_base64'] as String?,
      color: map['color'] as String?,
      rarity: map['rarity'] as String?,
      price: map['price'] as double?,
      inventoryPrice: map['inventory_price'] as double?,
      setId: map['set_id'] as String?,
      setName: map['set_name'] as String?,
      cardType: map['card_type'] as String?,
      cardText: map['card_text'] as String?,
      cardCost: map['card_cost'] as String?,
      cardPower: map['card_power'] as String?,
      life: map['life'] as String?,
      subTypes: map['sub_types'] as String?,
      counterAmount: map['counter_amount'] as int?,
      attribute: map['attribute'] as String?,
      cardImageId: map['card_image_id'] as String?,
    );
  }

  /// Convert CardModel to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'image_url': imageUrl,
      'image_base64': imageBase64,
      'color': color,
      'rarity': rarity,
      'price': price,
      'inventory_price': inventoryPrice,
      'set_id': setId,
      'set_name': setName,
      'card_type': cardType,
      'card_text': cardText,
      'card_cost': cardCost,
      'card_power': cardPower,
      'life': life,
      'sub_types': subTypes,
      'counter_amount': counterAmount,
      'attribute': attribute,
      'card_image_id': cardImageId,
    };
  }

  /// Create CardModel from JSON (API response from optcgapi.com)
  factory CardModel.fromJson(Map<String, dynamic> json) {
    // Parse price, handling both num and string values
    double? parsePrice(dynamic value) {
      if (value == null || value == 'NULL') return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // Parse nullable string (API returns "NULL" for null values)
    String? parseNullableString(dynamic value) {
      if (value == null || value == 'NULL') return null;
      return value.toString();
    }

    return CardModel(
      code: json['card_set_id'] ?? json['code'] ?? '',
      name: json['card_name'] ?? json['name'] ?? '',
      imageUrl: json['card_image'] ?? json['image_url'],
      color: json['card_color'] ?? json['color'],
      rarity: json['rarity'],
      price: parsePrice(json['market_price'] ?? json['price']),
      inventoryPrice: parsePrice(json['inventory_price']),
      setId: json['set_id'],
      setName: json['set_name'],
      cardType: json['card_type'],
      cardText: json['card_text'],
      cardCost: parseNullableString(json['card_cost']),
      cardPower: parseNullableString(json['card_power']),
      life: parseNullableString(json['life']),
      subTypes: json['sub_types'],
      counterAmount: json['counter_amount'] is int ? json['counter_amount'] : null,
      attribute: json['attribute'],
      cardImageId: json['card_image_id'],
    );
  }

  /// Convert CardModel to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'card_set_id': code,
      'card_name': name,
      'card_image': imageUrl,
      'card_color': color,
      'rarity': rarity,
      'market_price': price,
      'inventory_price': inventoryPrice,
      'set_id': setId,
      'set_name': setName,
      'card_type': cardType,
      'card_text': cardText,
      'card_cost': cardCost,
      'card_power': cardPower,
      'life': life,
      'sub_types': subTypes,
      'counter_amount': counterAmount,
      'attribute': attribute,
      'card_image_id': cardImageId,
    };
  }

  /// Extract set code from card code (e.g., OP01-001 -> OP01 -> OP-01)
  String get setCode {
    final parts = code.split('-');
    if (parts.isNotEmpty) {
      // Convert OP01 to OP-01 format if needed
      final rawCode = parts[0];
      if (rawCode.length >= 4 && !rawCode.contains('-')) {
        return '${rawCode.substring(0, 2)}-${rawCode.substring(2)}';
      }
      return rawCode;
    }
    return setId ?? '';
  }

  /// Check if card has a valid image
  bool get hasImage => imageUrl != null || imageBase64 != null;

  /// Check if card is rare (SR, SEC, L, etc.)
  bool get isRare {
    final rareRarities = ['SR', 'SEC', 'L', 'SP', 'ALT'];
    return rarity != null && rareRarities.any((r) => rarity!.toUpperCase().contains(r));
  }

  /// Check if card is expensive (price > $10)
  bool get isExpensive => price != null && price! > 10.0;

  /// Get formatted price string
  String get formattedPrice => price != null ? '\$${price!.toStringAsFixed(2)}' : 'N/A';

  /// Unique identifier combining name and code (card_name + card_set_id)
  /// This handles cards with same code but different versions (e.g., alternate art with different names)
  String get uniqueId => '${name}_$code';

  /// Copy with updated fields
  CardModel copyWith({
    int? id,
    String? code,
    String? name,
    String? imageUrl,
    String? imageBase64,
    String? color,
    String? rarity,
    double? price,
    double? inventoryPrice,
    String? setId,
    String? setName,
    String? cardType,
    String? cardText,
    String? cardCost,
    String? cardPower,
    String? life,
    String? subTypes,
    int? counterAmount,
    String? attribute,
    String? cardImageId,
  }) {
    return CardModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      color: color ?? this.color,
      rarity: rarity ?? this.rarity,
      price: price ?? this.price,
      inventoryPrice: inventoryPrice ?? this.inventoryPrice,
      setId: setId ?? this.setId,
      setName: setName ?? this.setName,
      cardType: cardType ?? this.cardType,
      cardText: cardText ?? this.cardText,
      cardCost: cardCost ?? this.cardCost,
      cardPower: cardPower ?? this.cardPower,
      life: life ?? this.life,
      subTypes: subTypes ?? this.subTypes,
      counterAmount: counterAmount ?? this.counterAmount,
      attribute: attribute ?? this.attribute,
      cardImageId: cardImageId ?? this.cardImageId,
    );
  }

  @override
  String toString() => 'CardModel(code: $code, name: $name, rarity: $rarity, price: $formattedPrice)';

  /// Equality based on code + rarity (uniqueId) to handle variant cards
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModel && runtimeType == other.runtimeType && uniqueId == other.uniqueId;

  @override
  int get hashCode => uniqueId.hashCode;
}
