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
                        Icons.attach_money,
                        color: Colors.purple[400],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Sell Products',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
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
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Products: ${gameService.state.products.values.fold(0, (sum, count) => sum + count)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Products inventory
                if (gameService.state.products.isEmpty || 
                    gameService.state.products.values.every((count) => count == 0))
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Products to Sell',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Build some products first to sell them here!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Products list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: gameService.allProducts.length,
                      itemBuilder: (context, index) {
                        final product = gameService.allProducts[index];
                        final available = gameService.state.getProductCount(product.id);
                        
                        if (available <= 0) return const SizedBox.shrink();
                        
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
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Sell buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSellButton(context, product, 1, gameService, available),
                if (available >= 5)
                  _buildSellButton(context, product, 5, gameService, available),
                if (available >= 10) 
                  _buildSellButton(context, product, 10, gameService, available),
                _buildSellButton(context, product, available, gameService, available, 
                    label: 'Sell All'),
              ],
            ),
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
