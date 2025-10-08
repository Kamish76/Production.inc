import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;
import 'product_details_dialog.dart';

/// Enhanced product card widget with materials, status indicators, and production controls
class BuildProductCard extends StatelessWidget {
  final game.Product product;
  final ProductionGameService gameService;

  const BuildProductCard({
    Key? key,
    required this.product,
    required this.gameService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if we can produce this product
    final canProduce = gameService.state.hasMaterialsFor(
      product.requiredMaterials,
    );

    // Check if this product is currently in production
    final isInProduction = gameService.state.activeProductions.any(
      (task) => task.productId == product.id,
    );

    // Calculate available quantity
    final availableQuantity = gameService.state.getProductCount(product.id);

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.all(4),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: canProduce
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Entire card is now clickable for production
          final quantity = gameService.getBuildQuantityPreference(product.id);
          if (canProduce) {
            HapticFeedback.mediumImpact();
            gameService.startProduction(product.id, quantity);
          } else {
            HapticFeedback.lightImpact();
          }
        },
        onLongPress: () => _showProductDetails(context),
        child: Container(
          // Add orange production indicator as background overlay
          decoration: isInProduction
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.orange.withValues(alpha: 0.2),
                )
              : null,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product emoji and name with enhanced styling
              Row(
                children: [
                  GestureDetector(
                    onLongPress: () => _showProductDetails(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(product.productionTimeSeconds / 60).toStringAsFixed(1)}m',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Production capability indicator with better design
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: canProduce ? Colors.green[700] : Colors.red[700],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canProduce ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        canProduce ? 'Ready to Build' : 'Need Materials',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Available quantity and production status indicators
              Row(
                children: [
                  // Available quantity indicator
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Available: $availableQuantity',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (isInProduction) ...[
                    const SizedBox(width: 4),
                    // Production status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.build, size: 12, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'In Production',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Material requirements as chips
              if (product.requiredMaterials.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Materials:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Material requirements as chips with dynamic sizing
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 100,
                    minHeight: 40,
                  ),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      alignment: WrapAlignment.center,
                      children: product.requiredMaterials.entries.map((entry) {
                        final materialId = entry.key;
                        final required = entry.value;
                        final owned =
                            gameService.state.getMaterialCount(materialId) +
                                gameService.state.getProductCount(materialId);
                        final hasEnough = owned >= required;

                        final materialName =
                            gameService.getMaterial(materialId)?.name ??
                                gameService.getProduct(materialId)?.name ??
                                materialId;

                        // Simple truncation for material names
                        String displayName = materialName.length > 18
                            ? '${materialName.substring(0, 8)}...'
                            : materialName;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: hasEnough
                                ? Colors.green[600]
                                : Colors.red[600],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$displayName: $owned/$required',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Production buttons (1 and 10 as requested)
              Row(
                children: [
                  Flexible(
                    child: _buildQuantitySelectorButton(
                      context,
                      1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: _buildQuantitySelectorButton(
                      context,
                      10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelectorButton(
    BuildContext context,
    int quantity,
  ) {
    return const SizedBox(
      height: 40,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(), // Placeholder for actual button logic
      ),
    );
  }

  void _showProductDetails(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProductDetailsDialog(
          product: product,
          gameService: gameService,
        );
      },
    );
  }
}
