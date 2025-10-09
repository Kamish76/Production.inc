import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/production_game_service.dart';
import '../widgets/screen_header.dart';
import '../widgets/financial_status_display.dart';
import '../widgets/item_card.dart';

class BuyMaterialsScreen extends StatefulWidget {
  const BuyMaterialsScreen({super.key});

  @override
  State<BuyMaterialsScreen> createState() => _BuyMaterialsScreenState();
}

class _BuyMaterialsScreenState extends State<BuyMaterialsScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Start a timer to update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Trigger rebuild for countdown
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

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

                // Auto-Buy Machine Status Info (v1.5.0)
                if (gameService.state.autoBuyMachinesOwned > 0)
                  _buildAutoBuyStatusInfo(gameService),

                // Materials list with single-column layout for better readability
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: gameService.allMaterials.length,
                    itemBuilder: (context, index) {
                      final material = gameService.allMaterials[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
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
          
          const SizedBox(height: 12),

          // Capacity controls
          Row(
            children: [
              const Text(
                'Capacity:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(width: 12),
              
              // Decrement button
              IconButton(
                onPressed: gameService.state.autoBuyResourceCapacity > 10
                    ? gameService.decreaseAutoBuyCapacity
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red[400],
                disabledColor: Colors.grey,
                iconSize: 28,
              ),
              
              // Capacity display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${gameService.state.autoBuyResourceCapacity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Increment button
              IconButton(
                onPressed: gameService.increaseAutoBuyCapacity,
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.green[400],
                iconSize: 28,
              ),
              
              const SizedBox(width: 8),
              
              // Info text
              Expanded(
                child: Text(
                  'per resource',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          
          // Info text
          if (gameService.state.autoBuyMachinesOwned > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Buying ${gameService.state.autoBuyMachinesOwned * 5} materials every 5s${gameService.state.autoBuyEnabled ? " (active)" : " (paused)"}',
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

  /// Build auto-buy machine status info display (v1.5.0)
  Widget _buildAutoBuyStatusInfo(ProductionGameService gameService) {
    final secondsRemaining = gameService.getSecondsUntilNextAutoBuyTick();
    final nextMaterial = gameService.getNextMaterialToBuy();
    final isActive = gameService.state.autoBuyEnabled;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isActive ? Colors.green[300] : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'AUTO-BUY STATUS',
                style: TextStyle(
                  color: isActive ? Colors.green[300] : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status info grid
          Row(
            children: [
              // Machines count
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.precision_manufacturing,
                  label: 'Machines',
                  value: '${gameService.state.autoBuyMachinesOwned}',
                  valueColor: Colors.white,
                ),
              ),
              
              // Capacity
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Capacity',
                  value: '${gameService.state.autoBuyResourceCapacity}',
                  valueColor: Colors.cyan[300]!,
                ),
              ),
              
              // Next tick countdown
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.timer_outlined,
                  label: 'Next Tick',
                  value: isActive
                      ? (secondsRemaining != null ? '${secondsRemaining}s' : '--')
                      : 'Paused',
                  valueColor: isActive
                      ? (secondsRemaining != null && secondsRemaining <= 2
                          ? Colors.orange
                          : Colors.green[300]!)
                      : Colors.grey,
                ),
              ),
              
              // Current/next material
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.shopping_basket_outlined,
                  label: 'Buying',
                  value: isActive ? (nextMaterial ?? '--') : 'Paused',
                  valueColor: isActive ? Colors.blue[300]! : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a single status item
  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
