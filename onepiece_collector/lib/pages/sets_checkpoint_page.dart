import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/collection_controller.dart';
import '../data/models/card_model.dart';
import '../data/models/set_model.dart';
import '../theme/app_colors.dart';
import '../widgets/card_tile.dart';

class SetsCheckpointPage extends StatefulWidget {
  const SetsCheckpointPage({super.key});

  @override
  State<SetsCheckpointPage> createState() => _SetsCheckpointPageState();
}

class _SetsCheckpointPageState extends State<SetsCheckpointPage> {
  // Use a Future to load data once
  late Future<Map<SetModel, List<CardModel>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = context.read<CollectionController>().getCheckpointData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      appBar: AppBar(
        title: const Text('Sets Checkpoint', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: FutureBuilder<Map<SetModel, List<CardModel>>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          final data = snapshot.data;
          
          if (data == null || data.isEmpty) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.collections_bookmark_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No cards in collection yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            );
          }

          // Sort sets by code (optional, as getCheckpointData return map keys might not be sorted by insertion if I did not use SplayTreeMap, but Controller sorted the list of keys? Controller returned standard Map. I should sort keys here for display order)
          final sortedSets = data.keys.toList()
            ..sort((a, b) => a.code.compareTo(b.code));

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: sortedSets.length,
            itemBuilder: (context, index) {
              final set = sortedSets[index];
              final cards = data[set]!;
              
              return _buildSetSection(set, cards);
            },
          );
        },
      ),
    );
  }

  Widget _buildSetSection(SetModel set, List<CardModel> cards) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        collapsedIconColor: AppColors.textMuted,
        iconColor: AppColors.cyan,
        title: Row(
          children: [
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(
                 color: AppColors.cyan.withOpacity(0.2),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Text(
                 set.code,
                 style: const TextStyle(
                   color: AppColors.cyan,
                   fontWeight: FontWeight.bold,
                   fontSize: 14,
                 ),
               ),
             ),
             const SizedBox(width: 12),
             Expanded(
               child: Text(
                 set.name,
                 style: const TextStyle(
                   color: AppColors.textPrimary, 
                   fontWeight: FontWeight.w600,
                   fontSize: 16
                 ),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
               ),
             ),
             Text(
               '${cards.length}',
               style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
             ),
          ],
        ),
        children: [
          _buildCardGrid(cards),
        ],
      ),
    );
  }

  Widget _buildCardGrid(List<CardModel> cards) {
    // We use a LayoutBuilder to constrain the grid if necessary,
    // though SliverGridDelegateWithMaxCrossAxisExtent handles responsiveness well.
    // Since this is inside a Column (ExpansionTile children), we must use shrinkWrap: true.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return CardTile(
            card: card,
            onTap: () => _showCardDetails(card),
          );
        },
      ),
    );
  }

  // Reuse the responsive modal logic
  void _showCardDetails(CardModel card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
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
                  child: isLandscape
                    ? Row(
                        children: [
                           Expanded(
                             flex: 4,
                             child: ClipRRect(
                               borderRadius: BorderRadius.circular(16),
                               child: card.imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: card.imageUrl!,
                                      fit: BoxFit.contain,
                                      errorWidget: (context, url, error) => Image.asset(
                                        'lib/data/images/card_template.png',
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.glassWhite,
                                      child: const Icon(Icons.image, size: 64),
                                    ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             flex: 6,
                             child: SingleChildScrollView(
                               child: _buildCardInfoInModal(card),
                             ),
                           ),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: card.imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: card.imageUrl!,
                                      fit: BoxFit.contain,
                                      errorWidget: (context, url, error) => Image.asset(
                                        'lib/data/images/card_template.png',
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.glassWhite,
                                      child: const Icon(Icons.image, size: 64),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildCardInfoInModal(card),
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

  Widget _buildCardInfoInModal(CardModel card) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          card.name,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildChip(card.code),
            if (card.rarity != null) 
              _buildChip(card.rarity!, color: AppColors.purple),
            if (card.price != null) 
             _buildChip('\$${card.price!.toStringAsFixed(2)}', color: AppColors.success),
          ],
        ),
      ],
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
