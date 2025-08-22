import 'package:flutter/material.dart';
import '../constants/game_constants.dart';

/// Common progress indicator used throughout the app
///
/// This widget provides a consistent progress bar appearance with
/// optional pulsing animation and customizable colors.
class GameProgressIndicator extends StatelessWidget {
  final double progress;
  final Color? backgroundColor;
  final Color? progressColor;
  final bool showPulse;
  final double height;
  final String? label;

  const GameProgressIndicator({
    super.key,
    required this.progress,
    this.backgroundColor,
    this.progressColor,
    this.showPulse = false,
    this.height = 8.0,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? AppColors.borderLight;
    final effectiveProgressColor = progressColor ?? AppColors.primaryBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: TypographyConstants.statusIndicatorSize,
            ),
          ),
          const SizedBox(height: UIConstants.smallPadding),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child:
                showPulse
                    ? _PulsingProgressBar(
                      progress: progress,
                      color: effectiveProgressColor,
                    )
                    : LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        effectiveProgressColor,
                      ),
                    ),
          ),
        ),
      ],
    );
  }
}

/// Pulsing progress bar for active productions
class _PulsingProgressBar extends StatefulWidget {
  final double progress;
  final Color color;

  const _PulsingProgressBar({required this.progress, required this.color});

  @override
  State<_PulsingProgressBar> createState() => _PulsingProgressBarState();
}

class _PulsingProgressBarState extends State<_PulsingProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: widget.progress,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.color.withValues(alpha: _opacityAnimation.value),
          ),
        );
      },
    );
  }
}

/// Game-style elevated card with consistent styling
class GameCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  const GameCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(UIConstants.standardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border:
            showBorder
                ? Border.all(
                  color: borderColor ?? AppColors.borderAccent,
                  width: 2,
                )
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: UIConstants.cardElevation * 2,
            offset: const Offset(0, UIConstants.cardElevation),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Quantity selector button with consistent styling
class QuantitySelector extends StatelessWidget {
  final int currentQuantity;
  final List<int> options;
  final ValueChanged<int> onChanged;
  final bool isEnabled;

  const QuantitySelector({
    super.key,
    required this.currentQuantity,
    required this.options,
    required this.onChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            options.map((quantity) {
              final isSelected = quantity == currentQuantity;
              return GestureDetector(
                onTap: isEnabled ? () => onChanged(quantity) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primaryBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    quantity.toString(),
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: TypographyConstants.statusIndicatorSize,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

/// Icon with rotation animation for expand/collapse
class AnimatedExpandIcon extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onTap;
  final Color? color;
  final double size;

  const AnimatedExpandIcon({
    super.key,
    required this.isExpanded,
    this.onTap,
    this.color,
    this.size = 24.0,
  });

  @override
  State<AnimatedExpandIcon> createState() => _AnimatedExpandIconState();
}

class _AnimatedExpandIconState extends State<AnimatedExpandIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: UIConstants.iconAnimationMs),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5, // 180 degrees (0.5 turns)
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedExpandIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159, // Convert to radians
            child: Icon(
              Icons.expand_more,
              color: widget.color ?? AppColors.primaryBlue,
              size: widget.size,
            ),
          );
        },
      ),
    );
  }
}
