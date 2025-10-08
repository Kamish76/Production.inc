import 'package:flutter/material.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;

/// Dialog that displays detailed information about a product
class ProductDetailsDialog extends StatelessWidget {
  final game.Product product;
  final ProductionGameService gameService;

  const ProductDetailsDialog({
    Key? key,
    required this.product,
    required this.gameService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Text(product.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product.description,
              style: TextStyle(color: Colors.grey[300], fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Production stats
            _buildStatRow(
              'Production Time',
              '${(product.productionTimeSeconds / 60).toStringAsFixed(1)} minutes',
            ),
            _buildStatRow(
              'Sell Price',
              '\$${product.sellPrice.toStringAsFixed(2)}',
            ),
            _buildStatRow('Tier', gameService.getTierName(product.levelId)),

            const SizedBox(height: 16),

            // Required materials
            if (product.requiredMaterials.isNotEmpty) ...[
              const Text(
                'Required Materials:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...product.requiredMaterials.entries.map((entry) {
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

                final emoji = gameService.getMaterial(materialId)?.emoji ??
                    gameService.getProduct(materialId)?.emoji ??
                    '📦';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          materialName,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: hasEnough
                              ? Colors.green[600]
                              : Colors.red[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$owned/$required',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close', style: TextStyle(color: Colors.blue[400])),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
