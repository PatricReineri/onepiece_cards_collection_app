import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/card_model.dart';
import '../models/set_model.dart';

/// SQLite database helper for One Piece TCG Collection
/// Manages 'cards' and 'sets' tables with CRUD operations
/// Cards are uniquely identified by code + rarity combination
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'onepiece_collection.db');

    return await openDatabase(
      path,
      version: 5, // Clear imageBase64 to fix CursorWindow error
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables (uses name+code as unique key for cards)
  Future<void> _onCreate(Database db, int version) async {
    // Cards table - uses name+code as unique key
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        image_url TEXT,
        image_base64 TEXT,
        color TEXT,
        rarity TEXT,
        price REAL,
        inventory_price REAL,
        set_id TEXT,
        set_name TEXT,
        card_type TEXT,
        card_text TEXT,
        card_cost TEXT,
        card_power TEXT,
        life TEXT,
        sub_types TEXT,
        counter_amount INTEGER,
        attribute TEXT,
        card_image_id TEXT,
        UNIQUE(name, code)
      )
    ''');

    // Sets table
    await db.execute('''
      CREATE TABLE sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        completion INTEGER DEFAULT 0,
        image_url TEXT,
        total_cards INTEGER,
        collected_cards INTEGER
      )
    ''');

    // Create indexes for faster queries
    await db.execute('CREATE INDEX idx_cards_code ON cards(code)');
    await db.execute('CREATE INDEX idx_cards_name ON cards(name)');
    await db.execute('CREATE INDEX idx_cards_set_id ON cards(set_id)');
    await db.execute('CREATE INDEX idx_cards_name_code ON cards(name, code)');
    await db.execute('CREATE INDEX idx_sets_code ON sets(code)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for CardModel fields
      await db.execute('ALTER TABLE cards ADD COLUMN inventory_price REAL');
      await db.execute('ALTER TABLE cards ADD COLUMN set_id TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN set_name TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN card_type TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN card_text TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN card_cost TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN card_power TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN life TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN sub_types TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN counter_amount INTEGER');
      await db.execute('ALTER TABLE cards ADD COLUMN attribute TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN card_image_id TEXT');
      
      // Add index for set_id
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cards_set_id ON cards(set_id)');
    }
    
    if (oldVersion < 3) {
      // Migrate from code-only unique to code+rarity unique
      // Create new table with proper constraints
      await db.execute('''
        CREATE TABLE cards_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT NOT NULL,
          name TEXT NOT NULL,
          image_url TEXT,
          image_base64 TEXT,
          color TEXT,
          rarity TEXT,
          price REAL,
          inventory_price REAL,
          set_id TEXT,
          set_name TEXT,
          card_type TEXT,
          card_text TEXT,
          card_cost TEXT,
          card_power TEXT,
          life TEXT,
          sub_types TEXT,
          counter_amount INTEGER,
          attribute TEXT,
          card_image_id TEXT,
          UNIQUE(code, rarity)
        )
      ''');
      
      // Copy data from old table
      await db.execute('''
        INSERT OR IGNORE INTO cards_new 
        SELECT * FROM cards
      ''');
      
      // Drop old table and rename new one
      await db.execute('DROP TABLE cards');
      await db.execute('ALTER TABLE cards_new RENAME TO cards');
      
      // Recreate indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cards_code ON cards(code)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cards_rarity ON cards(rarity)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cards_set_id ON cards(set_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cards_code_rarity ON cards(code, rarity)');
    }
    
    if (oldVersion < 4) {
      // Migrate from code+rarity unique to name+code unique
      await db.execute('''
        CREATE TABLE cards_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT NOT NULL,
          name TEXT NOT NULL,
          image_url TEXT,
          image_base64 TEXT,
          color TEXT,
          rarity TEXT,
          price REAL,
          inventory_price REAL,
          set_id TEXT,
          set_name TEXT,
          card_type TEXT,
          card_text TEXT,
          card_cost TEXT,
          card_power TEXT,
          life TEXT,
          sub_types TEXT,
          counter_amount INTEGER,
          attribute TEXT,
          card_image_id TEXT,
          UNIQUE(name, code)
        )
      ''');
      
      // Copy data from old table with explicit column names
      await db.execute('''
        INSERT OR IGNORE INTO cards_new 
        (id, code, name, image_url, image_base64, color, rarity, price, 
         inventory_price, set_id, set_name, card_type, card_text, card_cost, 
         card_power, life, sub_types, counter_amount, attribute, card_image_id)
        SELECT id, code, name, image_url, image_base64, color, rarity, price, 
               inventory_price, set_id, set_name, card_type, card_text, card_cost, 
               card_power, life, sub_types, counter_amount, attribute, card_image_id
        FROM cards
      ''');
      
      // Drop old table and rename new one
      await db.execute('DROP TABLE cards');
      await db.execute('ALTER TABLE cards_new RENAME TO cards');
      
      // Recreate indexes for name+code
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cards_code ON cards(code)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cards_name ON cards(name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cards_set_id ON cards(set_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cards_name_code ON cards(name, code)');
    }
    
    if (oldVersion < 5) {
      // Clear imageBase64 data to fix CursorWindow error
      // Images are cached by CachedNetworkImage widget instead
      await db.execute('UPDATE cards SET image_base64 = NULL');
    }
  }

  // ==================== CARD OPERATIONS ====================

  /// Insert a new card
  Future<int> insertCard(CardModel card) async {
    final db = await database;
    return await db.insert(
      'cards',
      card.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all cards
  Future<List<CardModel>> getAllCards() async {
    final db = await database;
    final maps = await db.query('cards', orderBy: 'code ASC');
    return maps.map((map) => CardModel.fromMap(map)).toList();
  }

  /// Get cards by set code (e.g., "OP01" or "OP-01")
  Future<List<CardModel>> getCardsBySet(String setCode) async {
    final db = await database;
    
    // Normalize set code: support both OP01 and OP-01 formats
    final normalizedCode = setCode.replaceAll('-', '');
    
    final maps = await db.query(
      'cards',
      where: "code LIKE ? OR set_id = ?",
      whereArgs: ['$normalizedCode-%', setCode],
      orderBy: 'code ASC',
    );
    return maps.map((map) => CardModel.fromMap(map)).toList();
  }

  /// Get card by name and code (exact match)
  Future<CardModel?> getCardByNameAndCode(String name, String code) async {
    final db = await database;
    final maps = await db.query(
      'cards',
      where: 'name = ? AND code = ?',
      whereArgs: [name, code],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CardModel.fromMap(maps.first);
  }

  /// Get card by code (returns first match, for backwards compatibility)
  Future<CardModel?> getCardByCode(String code) async {
    final db = await database;
    final maps = await db.query(
      'cards',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CardModel.fromMap(maps.first);
  }

  /// Get rare cards (SR, SEC, L, SP) or cards with parentheses in name (alternate art)
  Future<List<CardModel>> getRareCards() async {
    final db = await database;
    // Include: SR, SEC, L, SP, or cards with parentheses in name (alternate art)
    // Exclude: UC, C, and R cards without "Alternate Art" in name
    final maps = await db.query(
      'cards',
      where: """
        rarity IN ('SR', 'SEC', 'L', 'SP') 
        OR (rarity = 'R' AND name LIKE '%Alternate Art%')
        OR (name LIKE '%(%' AND name LIKE '%)%' AND rarity NOT IN ('C', 'UC', 'R'))
        OR (name LIKE '%(%' AND name LIKE '%)%' AND rarity = 'R' AND name LIKE '%Alternate Art%')
      """,
      orderBy: 'rarity DESC, code ASC',
    );
    return maps.map((map) => CardModel.fromMap(map)).toList();
  }

  /// Get expensive cards (ordered by price descending)
  Future<List<CardModel>> getExpensiveCards({int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      'cards',
      where: 'price IS NOT NULL AND price > 0',
      orderBy: 'price DESC',
      limit: limit,
    );
    return maps.map((map) => CardModel.fromMap(map)).toList();
  }

  /// Get total collection value (sum of all card prices)
  Future<double> getTotalCollectionValue() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(price) as total FROM cards WHERE price IS NOT NULL AND price > 0',
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// Update a card
  Future<int> updateCard(CardModel card) async {
    final db = await database;
    return await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  /// Delete a card by id
  Future<int> deleteCard(int id) async {
    final db = await database;
    return await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete a card by name and code
  Future<int> deleteCardByNameAndCode(String name, String code) async {
    final db = await database;
    return await db.delete('cards', where: 'name = ? AND code = ?', whereArgs: [name, code]);
  }

  /// Search cards by name or code
  Future<List<CardModel>> searchCards(String query) async {
    final db = await database;
    final maps = await db.query(
      'cards',
      where: 'name LIKE ? OR code LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'code ASC',
    );
    return maps.map((map) => CardModel.fromMap(map)).toList();
  }

  /// Check if a card is collected by name and code
  Future<bool> isCardCollected(String name, String code) async {
    final card = await getCardByNameAndCode(name, code);
    return card != null;
  }

  /// Get collected card unique IDs (name_code) for a set
  Future<Set<String>> getCollectedCardUniqueIds(String setCode) async {
    final cards = await getCardsBySet(setCode);
    return cards.map((c) => c.uniqueId).toSet();
  }

  /// Get collected card codes for a set (backwards compatibility)
  Future<Set<String>> getCollectedCardCodes(String setCode) async {
    final cards = await getCardsBySet(setCode);
    return cards.map((c) => c.code).toSet();
  }

  // ==================== SET OPERATIONS ====================

  /// Insert a new set
  Future<int> insertSet(SetModel set) async {
    final db = await database;
    return await db.insert(
      'sets',
      set.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all sets
  Future<List<SetModel>> getAllSets() async {
    final db = await database;
    final maps = await db.query('sets', orderBy: 'code ASC');
    return maps.map((map) => SetModel.fromMap(map)).toList();
  }

  /// Get set by code
  Future<SetModel?> getSetByCode(String code) async {
    final db = await database;
    final maps = await db.query(
      'sets',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SetModel.fromMap(maps.first);
  }

  /// Update set completion
  Future<void> updateSetCompletion(String setCode) async {
    final db = await database;
    final cards = await getCardsBySet(setCode);
    final collectedCount = cards.length;

    await db.update(
      'sets',
      {'collected_cards': collectedCount},
      where: 'code = ?',
      whereArgs: [setCode],
    );
  }

  /// Update set with total cards count
  Future<void> updateSetTotalCards(String setCode, int totalCards) async {
    final db = await database;
    await db.update(
      'sets',
      {'total_cards': totalCards},
      where: 'code = ?',
      whereArgs: [setCode],
    );
  }

  /// Get completion status for a set (rare, main, fully complete)
  /// Returns a map with isRareComplete, isMainSetComplete, isFullyComplete
  Future<Map<String, bool>> getSetCompletionStatus(String setCode, int totalMainCards) async {
    final db = await database;
    
    // Format setCode for matching (e.g., OP-01 -> OP01)
    final codePrefix = setCode.replaceAll('-', '');
    
    // Get all collected card codes for this set
    final collectedCards = await db.query(
      'cards',
      columns: ['code', 'rarity'],
      where: 'set_id = ?',
      whereArgs: [setCode],
    );
    
    // Extract unique base codes (without letter suffixes) for main set check
    final Set<String> collectedBaseCodes = {};
    bool hasAllRares = true;
    final Set<String> collectedRareCodes = {};
    
    for (final card in collectedCards) {
      final code = card['code'] as String;
      final rarity = card['rarity'] as String?;
      
      // Extract base code (e.g., OP01-001 from OP01-001a)
      final match = RegExp(r'^([A-Z]+\d+-\d+)').firstMatch(code);
      if (match != null) {
        collectedBaseCodes.add(match.group(1)!);
      }
      
      // Track rare cards (SR, SEC, L, SP)
      if (rarity != null) {
        final upperRarity = rarity.toUpperCase();
        if (upperRarity == 'SR' || upperRarity == 'SEC' || 
            upperRarity == 'L' || upperRarity == 'SP') {
          collectedRareCodes.add('${code}_$rarity');
        }
      }
    }
    
    // Check main set completion (all base codes from 001 to XXX)
    bool isMainSetComplete = true;
    for (int i = 1; i <= totalMainCards; i++) {
      final expectedCode = '$codePrefix-${i.toString().padLeft(3, '0')}';
      if (!collectedBaseCodes.contains(expectedCode)) {
        isMainSetComplete = false;
        break;
      }
    }
    
    // Check rare cards completion - query all rare cards available in this set from API would be needed
    // For now, check if we have at least some rare cards collected
    // A more accurate check would require knowing the total rare cards in the set
    final isRareComplete = collectedRareCodes.length >= 4; // Simplified check
    
    // Check fully complete (all variants)
    final setResult = await db.query(
      'sets',
      columns: ['total_cards', 'collected_cards'],
      where: 'code = ?',
      whereArgs: [setCode],
      limit: 1,
    );
    
    bool isFullyComplete = false;
    if (setResult.isNotEmpty) {
      final totalCards = setResult.first['total_cards'] as int?;
      final collectedCount = setResult.first['collected_cards'] as int?;
      if (totalCards != null && totalCards > 0 && collectedCount != null) {
        isFullyComplete = collectedCount >= totalCards;
      }
    }
    
    return {
      'isRareComplete': isRareComplete,
      'isMainSetComplete': isMainSetComplete,
      'isFullyComplete': isFullyComplete,
    };
  }

  /// Update a set
  Future<int> updateSet(SetModel set) async {
    final db = await database;
    return await db.update(
      'sets',
      set.toMap(),
      where: 'id = ?',
      whereArgs: [set.id],
    );
  }

  /// Delete a set
  Future<int> deleteSet(int id) async {
    final db = await database;
    return await db.delete('sets', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== IMPORT/EXPORT ====================

  /// Export all data as a map
  Future<Map<String, dynamic>> exportData() async {
    final cards = await getAllCards();
    final sets = await getAllSets();

    return {
      'cards': cards.map((c) => c.toJson()).toList(),
      'sets': sets.map((s) => s.toMap()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// Import data from a map, returns the number of cards imported
  Future<int> importData(Map<String, dynamic> data) async {
    final db = await database;
    int count = 0;

    // Import cards
    if (data['cards'] != null) {
      for (final cardJson in data['cards']) {
        final card = CardModel.fromJson(cardJson);
        await insertCard(card);
        count++;
      }
    }

    // Import sets
    if (data['sets'] != null) {
      for (final setMap in data['sets']) {
        final set = SetModel.fromMap(setMap);
        await insertSet(set);
      }
    }
    
    return count;
  }

  /// Delete the database (for testing)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'onepiece_collection.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
