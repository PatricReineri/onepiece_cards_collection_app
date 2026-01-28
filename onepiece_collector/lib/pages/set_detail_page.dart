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
          color: AppColors.darkBlue, 
          image: DecorationImage(
            image: const AssetImage('lib/data/images/pirate_background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              AppColors.darkBlue.withOpacity(0.8), 
              BlendMode.hardLight,
            ),
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
             onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < -200) {
                _controller.nextPage();
              } else if (details.primaryVelocity! > 200) {
                _controller.previousPage();
              }
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(child: _buildPageIndicator()),
                _buildSliverCardGrid(),
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
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
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
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
                case 'show_missing':
                  _showMissingCards();
                  break;
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
                value: 'show_missing',
                child: Row(
                  children: [
                    Icon(Icons.search_off, color: AppColors.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Show missing cards',
                        style: TextStyle(color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'add_current_page',
                child: Row(
                  children: [
                    Icon(Icons.playlist_add, color: AppColors.cyan, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add current page',
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
                        'Add all C and R',
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
                        'Remove all C and R',
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

  Widget _buildSliverCardGrid() {
    if (_controller.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      );
    }

    if (_controller.error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _controller.error!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _controller.loadSet(widget.setId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller.totalPages == 0) {
      return SliverFillRemaining(child: _buildEmptyState());
    }

    final cards = _controller.currentPageCards;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < cards.length) {
              return _buildCardSlot(cards[index]);
            } else {
              return _buildEmptySlot();
            }
          },
          childCount: 9, 
        ),
      ),
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
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
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
                const SizedBox(height: 16),
                
                // Content
                Expanded(
                  child: isLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Landscape: Image Left
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: card.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorWidget: (_,__,___) => const Icon(Icons.broken_image, size: 50, color: AppColors.textMuted),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Landscape: Details Right
                          Expanded(
                            flex: 6,
                            child: SingleChildScrollView(
                              child: _buildCardDetailContent(card),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          // Portrait: Image Top
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: card.imageUrl!,
                                fit: BoxFit.contain,
                                errorWidget: (_,__,___) => const Icon(Icons.broken_image, size: 50, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Portrait: Details Bottom
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              child: _buildCardDetailContent(card),
                            ),
                          ),
                        ],
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardDetailContent(CardModel card) {
    return Column(
      children: [
        Text(
          card.name,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          card.code,
          style: TextStyle(color: AppColors.textMuted),
        ),
        
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDetailChip('Rarity', card.rarity ?? 'N/A'),
            _buildDetailChip('Color', card.color ?? 'N/A'),
            _buildDetailChip('Price', card.formattedPrice),
          ],
        ),
      ],
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
            content: Text('Added $addedCount cards from current page'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new cards to add on this page'),
            backgroundColor: AppColors.cyan,
          ),
        );
      }
    }
  }

  /// Show list of missing cards
  void _showMissingCards() {
    // Get all missing cards from the set
    final missingCards = _controller.allSetCards
        .where((card) => !_controller.isCardCollected(card))
        .toList();
    
    // Sort by code
    missingCards.sort((a, b) => a.code.compareTo(b.code));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.darkBlue,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Missing Cards (${missingCards.length})',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // List of missing cards
            Expanded(
              child: missingCards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, 
                               color: AppColors.success, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'Collection complete!',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: missingCards.length,
                      itemBuilder: (context, index) {
                        final card = missingCards[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.glassWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.glassBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Card code badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  card.code,
                                  style: TextStyle(
                                    color: AppColors.warning.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Card name
                              Expanded(
                                child: Text(
                                  card.name,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Rarity badge
                              if (card.rarity != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRarityColor(card.rarity!)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    card.rarity!,
                                    style: TextStyle(
                                      color: _getRarityColor(card.rarity!),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'SEC':
        return Colors.amber;
      case 'L':
        return Colors.orange;
      case 'SR':
        return AppColors.purple;
      case 'R':
        return AppColors.cyan;
      case 'UC':
        return AppColors.success;
      default:
        return AppColors.textMuted;
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
          content: Text('Added $addedCount C and R cards to collection'),
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
          'Confirm removal',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Do you want to remove all common (C) and rare (R) cards from collection?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
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
          content: Text('Removed $removedCount C and R cards from collection'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }
}
