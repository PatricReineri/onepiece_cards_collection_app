import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../data/models/card_model.dart';

/// Card tile widget with glassmorphism effect
/// Displays card image, name, and rarity badge
/// Supports tap to view details and long press to remove from collection
class CardTile extends StatelessWidget {
  final CardModel card;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRemove;
  final bool showPrice;
  final bool isCollected;
  final String? heroTag; // Optional unique hero tag to avoid conflicts

  const CardTile({
    super.key,
    required this.card,
    this.onTap,
    this.onLongPress,
    this.onRemove,
    this.showPrice = false,
    this.isCollected = true,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress ?? (onRemove != null ? () => _showRemoveDialog(context) : null),
      child: Hero(
        tag: heroTag ?? 'card_${card.code}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            gradient: LinearGradient(
              colors: [
                AppColors.glassWhite,
                AppColors.glassWhite.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Card image
                _buildCardImage(),

                // Gradient overlay for text visibility
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Card info
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Card name
                      Text(
                        card.name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Card code and price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              card.code,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showPrice && card.price != null)
                            Text(
                              '\$${card.price!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.cyan,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Rarity badge
                if (card.rarity != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getRarityColor(card.rarity!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        card.rarity!,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Remove button indicator (shown on long press)
                if (isCollected && onRemove != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Remove Card',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove "${card.name}" from your collection?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardImage() {
    // Priority: Base64 > URL > Placeholder
    if (card.imageBase64 != null && card.imageBase64!.isNotEmpty) {
      return Image.memory(
        base64Decode(card.imageBase64!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else if (card.imageUrl != null && card.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: card.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildLoadingPlaceholder(),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Image.asset(
      'lib/data/images/card_template.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.darkBlue,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.style,
                size: 32,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                card.code,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppColors.darkBlue,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.cyan,
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'SEC':
        return const Color(0xFFFFD700); // Gold
      case 'SR':
        return AppColors.purple;
      case 'L':
        return const Color(0xFFFF6B6B); // Red
      case 'SP':
        return const Color(0xFF00CED1); // Turquoise
      case 'R':
        return AppColors.cyan;
      default:
        return AppColors.textMuted;
    }
  }
}
