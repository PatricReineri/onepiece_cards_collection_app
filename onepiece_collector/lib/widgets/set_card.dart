import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../data/models/set_model.dart';

/// Set card widget for collection home page
/// Displays set image, name, and completion progress bar
class SetCard extends StatelessWidget {
  final SetModel set;
  final VoidCallback? onTap;

  const SetCard({
    super.key,
    required this.set,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFullyComplete = set.isFullyComplete || set.completionPercentage >= 100;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          gradient: LinearGradient(
            colors: isFullyComplete 
              ? [
                  Colors.amber.withOpacity(0.2),
                  Colors.orange.withOpacity(0.1),
                ]
              : [
                  AppColors.glassWhite,
                  AppColors.glassWhite.withOpacity(0.05),
                ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isFullyComplete 
              ? Colors.amber.withOpacity(0.6) 
              : AppColors.glassBorder,
            width: isFullyComplete ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isFullyComplete 
                ? Colors.amber.withOpacity(0.3) 
                : Colors.black.withOpacity(0.2),
              blurRadius: isFullyComplete ? 16 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Set image
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildSetImage(),
                  ),

                  // Set info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Set name and code
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                set.displayName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.cyan.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                set.code,
                                style: const TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Completion progress
                        _buildProgressBar(),

                        const SizedBox(height: 8),

                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${set.collectedCards ?? 0} / ${set.totalCards ?? '?'} cards',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${set.completionPercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: _getProgressColor(set.completionPercentage),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        
                        // Completion badges row
                        if (set.isMainSetComplete || set.isRareComplete || isFullyComplete)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (isFullyComplete)
                                  _buildBadge('100%', Colors.amber, Icons.emoji_events),
                                if (set.isMainSetComplete && !isFullyComplete)
                                  _buildBadge('MAIN', AppColors.success, Icons.check_circle),
                                if (set.isRareComplete)
                                  _buildBadge('RARE', AppColors.warning, Icons.star),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Trophy icon for fully complete sets
              if (isFullyComplete)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetImage() {
    // Use local asset image: lib/data/images/{set_code}.jpg
    // Fallback to template.jpg if not found
    final setCode = set.code.replaceAll('-', ''); // OP-01 -> OP01

    final imagePath = 'lib/data/images/$setCode.jpg';
    final fallbackPath = 'lib/data/images/template.jpg';

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Try fallback template image
        return Image.asset(
          fallbackPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // If template also fails, show placeholder
            return _buildImagePlaceholder();
          },
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withOpacity(0.3),
            AppColors.cyan.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              set.code,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = set.completionPercentage / 100;
    final color = _getProgressColor(set.completionPercentage);

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Progress fill
              AnimatedContainer(
                duration: AppTheme.animationMedium,
                width: constraints.maxWidth * progress.clamp(0, 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 100) {
      return AppColors.success;
    } else if (percentage >= 75) {
      return AppColors.cyan;
    } else if (percentage >= 50) {
      return AppColors.purple;
    } else if (percentage >= 25) {
      return AppColors.warning;
    } else {
      return AppColors.textMuted;
    }
  }
}
