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
        return Scaffold(
          appBar: AppBar(
            title: const Text('Build Products'),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
            child: Column(
              children: [
                // Current materials display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Current Materials',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...gameService.allMaterials.map((material) {
                        final count = gameService.state.getMaterialCount(material.id);
                        return Text(
                          '${material.emoji} ${material.name}: $count',
                          style: const TextStyle(color: Colors.white),
                        );
                      }),
                    ],
                  ),
                ),
                
                // Active productions
                if (gameService.state.activeProductions.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Active Productions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...gameService.state.activeProductions.map((task) {
                          final product = gameService.getProduct(task.productId);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${product?.emoji} ${product?.name} x${task.quantity}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      '${(task.progress * 100).toInt()}%',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                LinearProgressIndicator(
                                  value: task.progress,
                                  backgroundColor: Colors.grey[600],
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[300]!),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Products to build
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
                        'Sell Price: \$${product.sellPrice.toStringAsFixed(2)} | Time: ${product.productionTimeSeconds}s',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Required materials
            Text(
              'Required Materials:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[300],
              ),
            ),
            ...product.requiredMaterials.entries.map((entry) {
              final material = gameService.getMaterial(entry.key);
              final needed = entry.value;
              final have = gameService.state.getMaterialCount(entry.key);
              final hasEnough = have >= needed;
              
              return Text(
                '  ${material?.emoji} ${material?.name}: $have/$needed',
                style: TextStyle(
                  fontSize: 12,
                  color: hasEnough ? Colors.green[300] : Colors.red[300],
                ),
              );
            }),
            
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProduceButton(context, product, 1, gameService, canProduce),
                _buildProduceButton(context, product, 3, gameService, canProduce),
                _buildProduceButton(context, product, 5, gameService, canProduce),
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
