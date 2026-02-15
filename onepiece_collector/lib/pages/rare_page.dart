import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../controllers/card_controller.dart';
import '../widgets/card_tile.dart';
import '../data/models/card_model.dart';

/// Page 3 - Rare & Costose
/// Horizontal scroll sections for rare and expensive cards
class RarePage extends StatefulWidget {
  const RarePage({super.key});

  @override
  State<RarePage> createState() => _RarePageState();
}

class _RarePageState extends State<RarePage> {
  final CardController _controller = CardController();

  @override
  void initState() {
    super.initState();
    _controller.loadRareAndExpensive();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            _controller.isLoading && !_controller.isRefreshingPrices
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.cyan),
                  )
                : RefreshIndicator(
                    onRefresh: _controller.loadRareAndExpensive,
                    color: AppColors.cyan,
                    backgroundColor: AppColors.darkBlue,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          _buildHeader(),

                          // Rare cards section
                          _buildSection(
                            sectionId: 'rare',
                            title: 'Rare Cards',
                            subtitle: 'SR, SEC, L, SP rarities',
                            icon: Icons.star,
                            iconColor: AppColors.purple,
                            cards: _controller.rareCards,
                            emptyMessage: 'No rare cards in your collection yet',
                            onSeeAll: () => context.go('/all-rare'),
                          ),

                          const SizedBox(height: 24),

                          // Expensive cards section
                          _buildSection(
                            sectionId: 'valuable',
                            title: 'Most Valuable',
                            subtitle: 'Sorted by market price',
                            icon: Icons.attach_money,
                            iconColor: AppColors.success,
                            cards: _controller.expensiveCards,
                            showPrice: true,
                            emptyMessage: 'No priced cards available',
                            onSeeAll: () => context.go('/all-valuable'),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

            // Blocking overlay during price refresh
            if (_controller.isRefreshingPrices)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.darkBlue,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.glassBorder),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.currency_exchange,
                          color: AppColors.cyan,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Updating Prices',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _controller.refreshTotal > 0
                            ? '${_controller.refreshProgress} / ${_controller.refreshTotal}'
                            : 'Loading cards...',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _controller.refreshTotal > 0
                              ? _controller.refreshProgress / _controller.refreshTotal
                              : null,
                            minHeight: 8,
                            backgroundColor: AppColors.glassWhite,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _controller.refreshTotal > 0
                            ? '${(_controller.refreshProgress / _controller.refreshTotal * 100).toStringAsFixed(0)}%'
                            : '',
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rare & Valuable',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              // Refresh prices button
              GestureDetector(
                onTap: _controller.isRefreshingPrices ? null : _refreshPrices,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: AppColors.cyan, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Update Prices',
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your most valuable cards',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // Collection value box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.2),
                  AppColors.cyan.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.success,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valore Collezione',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '\$${_controller.totalCollectionValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String sectionId,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<CardModel> cards,
    bool showPrice = false,
    required String emptyMessage,
    VoidCallback? onSeeAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Card count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cards.length}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // See All button
              if (onSeeAll != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSeeAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See All',
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, color: iconColor, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Horizontal card list
        if (cards.isEmpty)
          _buildEmptySection(emptyMessage)
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return Container(
                  width: 140,
                  margin: EdgeInsets.only(
                    right: index < cards.length - 1 ? 12 : 0,
                  ),
                  child: CardTile(
                    card: card,
                    showPrice: showPrice,
                    heroTag: '${sectionId}_card_${card.uniqueId}',
                    onTap: () => _showCardDetails(card),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardDetails(CardModel card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
            const SizedBox(height: 24),

            // Card image (large)
            Expanded(
              child: Hero(
                tag: 'card_${card.code}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: card.imageUrl != null
                        ? Image.network(
                            card.imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(card),
                          )
                        : _buildPlaceholder(card),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Card info
            Column(
              children: [
                Text(
                  card.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildInfoChip(card.code),
                    if (card.rarity != null) ...[
                      const SizedBox(width: 8),
                      _buildInfoChip(card.rarity!, isRarity: true),
                    ],
                    if (card.price != null) ...[
                      const SizedBox(width: 8),
                      _buildInfoChip('\$${card.price!.toStringAsFixed(2)}',
                          isPrice: true),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(CardModel card) {
    return Container(
      color: AppColors.darkBlue,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text(card.code, style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, {bool isRarity = false, bool isPrice = false}) {
    Color bgColor = AppColors.glassWhite;
    Color textColor = AppColors.textPrimary;

    if (isRarity) {
      bgColor = AppColors.purple.withOpacity(0.2);
      textColor = AppColors.purple;
    } else if (isPrice) {
      bgColor = AppColors.success.withOpacity(0.2);
      textColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _refreshPrices() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing prices...'),
        backgroundColor: AppColors.cyan,
        duration: Duration(seconds: 1),
      ),
    );
    await _controller.refreshPrices();
  }
}
