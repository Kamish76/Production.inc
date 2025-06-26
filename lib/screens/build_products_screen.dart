import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;

class BuildProductsScreen extends StatelessWidget {
  const BuildProductsScreen({super.key});

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
                        Icons.build,
                        color: Colors.blue[400],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Build Products',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Current materials display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Materials:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (gameService.state.materials.isEmpty)
                        const Text(
                          'No materials available. Buy some materials first!',
                          style: TextStyle(color: Colors.white70),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: gameService.state.materials.entries
                              .where((entry) => entry.value > 0)
                              .map((entry) {
                            final materialId = entry.key;
                            final count = entry.value;
                            final material = gameService.allMaterials
                                .firstWhere((m) => m.id == materialId);
                            return Chip(
                              avatar: Text(material.emoji),
                              label: Text('${material.name}: $count'),
                              backgroundColor: Colors.grey[700],
                              labelStyle: const TextStyle(color: Colors.white),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Production status
                if (gameService.state.activeProductions.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Productions:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...gameService.state.activeProductions.map((production) {
                          final product = gameService.allProducts
                              .firstWhere((p) => p.id == production.productId);
                          final progress = (production.progress * 100).toInt();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${product.emoji} ${product.name} x${production.quantity}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: production.progress,
                                  backgroundColor: Colors.grey[600],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.orange[400]!,
                                  ),
                                ),
                                Text(
                                  '$progress% complete',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Products list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: gameService.allProducts.length,
                    itemBuilder: (context, index) {
                      final product = gameService.allProducts[index];
                      return _buildProductCard(context, product, gameService);
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

  Widget _buildProductCard(
    BuildContext context,
    game.Product product,
    ProductionGameService gameService,
  ) {
    // Check if we can produce this product
    final canProduce = gameService.state.hasMaterialsFor(product.requiredMaterials);
    
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  product.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                      Text(
                        'Production Time: ${(product.productionTimeSeconds/60).toStringAsFixed(1)} minutes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Required materials
            const Text(
              'Required Materials:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: product.requiredMaterials.entries.map((entry) {
                final materialId = entry.key;
                final required = entry.value;
                final material = gameService.allMaterials
                    .firstWhere((m) => m.id == materialId);
                final owned = gameService.state.getMaterialCount(materialId);
                final hasEnough = owned >= required;
                
                return Chip(
                  avatar: Text(material.emoji, style: const TextStyle(fontSize: 16)),
                  label: Text('${material.name}: $required'),
                  backgroundColor: hasEnough ? Colors.green[700] : Colors.red[700],
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProduceButton(context, product, 1, gameService, canProduce),
                _buildProduceButton(context, product, 5, gameService, canProduce),
                _buildProduceButton(context, product, 10, gameService, canProduce),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProduceButton(
    BuildContext context,
    game.Product product,
    int quantity,
    ProductionGameService gameService,
    bool canProduce,
  ) {
    // Check if we have materials for this quantity
    final requiredMaterials = <String, int>{};
    for (final entry in product.requiredMaterials.entries) {
      requiredMaterials[entry.key] = entry.value * quantity;
    }
    final canProduceQuantity = gameService.state.hasMaterialsFor(requiredMaterials);
    
    return ElevatedButton(
      onPressed: canProduceQuantity
          ? () => gameService.startProduction(product.id, quantity)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canProduceQuantity ? Colors.blue[600] : Colors.grey[600],
        foregroundColor: Colors.white,
      ),
      child: Text('Build $quantity'),
    );
  }
}
