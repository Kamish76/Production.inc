import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;

class SellProductsScreen extends StatelessWidget {
  const SellProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionGameService>(
      builder: (context, gameService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sell Products'),
            backgroundColor: Colors.purple[600],
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
                // Money and inventory display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Money: \$${gameService.state.money.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Current Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (gameService.state.products.isEmpty)
                        Text(
                          'No products to sell',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[300],
                          ),
                        )
                      else
                        ...gameService.allProducts.map((product) {
                          final count = gameService.state.getProductCount(product.id);
                          if (count > 0) {
                            return Text(
                              '${product.emoji} ${product.name}: $count',
                              style: const TextStyle(color: Colors.white),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                    ],
                  ),
                ),
                
                // Products to sell
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: gameService.allProducts.length,
                    itemBuilder: (context, index) {
                      final product = gameService.allProducts[index];
                      final available = gameService.state.getProductCount(product.id);
                      
                      return _buildProductCard(context, product, available, gameService);
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
    int available,
    ProductionGameService gameService,
  ) {
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
                        'Sell Price: \$${product.sellPrice.toStringAsFixed(2)} | Available: $available',
                        style: TextStyle(
                          fontSize: 14,
                          color: available > 0 ? Colors.green[300] : Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (available > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSellButton(context, product, 1, gameService, available),
                  if (available >= 5)
                    _buildSellButton(context, product, 5, gameService, available),
                  if (available >= 10)
                    _buildSellButton(context, product, 10, gameService, available),
                  _buildSellButton(context, product, available, gameService, available, label: 'All'),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No ${product.name.toLowerCase()}s available to sell',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSellButton(
    BuildContext context,
    game.Product product,
    int quantity,
    ProductionGameService gameService,
    int available, {
    String? label,
  }) {
    final canSell = available >= quantity;
    final revenue = product.sellPrice * quantity;
    
    return ElevatedButton(
      onPressed: canSell
          ? () => gameService.sellProduct(product.id, quantity)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canSell ? Colors.purple[600] : Colors.grey[600],
        foregroundColor: Colors.white,
      ),
      child: Text('${label ?? 'Sell $quantity'}\n\$${revenue.toStringAsFixed(2)}'),
    );
  }
}
