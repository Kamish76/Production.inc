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

                // Auto-Buy Machine Status Info (v1.5.0) - Now includes controls
                if (gameService.state.autoBuyMachinesOwned > 0)
                  _buildAutoBuyStatusWithControls(gameService),

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

  /// Build auto-buy machine status with embedded controls (v1.5.0)
  Widget _buildAutoBuyStatusWithControls(ProductionGameService gameService) {
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
          color: isActive ? Colors.green.withValues(alpha: 77) : Colors.grey.withValues(alpha: 77),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with On/Off toggle
          Row(
            children: [
              Icon(
                Icons.precision_manufacturing,
                color: isActive ? Colors.green[300] : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AUTO-BUY MACHINE',
                style: TextStyle(
                  color: isActive ? Colors.green[300] : Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              // On/Off toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withValues(alpha: 51)
                      : Colors.red.withValues(alpha: 51),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? Colors.green : Colors.red,
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  onTap: gameService.toggleAutoBuy,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.power_settings_new : Icons.power_off,
                        color: isActive ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.red,
                          fontSize: 12,
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

          // Status info grid
          Row(
            children: [
              // Machines count
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.settings_input_component,
                  label: 'Machines',
                  value: '${gameService.state.autoBuyMachinesOwned}',
                  valueColor: Colors.white,
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
          
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          
          // Capacity controls embedded in status
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: Colors.cyan[300],
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Capacity per Resource:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              
              // Decrement button
              IconButton(
                onPressed: gameService.state.autoBuyResourceCapacity > 10
                    ? gameService.decreaseAutoBuyCapacity
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red[400],
                disabledColor: Colors.grey,
                iconSize: 24,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              
              const SizedBox(width: 12),
              
              // Capacity display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 38),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.cyan.withValues(alpha: 77),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '${gameService.state.autoBuyResourceCapacity}',
                  style: TextStyle(
                    color: Colors.cyan[300],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Increment button
              IconButton(
                onPressed: gameService.increaseAutoBuyCapacity,
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.green[400],
                iconSize: 24,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          // Info text
          const SizedBox(height: 8),
          Text(
            'Buying ${gameService.state.autoBuyMachinesOwned * 5} materials every 5s${isActive ? " (active)" : " (paused)"}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 128),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
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
