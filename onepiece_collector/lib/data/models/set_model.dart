/// Set model representing a One Piece TCG card set
/// Maps to the 'sets' SQLite table
/// API reference: https://www.optcgapi.com/api/allSets/
class SetModel {
  final int? id;
  final String code;         // set_id from API (e.g., "OP-01")
  final String name;         // set_name from API (e.g., "Romance Dawn")
  final int completion;      // Percentage 0-100 (calculated locally)
  final String? imageUrl;    // Generated or cached set image
  final int? totalCards;     // Total cards in set
  final int? collectedCards; // Cards collected by user
  final bool isRareComplete;     // All rare cards (SR, SEC, L, SP) collected
  final bool isMainSetComplete;  // All base codes (001-XXX) collected
  final bool isFullyComplete;    // 100% collection including all variants

  SetModel({
    this.id,
    required this.code,
    required this.name,
    this.completion = 0,
    this.imageUrl,
    this.totalCards,
    this.collectedCards,
    this.isRareComplete = false,
    this.isMainSetComplete = false,
    this.isFullyComplete = false,
  });

  /// Create SetModel from SQLite map
  factory SetModel.fromMap(Map<String, dynamic> map) {
    return SetModel(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String,
      completion: map['completion'] as int? ?? 0,
      imageUrl: map['image_url'] as String?,
      totalCards: map['total_cards'] as int?,
      collectedCards: map['collected_cards'] as int?,
    );
  }

  /// Convert SetModel to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'completion': completion,
      'image_url': imageUrl,
      'total_cards': totalCards,
      'collected_cards': collectedCards,
    };
  }

  /// Create SetModel from JSON (API response from optcgapi.com /allSets/)
  factory SetModel.fromJson(Map<String, dynamic> json) {
    return SetModel(
      code: json['set_id'] ?? json['code'] ?? '',
      name: json['set_name'] ?? json['name'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'],
      totalCards: json['total_cards'] ?? json['totalCards'],
    );
  }

  /// Convert SetModel to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'set_id': code,
      'set_name': name,
      'image_url': imageUrl,
      'total_cards': totalCards,
      'collected_cards': collectedCards,
      'completion': completion,
    };
  }

  /// Generate a representative image URL for the set (first card of the set)
  /// Format: https://www.optcgapi.com/media/static/Card_Images/{setCode}-001.jpg
  String get generatedImageUrl {
    // Convert OP-01 to OP01 format for card image
    final cardCode = code.replaceAll('-', '');
    return 'https://www.optcgapi.com/media/static/Card_Images/$cardCode-001.jpg';
  }

  /// Calculate completion percentage from collected/total
  double get completionPercentage {
    if (totalCards == null || totalCards == 0) return completion.toDouble();
    if (collectedCards == null) return 0;
    return (collectedCards! / totalCards!) * 100;
  }

  /// Check if set is complete
  bool get isComplete => completionPercentage >= 100;

  /// Get display name for the set
  String get displayName => name.isNotEmpty ? name : code;

  /// Copy with updated fields
  SetModel copyWith({
    int? id,
    String? code,
    String? name,
    int? completion,
    String? imageUrl,
    int? totalCards,
    int? collectedCards,
    bool? isRareComplete,
    bool? isMainSetComplete,
    bool? isFullyComplete,
  }) {
    return SetModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      completion: completion ?? this.completion,
      imageUrl: imageUrl ?? this.imageUrl,
      totalCards: totalCards ?? this.totalCards,
      collectedCards: collectedCards ?? this.collectedCards,
      isRareComplete: isRareComplete ?? this.isRareComplete,
      isMainSetComplete: isMainSetComplete ?? this.isMainSetComplete,
      isFullyComplete: isFullyComplete ?? this.isFullyComplete,
    );
  }

  @override
  String toString() => 'SetModel(code: $code, name: $name, completion: $completion%)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetModel && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}
