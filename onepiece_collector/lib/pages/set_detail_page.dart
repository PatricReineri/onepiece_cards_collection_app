import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../controllers/set_controller.dart';
import '../data/models/card_model.dart';

/// Page 1 - Vista Set / Paginazione Carte
/// 3x3 binder-style grid with editable page indicator "PAGINA 0 di 50"
/// Collected cards shown full color, missing cards darkened with + button
class SetDetailPage extends StatefulWidget {
  final String setId;

  const SetDetailPage({
    super.key,
    required this.setId,
  });

  @override
  State<SetDetailPage> createState() => _SetDetailPageState();
}

class _SetDetailPageState extends State<SetDetailPage> {
  final SetController _controller = SetController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageInputController = TextEditingController();
  final FocusNode _pageInputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.loadSet(widget.setId);
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _searchController.dispose();
    _pageInputController.dispose();
    _pageInputFocus.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
      // Update page input when page changes
      _pageInputController.text = _controller.currentPage.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E3A5F), // Dark blue-teal at top
              const Color(0xFF2D5A6B), // Mid teal
              const Color(0xFF3D7A7D), // Lighter teal at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              _buildHeader(),

              // Search bar
              _buildSearchBar(),

              // Page indicator "PAGINA 0 di 50"
              _buildPageIndicator(),

              // Card grid - binder style
              Expanded(
                child: _buildCardGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => context.go('/home'),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.white,
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Set title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _controller.currentSet?.displayName ?? widget.setId,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_controller.collectedCount}/${_controller.totalCardsCount} cards',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Completion badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_controller.completionPercentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Bulk actions menu
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.playlist_add_check,
                color: AppColors.cyan,
                size: 20,
              ),
            ),
            color: AppColors.darkBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.glassBorder),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'add_current_page':
                  await _addAllPageCards();
                  break;
                case 'add_common_rare':
                  await _addAllCommonAndRareCards();
                  break;
                case 'remove_common_rare':
                  await _removeAllCommonAndRareCards();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'add_current_page',
                child: Row(
                  children: [
                    Icon(Icons.playlist_add, color: AppColors.cyan, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aggiungi pagina corrente',
                        style: TextStyle(color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'add_common_rare',
                child: Row(
                  children: [
                    Icon(Icons.add_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aggiungi tutte C e R',
                        style: TextStyle(color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'remove_common_rare',
                child: Row(
                  children: [
                    Icon(Icons.remove_circle, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Rimuovi tutte C e R',
                        style: TextStyle(color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.purple.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _controller.search,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _controller.clearSearch();
                    },
                    icon: Icon(Icons.close, color: AppColors.textMuted),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left arrow
          IconButton(
            onPressed: _controller.currentPage > 0
                ? () => _controller.previousPage()
                : null,
            icon: Icon(
              Icons.chevron_left,
              color: _controller.currentPage > 0
                  ? AppColors.white.withOpacity(0.7)
                  : AppColors.white.withOpacity(0.2),
              size: 32,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // "PAGINA X di Y" text with editable X
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PAGINA ',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Editable page number
              GestureDetector(
                onTap: () {
                  _pageInputController.text = _controller.currentPage.toString();
                  _pageInputFocus.requestFocus();
                  _pageInputController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _pageInputController.text.length,
                  );
                },
                child: Container(
                  width: 50,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: _pageInputController,
                    focusNode: _pageInputFocus,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onSubmitted: (value) {
                      final page = int.tryParse(value);
                      if (page != null && page >= 0 && page < _controller.totalPages) {
                        _controller.goToPage(page);
                      } else {
                        _pageInputController.text = _controller.currentPage.toString();
                      }
                      _pageInputFocus.unfocus();
                    },
                  ),
                ),
              ),
              Text(
                ' di ${_controller.totalPages > 0 ? _controller.totalPages - 1 : 0}',
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.7),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 8),
          
          // Right arrow
          IconButton(
            onPressed: _controller.currentPage < _controller.totalPages - 1
                ? () => _controller.nextPage()
                : null,
            icon: Icon(
              Icons.chevron_right,
              color: _controller.currentPage < _controller.totalPages - 1
                  ? AppColors.white.withOpacity(0.7)
                  : AppColors.white.withOpacity(0.2),
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrid() {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      );
    }

    if (_controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _controller.error!,
              style: TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _controller.loadSet(widget.setId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_controller.totalPages == 0) {
      return _buildEmptyState();
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < -200) {
          // Swipe left - next page
          _controller.nextPage();
        } else if (details.primaryVelocity! > 200) {
          // Swipe right - previous page
          _controller.previousPage();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _buildBinderGrid(),
      ),
    );
  }

  Widget _buildBinderGrid() {
    final cards = _controller.currentPageCards;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate card height based on available space
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        
        // Card width = (available width - 2 gaps) / 3
        final cardWidth = (availableWidth - 16) / 3;
        // Card height based on aspect ratio 0.7
        final cardHeight = cardWidth / 0.7;
        
        // Total grid height needed for 3 rows
        final totalGridHeight = (cardHeight * 3) + 16; // 3 rows + 2 gaps
        
        // Use actual height or calculated, whichever is smaller
        final gridHeight = totalGridHeight > availableHeight 
            ? availableHeight 
            : totalGridHeight;
        
        // Recalculate aspect ratio based on available height
        final effectiveCardHeight = (gridHeight - 16) / 3;
        final effectiveAspectRatio = cardWidth / effectiveCardHeight;

        return SizedBox(
          height: gridHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: effectiveAspectRatio.clamp(0.5, 0.85),
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              if (index < cards.length) {
                final slot = cards[index];
                return _buildCardSlot(slot);
              } else {
                return _buildEmptySlot();
              }
            },
          ),
        );
      },
    );
  }

  /// Build a card slot - collected cards are full color, missing are darkened
  Widget _buildCardSlot(CardSlot slot) {
    if (slot.card == null) {
      return _buildEmptySlot();
    }

    final card = slot.card!;
    final isCollected = slot.isCollected;

    return GestureDetector(
      onTap: () => isCollected ? _showCardDetails(card) : _addCardToCollection(card),
      onLongPress: isCollected ? () => _showCardOptions(card) : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Card image
              card.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: card.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.glassWhite,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.cyan,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.glassWhite,
                        child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                      ),
                    )
                  : Container(
                      color: AppColors.glassWhite,
                      child: Center(
                        child: Text(
                          card.code,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),

              // Darkened overlay for non-collected cards
              if (!isCollected)
                Container(
                  color: Colors.black.withOpacity(0.6),
                ),

              // + button overlay for non-collected cards
              if (!isCollected)
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white.withOpacity(0.8),
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build empty slot (no card in this position)
  Widget _buildEmptySlot() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.add,
            color: Colors.white.withOpacity(0.3),
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            _controller.searchQuery.isNotEmpty
                ? 'No cards found'
                : 'No cards in this set',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _controller.searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Cards could not be loaded from API',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _controller.loadSet(widget.setId),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _addCardToCollection(CardModel card) async {
    final success = await _controller.addCard(card);
    if (!success && mounted && _controller.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showCardDetails(CardModel card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.darkBlue,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Card image
            if (card.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: card.imageUrl!,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Card name
            Text(
              card.name,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            
            // Card code
            Text(
              card.code,
              style: TextStyle(color: AppColors.textMuted),
            ),
            
            // Card details
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDetailChip('Rarity', card.rarity ?? 'N/A'),
                _buildDetailChip('Color', card.color ?? 'N/A'),
                _buildDetailChip('Price', card.formattedPrice),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showCardOptions(CardModel card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.darkBlue,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              card.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              card.code,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _controller.removeCard(card);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Remove from Collection'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Add all cards from the current page
  Future<void> _addAllPageCards() async {
    // Show loading indicator
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      ),
    );

    // Get cards from current page
    final pageSlots = _controller.currentPageCards;
    final cardsToAdd = pageSlots
        .where((slot) => slot.card != null && !slot.isCollected)
        .map((slot) => slot.card!)
        .toList();

    int addedCount = 0;
    if (cardsToAdd.isNotEmpty) {
      addedCount = await _controller.addCards(cardsToAdd);
    }

    // Close loading dialog
    if (mounted) {
      navigator.pop();
    }

     // Show result after a small delay
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      if (addedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aggiunte $addedCount carte dalla pagina corrente'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nessuna nuova carta da aggiungere in questa pagina'),
            backgroundColor: AppColors.cyan,
          ),
        );
      }
    }
  }

  /// Add all common and rare cards to the collection
  Future<void> _addAllCommonAndRareCards() async {
    // Show loading indicator
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      ),
    );

    int addedCount = 0;
    final allCards = List<CardModel>.from(_controller.allSetCards);
    
    for (final card in allCards) {
      // Check if it's common (C) or rare (R)
      final rarity = card.rarity?.toUpperCase() ?? '';
      if (rarity == 'C' || rarity == 'R') {
        // Check if not already collected
        if (!_controller.isCardCollected(card)) {
          final success = await _controller.addCard(card);
          if (success) addedCount++;
        }
      }
    }

    // Close loading dialog using rootNavigator
    if (mounted) {
      navigator.pop();
    }

    // Show result after a small delay to let navigator settle
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aggiunte $addedCount carte C e R alla collezione'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// Remove all common and rare cards from the collection
  Future<void> _removeAllCommonAndRareCards() async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Conferma rimozione',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Vuoi rimuovere tutte le carte comuni (C) e rare (R) dalla collezione?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Annulla', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Show loading indicator
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      ),
    );

    int removedCount = 0;
    final allCards = List<CardModel>.from(_controller.allSetCards);
    
    for (final card in allCards) {
      // Check if it's common (C) or rare (R)
      final rarity = card.rarity?.toUpperCase() ?? '';
      if (rarity == 'C' || rarity == 'R') {
        // Check if collected
        if (_controller.isCardCollected(card)) {
          await _controller.removeCard(card);
          removedCount++;
        }
      }
    }

    // Close loading dialog using rootNavigator
    if (mounted) {
      navigator.pop();
    }

    // Show result after a small delay to let navigator settle
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rimosse $removedCount carte C e R dalla collezione'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }
}
