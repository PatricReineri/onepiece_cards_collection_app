import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Empty slot widget for uncollected cards
/// Shows a '+' icon to add new cards
class EmptySlot extends StatelessWidget {
  final VoidCallback? onTap;
  final String? label;

  const EmptySlot({
    super.key,
    this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animationFast,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: AppColors.glassWhite,
          border: Border.all(
            color: AppColors.glassBorder,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            splashColor: AppColors.cyan.withOpacity(0.3),
            highlightColor: AppColors.cyan.withOpacity(0.1),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Plus icon with glow effect
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cyan.withOpacity(0.2),
                          AppColors.purple.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppColors.cyan.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.cyan,
                      size: 28,
                    ),
                  ),

                  if (label != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      label!,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsing empty slot variant for emphasis
class PulsingEmptySlot extends StatefulWidget {
  final VoidCallback? onTap;
  final String? label;

  const PulsingEmptySlot({
    super.key,
    this.onTap,
    this.label,
  });

  @override
  State<PulsingEmptySlot> createState() => _PulsingEmptySlotState();
}

class _PulsingEmptySlotState extends State<PulsingEmptySlot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: EmptySlot(
            onTap: widget.onTap,
            label: widget.label,
          ),
        );
      },
    );
  }
}
