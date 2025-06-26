import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;

class BuildProductsScreen extends StatefulWidget {
  const BuildProductsScreen({super.key});

  @override
  State<BuildProductsScreen> createState() => _BuildProductsScreenState();
}

class _BuildProductsScreenState extends State<BuildProductsScreen> {
  bool _isProductionExpanded = false;

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
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isProductionExpanded = !_isProductionExpanded;
                            });
                          },
                          child: Row(
                            children: [
                              const Text(
                                'Active Productions:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _isProductionExpanded 
                                    ? Icons.expand_less 
                                    : Icons.expand_more,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isProductionExpanded)
                          // Show all productions when expanded
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount: gameService.state.activeProductions.length,
                              itemBuilder: (context, index) {
                                final production = gameService.state.activeProductions[index];
                                return _buildProductionItem(production, gameService);
                              },
                            ),
                          )
                        else
                          // Show only the next production to finish when collapsed
                          Builder(
                            builder: (context) {
                              // Find the production that will finish first (highest progress)
                              final nextProduction = gameService.state.activeProductions
                                  .reduce((a, b) => a.progress > b.progress ? a : b);
                              return _buildProductionItem(nextProduction, gameService);
                            },
                          ),
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
                        'Base Production Time: ${(product.productionTimeSeconds/60).toStringAsFixed(1)} min per item',
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
    
    // Calculate total production time for this quantity
    final totalTimeMinutes = (product.productionTimeSeconds * quantity / 60);
    final timeText = totalTimeMinutes < 60 
        ? '${totalTimeMinutes.toStringAsFixed(1)}m'
        : '${(totalTimeMinutes / 60).toStringAsFixed(1)}h';
    
    return ElevatedButton(
      onPressed: canProduceQuantity
          ? () => gameService.startProduction(product.id, quantity)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canProduceQuantity ? Colors.blue[600] : Colors.grey[600],
        foregroundColor: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Build $quantity'),
          Text(
            timeText,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionItem(dynamic production, ProductionGameService gameService) {
    final product = gameService.allProducts
        .firstWhere((p) => p.id == production.productId);
    final progress = (production.progress * 100).toInt();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${product.emoji} ${product.name} x${production.quantity}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$progress%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            tween: Tween<double>(
              begin: 0,
              end: production.progress,
            ),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[600],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.orange[400]!,
                ),
                minHeight: 6,
              );
            },
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 12,
                color: Colors.white60,
              ),
              const SizedBox(width: 4),
              Text(
                _getRemainingTime(production),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRemainingTime(dynamic production) {
    final elapsed = DateTime.now().difference(production.startTime).inSeconds;
    final total = production.durationSeconds;
    final remaining = total - elapsed;
    
    if (remaining <= 0) return 'Completing...';
    
    if (remaining < 60) {
      return '${remaining}s left';
    } else if (remaining < 3600) {
      final minutes = (remaining / 60).floor();
      final seconds = remaining % 60;
      return '${minutes}m ${seconds}s left';
    } else {
      final hours = (remaining / 3600).floor();
      final minutes = ((remaining % 3600) / 60).floor();
      return '${hours}h ${minutes}m left';
    }
  }
}
