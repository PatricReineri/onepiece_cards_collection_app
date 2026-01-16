import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../controllers/card_controller.dart';
import '../widgets/card_tile.dart';
import '../data/models/card_model.dart';

/// Page showing all rare cards (non-common rarity)
/// Grid view with all SR, SEC, L, SP, R cards
class AllRareCardsPage extends StatefulWidget {
  const AllRareCardsPage({super.key});

  @override
  State<AllRareCardsPage> createState() => _AllRareCardsPageState();
}

class _AllRareCardsPageState extends State<AllRareCardsPage> {
  final CardController _controller = CardController();

  @override
  void initState() {
    super.initState();
    _controller.loadAllRareCards();
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/rare'),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.star, color: AppColors.purple, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'All Rare Cards',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${_controller.rareCards.length} cards',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              onPressed: _controller.loadAllRareCards,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_controller.rareCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No rare cards in your collection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add cards with SR, SEC, L, SP or R rarities',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.loadAllRareCards,
      color: AppColors.cyan,
      backgroundColor: AppColors.darkBlue,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: _controller.rareCards.length,
        itemBuilder: (context, index) {
          final card = _controller.rareCards[index];
          return CardTile(
            card: card,
            heroTag: 'allrare_card_${card.uniqueId}',
            onTap: () => _showCardDetails(card),
          );
        },
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: card.imageUrl != null
                    ? Image.network(card.imageUrl!, fit: BoxFit.contain)
                    : Container(
                        color: AppColors.glassWhite,
                        child: const Icon(Icons.image, size: 64),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              card.name,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChip(card.code),
                if (card.rarity != null) ...[
                  const SizedBox(width: 8),
                  _buildChip(card.rarity!, color: AppColors.purple),
                ],
                if (card.price != null) ...[
                  const SizedBox(width: 8),
                  _buildChip('\$${card.price!.toStringAsFixed(2)}', color: AppColors.success),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppColors.textMuted).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
