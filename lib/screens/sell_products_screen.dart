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
                    gameService.state.products.values.every(
                      (count) => count == 0,
                    ))
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
                  // Products list - organized by tiers
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Build sections for each tier that has available products
                        ...gameService.productsByTier.entries
                            .map(
                              (entry) => _buildTierSection(
                                context,
                                gameService.getTierName(entry.key),
                                entry.value,
                                gameService,
                              ),
                            )
                            .where((widget) => widget != null)
                            .cast<Widget>(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget? _buildTierSection(
    BuildContext context,
    String tierName,
    List<game.Product> products,
    ProductionGameService gameService,
  ) {
    // Filter products to only show those we have in inventory
    final availableProducts =
        products
            .where(
              (product) => gameService.state.getProductCount(product.id) > 0,
            )
            .toList();

    if (availableProducts.isEmpty) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tier header
        Container(
          margin: const EdgeInsets.only(bottom: 12, top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.purple[900]!.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple[400]!.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(_getTierIcon(tierName), color: Colors.purple[400], size: 20),
              const SizedBox(width: 8),
              Text(
                tierName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[400],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple[400]!.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${availableProducts.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple[300],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Products in this tier
        ...availableProducts.map((product) {
          final available = gameService.state.getProductCount(product.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildProductCard(context, product, available, gameService),
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }

  IconData _getTierIcon(String tierName) {
    switch (tierName) {
      case 'Basic Parts':
        return Icons.construction;
      case 'Intermediate':
        return Icons.precision_manufacturing;
      case 'Complex':
        return Icons.smart_toy;
      case 'Retail':
        return Icons.storefront;
      default:
        return Icons.category;
    }
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
                Text(product.emoji, style: const TextStyle(fontSize: 32)),
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                      Text(
                        'Sell Price: \$${product.sellPrice.toStringAsFixed(2)} | Available: $available',
                        style: TextStyle(fontSize: 14, color: Colors.grey[300]),
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
                  _buildSellButton(
                    context,
                    product,
                    10,
                    gameService,
                    available,
                  ),
                _buildSellButton(
                  context,
                  product,
                  available,
                  gameService,
                  available,
                  label: 'Sell All',
                ),
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
      onPressed:
          canSell ? () => gameService.sellProduct(product.id, quantity) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canSell ? Colors.purple[600] : Colors.grey[600],
        foregroundColor: Colors.white,
      ),
      child: Text(
        '${label ?? 'Sell $quantity'}\n\$${revenue.toStringAsFixed(2)}',
      ),
    );
  }
}
