import 'package:flutter/material.dart';
import '../services/production_game_service.dart';

/// Card widget displaying the player's Logistics Fleet status and upgrade options
class FleetUpgradeCard extends StatelessWidget {
  final ProductionGameService gameService;

  const FleetUpgradeCard({super.key, required this.gameService});

  @override
  Widget build(BuildContext context) {
    final currentTier = gameService.currentFleetTier;
    final nextTier = gameService.nextFleetTier;
    final activeCount = gameService.state.activeShippingOrders.length;
    final maxSlots = currentTier.maxSimultaneousShipments;
    final canUpgrade = gameService.canUpgradeFleet;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orangeAccent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Current Vehicle & Tier
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(currentTier.emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Fleet Tier ${currentTier.tierNumber}: ${currentTier.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentTier.description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Stat Pills: Slots & Speed Boost
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131726),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: activeCount >= maxSlots
                          ? Colors.redAccent.withValues(alpha: 0.5)
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.route,
                        size: 16,
                        color: activeCount >= maxSlots ? Colors.redAccent : Colors.orangeAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dispatch Slots: $activeCount / $maxSlots',
                        style: TextStyle(
                          color: activeCount >= maxSlots ? Colors.redAccent : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131726),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.speed, size: 16, color: Colors.greenAccent),
                      const SizedBox(width: 6),
                      Text(
                        'Speed: ${(currentTier.speedMultiplier * 100).round()}% (${((currentTier.speedMultiplier - 1.0) * 100).round()}% boost)',
                        style: const TextStyle(
                          color: Colors.greenAccent,
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

          const SizedBox(height: 14),

          // Upgrade Section
          if (nextTier != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.orangeAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Text(nextTier.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next: ${nextTier.name}',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${nextTier.maxSimultaneousShipments} slots • ${(nextTier.speedMultiplier * 100).round()}% speed',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canUpgrade ? Colors.orange[600] : Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: canUpgrade
                        ? () async {
                            final success = await gameService.upgradeFleet();
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '🚚 Upgraded to ${nextTier.name}! Dispatch capacity expanded to ${nextTier.maxSimultaneousShipments} slots.',
                                  ),
                                  backgroundColor: Colors.orange[700],
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        : null,
                    child: Text(
                      canUpgrade
                          ? 'Upgrade (\$${nextTier.upgradeCost.toStringAsFixed(0)})'
                          : 'Need \$${(nextTier.upgradeCost - gameService.state.money).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Maximum Fleet Tier Acquired (Cargo Planes ✈️)',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
