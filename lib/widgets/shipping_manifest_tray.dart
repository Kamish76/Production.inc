import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/production_game_service.dart';
import 'shipping_manifest_drawer.dart';

/// Docked bottom bar that appears on the Sell Products Screen (Storefront)
/// whenever there are products staged in the Commercial Dispatch Manifest.
class ShippingManifestTray extends StatelessWidget {
  const ShippingManifestTray({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionGameService>(
      builder: (context, gameService, _) {
        final staged = gameService.stagedManifest;
        if (staged.isEmpty) {
          return const SizedBox.shrink();
        }

        final fleet = gameService.currentFleetTier;
        final totalUnits = gameService.manifestTotalUnits;
        final varietyCount = gameService.manifestVarietyCount;
        final totalRevenue = gameService.manifestTotalRevenue;
        final shippingTime = gameService.calculateManifestShippingTime();
        final hasFleetSlot = gameService.state.canShipMore(
          gameService.state.activeShippingOrders.length,
        );

        final isNearCapacity = totalUnits >= fleet.maxPayloadUnits * 0.8;
        final isAtCapacity = totalUnits >= fleet.maxPayloadUnits;

        Color badgeColor = Colors.greenAccent;
        if (isAtCapacity) {
          badgeColor = Colors.orangeAccent;
        } else if (isNearCapacity) {
          badgeColor = Colors.amber;
        }

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF222842), Color(0xFF181B2E)],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.purple[400]!.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Manifest summary statistics
                Expanded(
                  child: InkWell(
                    onTap: () => ShippingManifestDrawer.show(context, gameService),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                '📦 $varietyCount Var • $totalUnits/${fleet.maxPayloadUnits} Units',
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.purple.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  '${fleet.emoji} ${fleet.name}',
                                  style: const TextStyle(
                                    color: Colors.purpleAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total: \$${totalRevenue.toStringAsFixed(2)} • ⏱️ ${shippingTime.toStringAsFixed(1)}s',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Review button
                OutlinedButton(
                  onPressed: () =>
                      ShippingManifestDrawer.show(context, gameService),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Review', style: TextStyle(fontSize: 12)),
                ),

                const SizedBox(width: 8),

                // One-tap Dispatch button
                ElevatedButton(
                  onPressed: !hasFleetSlot
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          final scaffold = ScaffoldMessenger.of(context);
                          final success = gameService.dispatchManifest(
                            onStockAdjusted: (msg) {
                              scaffold.showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                  backgroundColor: Colors.orange[800],
                                ),
                              );
                            },
                          );

                          if (success) {
                            scaffold.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '🚚 Dispatched consolidated carrier! (\$${totalRevenue.toStringAsFixed(2)})',
                                ),
                                backgroundColor: Colors.green[800],
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[800],
                    disabledForegroundColor: Colors.white30,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    hasFleetSlot ? '🚚 Dispatch' : 'Fleet Full',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
