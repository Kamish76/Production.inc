import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/production_game_service.dart';
import '../widgets/screen_header.dart';
import '../widgets/financial_status_display.dart';
import '../widgets/item_card.dart';

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
                ScreenHeader(
                  icon: Icons.shopping_cart,
                  title: 'Buy Materials',
                  iconColor: Colors.green[400]!,
                ),
                // Money display
                FinancialStatusDisplay(
                  gameService: gameService,
                  mode: FinancialDisplayMode.moneyOnly,
                ),

                // DEV MODE: Auto-Buy Machine Controls (v1.5.0)
                _buildAutoBuyDevControls(gameService),

                // Materials list with single-column layout for better readability
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: gameService.allMaterials.length,
                    itemBuilder: (context, index) {
                      final material = gameService.allMaterials[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ItemCard(
                          item: material,
                          gameService: gameService,
                          mode: ItemCardMode.buy,
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

  /// Build auto-buy machine dev controls (v1.5.0 - temporary for development)
  Widget _buildAutoBuyDevControls(ProductionGameService gameService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dev mode header
          Row(
            children: [
              Icon(Icons.construction, color: Colors.orange[400], size: 20),
              const SizedBox(width: 8),
              Text(
                'AUTO-BUY MACHINE (DEV MODE)',
                style: TextStyle(
                  color: Colors.orange[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Machine count controls
          Row(
            children: [
              const Text(
                'Machines:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(width: 12),
              
              // Decrement button
              IconButton(
                onPressed: gameService.state.autoBuyMachinesOwned > 0
                    ? gameService.decrementAutoBuyMachines
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red[400],
                disabledColor: Colors.grey,
                iconSize: 28,
              ),
              
              // Count display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${gameService.state.autoBuyMachinesOwned}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Increment button
              IconButton(
                onPressed: gameService.incrementAutoBuyMachines,
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.green[400],
                iconSize: 28,
              ),
              
              const Spacer(),
              
              // On/Off toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: gameService.state.autoBuyEnabled
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: gameService.state.autoBuyEnabled
                        ? Colors.green
                        : Colors.red,
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  onTap: gameService.state.autoBuyMachinesOwned > 0
                      ? gameService.toggleAutoBuy
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        gameService.state.autoBuyEnabled
                            ? Icons.power_settings_new
                            : Icons.power_off,
                        color: gameService.state.autoBuyEnabled
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        gameService.state.autoBuyEnabled ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: gameService.state.autoBuyEnabled
                              ? Colors.green
                              : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Info text
          if (gameService.state.autoBuyMachinesOwned > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Buying ${gameService.state.autoBuyMachinesOwned * 5} materials every 10s${gameService.state.autoBuyEnabled ? " (active)" : " (paused)"}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
