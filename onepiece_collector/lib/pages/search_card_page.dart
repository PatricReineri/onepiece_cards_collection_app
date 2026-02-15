import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/collection_controller.dart';
import '../data/models/card_model.dart';
import '../theme/app_colors.dart';

class SearchCardPage extends StatefulWidget {
  const SearchCardPage({super.key});

  @override
  State<SearchCardPage> createState() => _SearchCardPageState();
}

class _SearchCardPageState extends State<SearchCardPage> {
  final TextEditingController _searchController = TextEditingController();
  List<CardModel> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _error = null;
      _searchResults = [];
    });

    try {
      final results = await context.read<CollectionController>().searchGlobal(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Search Card', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  hintText: 'Enter card name or code (e.g. Luffy, OP01-001)...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.cyan),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: AppColors.cyan),
                    onPressed: () => _performSearch(_searchController.text),
                  ),
                ),
                onSubmitted: _performSearch,
              ),
            ),
          ),

          // Results or Status
          _buildSliverBody(),
        ],
      ),
    );
  }

  Widget _buildSliverBody() {
    if (_isSearching) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppColors.textMuted), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty && !_isSearching) {
       return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('No cards found for "${_searchController.text}"', 
                style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink()); 
    }

    // Grid of results
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final card = _searchResults[index];
            return _buildResultItem(card);
          },
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  Widget _buildResultItem(CardModel card) {
    return GestureDetector(
      onTap: () => _showCardDetails(card),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: card.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: card.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.black26),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: AppColors.textMuted),
                    )
                  : Container(
                      color: Colors.black26,
                      child: Center(
                        child: Text(card.code, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card.code,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _showCardDetails(CardModel card) async {
    // Check if collected
    final isCollected = await context.read<CollectionController>().isCardCollected(card);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _CardDetailSheet(card: card, initialIsCollected: isCollected),
    );
  }
}

/// Stateful bottom sheet for card details with collection toggle
class _CardDetailSheet extends StatefulWidget {
  final CardModel card;
  final bool initialIsCollected;

  const _CardDetailSheet({required this.card, required this.initialIsCollected});

  @override
  State<_CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends State<_CardDetailSheet> {
  late bool _isCollected;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _isCollected = widget.initialIsCollected;
  }

  Future<void> _toggleCollection() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);

    final controller = context.read<CollectionController>();

    bool success;
    if (_isCollected) {
      success = await controller.removeCardFromCollection(widget.card);
    } else {
      success = await controller.addCardToCollection(widget.card);
    }

    if (mounted) {
      setState(() {
        if (success) _isCollected = !_isCollected;
        _isToggling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
              ? (_isCollected ? '${widget.card.name} added to collection' : '${widget.card.name} removed from collection')
              : 'Operation failed',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
              // Handle
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              
              // Content
              Expanded(
                child: isLandscape 
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: widget.card.imageUrl ?? '',
                                fit: BoxFit.contain,
                                errorWidget: (context, url, err) => const Icon(Icons.broken_image, size: 50, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 6,
                          child: SingleChildScrollView(
                            child: _buildInfoContent(),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          flex: 5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: widget.card.imageUrl ?? '',
                              fit: BoxFit.contain,
                              errorWidget: (context, url, err) => const Icon(Icons.broken_image, size: 50, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(
                            child: _buildInfoContent(),
                          ),
                        ),
                      ],
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoContent() {
    return Column(
      children: [
        Text(widget.card.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(widget.card.code, style: const TextStyle(color: AppColors.cyan, fontSize: 16, fontWeight: FontWeight.bold)),
        
        const SizedBox(height: 16),
        
        // Collection Status Badge (tappable)
        GestureDetector(
          onTap: _isToggling ? null : _toggleCollection,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isCollected ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isCollected ? AppColors.success : AppColors.error),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isCollected ? Icons.check_circle : Icons.cancel, color: _isCollected ? AppColors.success : AppColors.error),
                const SizedBox(width: 8),
                Text(
                  _isCollected ? 'IN COLLECTION' : 'NOT COLLECTED',
                  style: TextStyle(
                    color: _isCollected ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Add / Remove button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isToggling ? null : _toggleCollection,
            icon: _isToggling
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(_isCollected ? Icons.remove_circle_outline : Icons.add_circle_outline),
            label: Text(_isCollected ? 'Remove from Collection' : 'Add to Collection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCollected ? AppColors.error : AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Grid of details
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _buildDetailChip('Rarity', widget.card.rarity ?? '-'),
            _buildDetailChip('Color', widget.card.color ?? '-'),
            _buildDetailChip('Type', widget.card.cardType ?? '-'),
            if (widget.card.price != null && widget.card.price! > 0)
              _buildDetailChip('Market Price', '€${widget.card.price!.toStringAsFixed(2)}'),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
