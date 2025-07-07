import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;

class BuyMaterialsScreen extends StatelessWidget {
  const BuyMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionGameService>(
      builder: (context, gameService, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Screen title
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        color: Colors.green[400],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Buy Materials',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Money display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Money: \$${gameService.state.money.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Materials list with single-column layout for better readability
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: gameService.allMaterials.length,
                    itemBuilder: (context, index) {
                      final material = gameService.allMaterials[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildEnhancedMaterialCard(
                          context,
                          material,
                          gameService,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedMaterialCard(
    BuildContext context,
    game.Material material,
    ProductionGameService gameService,
  ) {
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
          color:
              canAfford
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // V1.4.11: Entire card is now clickable for buying
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

              // // Purchase capability indicator
              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              //   decoration: BoxDecoration(
              //     color: canAfford ? Colors.green[700] : Colors.red[700],
              //     borderRadius: BorderRadius.circular(6),
              //   ),
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Icon(
              //         canAfford ? Icons.check_circle : Icons.cancel,
              //         size: 14,
              //         color: Colors.white,
              //       ),
              //       const SizedBox(width: 4),
              //       Flexible(
              //         child: Text(
              //           canAfford ? 'Can Afford' : 'Need More Money',
              //           style: const TextStyle(
              //             fontSize: 13,
              //             color: Colors.white,
              //             fontWeight: FontWeight.w500,
              //           ),
              //           overflow: TextOverflow.ellipsis,
              //           textAlign: TextAlign.center,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 8),

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
                maxLines:
                    3, // Increased from 2 for better description visibility
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12), // Slightly increased spacing
              // Buy quantity selector buttons (V1.4.11: Dual-function) - Optimized for single-column
              Row(
                children: [
                  Expanded(
                    // Changed from Flexible to Expanded for better button sizing
                    child: _buildQuantitySelectorButton(
                      context,
                      material,
                      1,
                      gameService,
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ), // Increased spacing for better touch targets
                  Expanded(
                    // Changed from Flexible to Expanded for better button sizing
                    child: _buildQuantitySelectorButton(
                      context,
                      material,
                      5,
                      gameService,
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ), // Increased spacing for better touch targets
                  Expanded(
                    // Changed from Flexible to Expanded for better button sizing
                    child: _buildQuantitySelectorButton(
                      context,
                      material,
                      10,
                      gameService,
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
    game.Material material,
    int quantity,
    ProductionGameService gameService,
  ) {
    final isSelected =
        gameService.getBuyQuantityPreference(material.id) == quantity;
    final cost = material.buyPrice * quantity;
    final canAfford = gameService.state.canAfford(cost);

    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: () {
          // V1.4.11: Dual-function button
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
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected
                  ? (canAfford ? Colors.green[600] : Colors.orange[600])
                  : (canAfford ? Colors.grey[700] : Colors.red[800]),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side:
                isSelected
                    ? BorderSide(color: Colors.blue[300]!, width: 2)
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
                'Buy $quantity',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '\$${cost.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
