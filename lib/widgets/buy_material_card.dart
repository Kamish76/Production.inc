import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;
import 'quantity_selector_button.dart';

/// Material card widget for the buy materials screen
class BuyMaterialCard extends StatelessWidget {
  final game.Material material;
  final ProductionGameService gameService;

  const BuyMaterialCard({
    Key? key,
    required this.material,
    required this.gameService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final owned = gameService.state.getMaterialCount(material.id);
    final currentPreference = gameService.getBuyQuantityPreference(material.id);
    final cost = material.buyPrice * currentPreference;
    final canAfford = gameService.state.canAfford(cost);

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.all(4),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: canAfford
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Entire card is clickable for buying
          if (canAfford) {
            HapticFeedback.mediumImpact();
            gameService.buyMaterial(material.id, currentPreference);
          } else {
            HapticFeedback.lightImpact();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Material emoji and name with enhanced styling
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      material.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.name,
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
                          '\$${material.buyPrice.toStringAsFixed(2)} each',
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

              // Owned quantity indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Owned: $owned',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),

              // Description with more space for better readability
              Text(
                material.description,
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Buy quantity selector buttons - Optimized for single-column
              Row(
                children: [
                  Expanded(
                    child: QuantitySelectorButton(
                      quantity: 1,
                      cost: material.buyPrice * 1,
                      isSelected: currentPreference == 1,
                      canAfford: gameService.state.canAfford(material.buyPrice * 1),
                      onPressed: () => _handleQuantitySelection(1),
                      label: 'Buy 1',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: QuantitySelectorButton(
                      quantity: 5,
                      cost: material.buyPrice * 5,
                      isSelected: currentPreference == 5,
                      canAfford: gameService.state.canAfford(material.buyPrice * 5),
                      onPressed: () => _handleQuantitySelection(5),
                      label: 'Buy 5',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: QuantitySelectorButton(
                      quantity: 10,
                      cost: material.buyPrice * 10,
                      isSelected: currentPreference == 10,
                      canAfford: gameService.state.canAfford(material.buyPrice * 10),
                      onPressed: () => _handleQuantitySelection(10),
                      label: 'Buy 10',
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

  void _handleQuantitySelection(int quantity) {
    final cost = material.buyPrice * quantity;
    final canAfford = gameService.state.canAfford(cost);

    if (canAfford) {
      HapticFeedback.mediumImpact();
      // Direct buy action
      gameService.buyMaterial(material.id, quantity);
      // Also set as preference
      gameService.setBuyQuantityPreference(material.id, quantity);
    } else {
      // Just set preference even if can't afford
      HapticFeedback.lightImpact();
      gameService.setBuyQuantityPreference(material.id, quantity);
    }
  }
}