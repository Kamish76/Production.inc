import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../models/game_models.dart';
import '../models/game_data.dart';
import 'common_widgets.dart';

/// Enhanced product card with consistent styling and animations
///
/// This widget provides a reusable product display component used across
/// different screens (Build Products, Buy Materials, Sell Products).
/// Supports unlock animations, quantity selection, and action buttons.
class ProductCard extends StatelessWidget {
  final Product product;
  final int currentQuantity;
  final int? buildableQuantity;
  final bool isUnlocked;
  final bool isNewlyUnlocked;
  final List<int>? quantityOptions;
  final int? selectedQuantity;
  final VoidCallback? onTap;
  final VoidCallback? onQuantityTap;
  final ValueChanged<int>? onQuantityChanged;
  final Widget? actionButton;
  final String? statusText;
  final Color? statusColor;
  final double? progress;
  final bool showProgress;
  final Map<String, int>? availableMaterials;

  const ProductCard({
    super.key,
    required this.product,
    required this.currentQuantity,
    required this.isUnlocked,
    this.buildableQuantity,
    this.isNewlyUnlocked = false,
    this.quantityOptions,
    this.selectedQuantity,
    this.onTap,
    this.onQuantityTap,
    this.onQuantityChanged,
    this.actionButton,
    this.statusText,
    this.statusColor,
    this.progress,
    this.showProgress = false,
    this.availableMaterials,
  });

  @override
  Widget build(BuildContext context) {
    if (!isUnlocked) {
      return _buildLockedCard();
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: UIConstants.standardAnimationMs),
      child: GameCard(
        onTap: onTap,
        showBorder: isNewlyUnlocked,
        borderColor: isNewlyUnlocked ? AppColors.successGreen : null,
        backgroundColor:
            isNewlyUnlocked
                ? AppColors.successGreen.withValues(alpha: 0.1)
                : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: UIConstants.standardSpacing),
            _buildMaterialsSection(),
            if (showProgress && progress != null) ...[
              const SizedBox(height: UIConstants.standardSpacing),
              GameProgressIndicator(
                progress: progress!,
                showPulse: progress! < 1.0,
                label: statusText,
              ),
            ] else if (statusText != null) ...[
              const SizedBox(height: UIConstants.smallPadding),
              Text(
                statusText!,
                style: TextStyle(
                  color: statusColor ?? AppColors.textSecondary,
                  fontSize: TypographyConstants.statusIndicatorSize,
                ),
              ),
            ],
            if (quantityOptions != null && selectedQuantity != null) ...[
              const SizedBox(height: UIConstants.standardSpacing),
              _buildQuantitySelector(),
            ],
            if (actionButton != null) ...[
              const SizedBox(height: UIConstants.standardSpacing),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLockedCard() {
    return GameCard(
      backgroundColor: AppColors.cardBackground.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: AppColors.textHint, size: 20),
              const SizedBox(width: UIConstants.standardSpacing),
              Expanded(
                child: Text(
                  'Locked Product',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: TypographyConstants.productNameSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UIConstants.smallPadding),
          Text(
            'Gather materials to discover this product',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: TypographyConstants.statusIndicatorSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Product emoji and name
        Expanded(
          child: Row(
            children: [
              if (product.emoji.isNotEmpty) ...[
                Text(product.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: UIConstants.standardSpacing),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: TypographyConstants.productNameSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: TypographyConstants.statusIndicatorSize,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Quantity and price info
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (currentQuantity > 0) ...[
              Text(
                'Owned: $currentQuantity',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: TypographyConstants.statusIndicatorSize,
                ),
              ),
            ],
            if (buildableQuantity != null) ...[
              Text(
                'Can build: $buildableQuantity',
                style: TextStyle(
                  color:
                      buildableQuantity! > 0
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                  fontSize: TypographyConstants.statusIndicatorSize,
                ),
              ),
            ],
            if (product.sellPrice > 0) ...[
              Text(
                '\$${product.sellPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: TypographyConstants.productNameSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (product.productionTimeSeconds > 0) ...[
              Text(
                '${product.productionTimeSeconds.toStringAsFixed(0)}s',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: TypographyConstants.productionTimeSize,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMaterialsSection() {
    if (product.requiredMaterials.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Materials:',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: TypographyConstants.statusIndicatorSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: UIConstants.smallPadding),
        Wrap(
          spacing: UIConstants.smallPadding,
          runSpacing: UIConstants.smallPadding / 2,
          children:
              product.requiredMaterials.entries.map((entry) {
                final materialId = entry.key;
                final requiredQuantity = entry.value;
                final availableQuantity = availableMaterials?[materialId] ?? 0;
                final hasEnough = availableQuantity >= requiredQuantity;

                // Try to get material info
                String displayName = materialId;
                String emoji = '';

                // Check if it's a product
                try {
                  final materialProduct = GameData.products.firstWhere(
                    (p) => p.id == materialId,
                  );
                  displayName = materialProduct.name;
                  emoji = materialProduct.emoji;
                } catch (e) {
                  // Check if it's a material
                  try {
                    final material = GameData.materials.firstWhere(
                      (m) => m.id == materialId,
                    );
                    displayName = material.name;
                    emoji = material.emoji;
                  } catch (e) {
                    // Use ID as fallback
                  }
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.standardSpacing,
                    vertical: UIConstants.smallPadding,
                  ),
                  decoration: BoxDecoration(
                    color:
                        hasEnough
                            ? AppColors.successGreen.withValues(alpha: 0.2)
                            : AppColors.errorRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          hasEnough
                              ? AppColors.successGreen.withValues(alpha: 0.5)
                              : AppColors.errorRed.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (emoji.isNotEmpty) ...[
                        Text(emoji, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '$displayName ($requiredQuantity)',
                        style: TextStyle(
                          color:
                              hasEnough
                                  ? AppColors.successGreen
                                  : AppColors.errorRed,
                          fontSize: TypographyConstants.statusIndicatorSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Text(
          'Quantity:',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: TypographyConstants.statusIndicatorSize,
          ),
        ),
        const SizedBox(width: UIConstants.standardSpacing),
        Expanded(
          child: QuantitySelector(
            currentQuantity: selectedQuantity!,
            options: quantityOptions!,
            onChanged: onQuantityChanged ?? (_) {},
          ),
        ),
        if (onQuantityTap != null) ...[
          const SizedBox(width: UIConstants.standardSpacing),
          IconButton(
            onPressed: onQuantityTap,
            icon: const Icon(
              Icons.edit,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            constraints: const BoxConstraints(
              minWidth: UIConstants.minTouchTarget,
              minHeight: UIConstants.minTouchTarget,
            ),
          ),
        ],
      ],
    );
  }
}
