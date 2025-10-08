import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;

class SellProductCard extends StatelessWidget {
  final game.Product product;
  final ProductionGameService gameService;
  final VoidCallback? onProductDetails;

  const SellProductCard({
    super.key,
    required this.product,
    required this.gameService,
    this.onProductDetails,
  });

  String _getStockLevel(int available) {
    if (available >= 20) return 'high';
    if (available >= 5) return 'medium';
    return 'low';
  }

  Color _getStockLevelColor(String stockLevel) {
    switch (stockLevel) {
      case 'high':
        return Colors.green[700]!;
      case 'medium':
        return Colors.orange[700]!;
      case 'low':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  IconData _getStockLevelIcon(String stockLevel) {
    switch (stockLevel) {
      case 'high':
        return Icons.trending_up;
      case 'medium':
        return Icons.trending_flat;
      case 'low':
        return Icons.trending_down;
      default:
        return Icons.inventory;
    }
  }

  Widget _buildQuantitySelectorButton(
    BuildContext context,
    int quantity,
    int available,
  ) {
    final isSelected =
        gameService.getSellQuantityPreference(product.id) == quantity;
    final canSell = available >= quantity;
    final revenue = product.sellPrice * quantity;

    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: () {
          // V1.4.11: Dual-function button
          if (canSell) {
            HapticFeedback.mediumImpact();
            // Direct sell action
            gameService.sellProduct(product.id, quantity);
            // Also set as preference
            gameService.setSellQuantityPreference(product.id, quantity);
          } else {
            // Just set preference even if can't sell
            HapticFeedback.lightImpact();
            gameService.setSellQuantityPreference(product.id, quantity);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected
                  ? (canSell ? Colors.purple[600] : Colors.orange[600])
                  : (canSell ? Colors.grey[700] : Colors.red[800]),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side:
                isSelected
                    ? BorderSide(color: Colors.purple[300]!, width: 2)
                    : BorderSide.none,
          ),
          elevation: isSelected ? 6 : 2,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sell $quantity',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '\$${revenue.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = gameService.state.getProductCount(product.id);
    final stockLevel = _getStockLevel(available);

    // Check if this product is currently in production
    final isInProduction = gameService.state.activeProductions.any(
      (task) => task.productId == product.id,
    );

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.all(4),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStockLevelColor(stockLevel).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // V1.4.11: Entire card is now clickable for selling
          final quantity = gameService.getSellQuantityPreference(product.id);
          if (available >= quantity) {
            HapticFeedback.mediumImpact();
            gameService.sellProduct(product.id, quantity);
          } else {
            HapticFeedback.lightImpact();
          }
        },
        onLongPress: onProductDetails,
        child: Container(
          // Add orange production indicator as background overlay
          decoration:
              isInProduction
                  ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.orange.withValues(alpha: 0.2),
                  )
                  : null,
          padding: const EdgeInsets.all(10), // Mobile-optimized padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product emoji and name with enhanced styling
              Row(
                children: [
                  GestureDetector(
                    onLongPress: onProductDetails,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.emoji,
                        style: const TextStyle(fontSize: 32), // Prominent emoji
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
                            fontSize: 14, // Mobile-optimized for 3 columns
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '\$${product.sellPrice.toStringAsFixed(2)} each',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stock availability indicator with color coding
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStockLevelColor(stockLevel),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStockLevelIcon(stockLevel),
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Available: $available',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Production status indicator (if product is being produced)
              if (isInProduction)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.build, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Producing',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isInProduction) const SizedBox(height: 8),

              // Revenue potential display
              if (available > 0) ...[
                Text(
                  'Revenue Potential:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: \$${(product.sellPrice * available).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green[300],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Sell buttons (1, 5, and 10 with dual-function) - V1.4.11
              Row(
                children: [
                  Flexible(
                    child: _buildQuantitySelectorButton(context, 1, available),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: _buildQuantitySelectorButton(context, 5, available),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: _buildQuantitySelectorButton(context, 10, available),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}