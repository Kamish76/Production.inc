import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;

class BuyMaterialsScreen extends StatelessWidget {
  const BuyMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionGameService>(
      builder: (context, gameService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Buy Materials'),
            backgroundColor: Colors.green[600],
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
                
                // Materials list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: gameService.allMaterials.length,
                    itemBuilder: (context, index) {
                      final material = gameService.allMaterials[index];
                      final owned = gameService.state.getMaterialCount(material.id);
                      
                      return _buildMaterialCard(context, material, owned, gameService);
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

  Widget _buildMaterialCard(
    BuildContext context,
    game.Material material,
    int owned,
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
                  material.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        material.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                      Text(
                        'Price: \$${material.buyPrice.toStringAsFixed(2)} | Owned: $owned',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBuyButton(context, material, 1, gameService),
                _buildBuyButton(context, material, 5, gameService),
                _buildBuyButton(context, material, 10, gameService),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyButton(
    BuildContext context,
    game.Material material,
    int quantity,
    ProductionGameService gameService,
  ) {
    final cost = material.buyPrice * quantity;
    final canAfford = gameService.state.canAfford(cost);
    
    return ElevatedButton(
      onPressed: canAfford
          ? () => gameService.buyMaterial(material.id, quantity)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford ? Colors.green[600] : Colors.grey[600],
        foregroundColor: Colors.white,
      ),
      child: Text('Buy $quantity\n\$${cost.toStringAsFixed(2)}'),
    );
  }
}
