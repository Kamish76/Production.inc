import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';
import '../services/production_game_service.dart';
import 'game_icon.dart';

/// Modal bottom sheet for inspecting, adjusting, and dispatching
/// the multi-product Commercial Dispatch Manifest (Bulk Sell Cart).
class ShippingManifestDrawer extends StatelessWidget {
  final ProductionGameService gameService;

  const ShippingManifestDrawer({
    super.key,
    required this.gameService,
  });

  /// Displays the drawer as a modal bottom sheet
  static Future<void> show(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShippingManifestDrawer(gameService: gameService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionGameService>(
      builder: (context, service, _) {
        final fleet = service.currentFleetTier;
        final staged = service.stagedManifest;
        final totalUnits = service.manifestTotalUnits;
        final varietyCount = service.manifestVarietyCount;
        final totalRevenue = service.manifestTotalRevenue;
        final shippingTime = service.calculateManifestShippingTime();
        final hasFleetSlot = service.state.canShipMore(
          service.state.activeShippingOrders.length,
        );

        final payloadProgress = fleet.maxPayloadUnits > 0
            ? (totalUnits / fleet.maxPayloadUnits).clamp(0.0, 1.0)
            : 0.0;

        Color progressColor;
        if (payloadProgress >= 1.0) {
          progressColor = Colors.orangeAccent;
        } else if (payloadProgress >= 0.75) {
          progressColor = Colors.amber;
        } else {
          progressColor = Colors.greenAccent;
        }

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF181B2C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.orange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shipping Manifest',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${fleet.name} • 1 Fleet Slot',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Capacity & Progress Bar Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22263D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Payload: $totalUnits / ${fleet.maxPayloadUnits} Units',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Varieties: $varietyCount / ${fleet.maxProductVarieties}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: payloadProgress,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 14, color: Colors.cyanAccent),
                              const SizedBox(width: 4),
                              Text(
                                'Transit: ${shippingTime.toStringAsFixed(1)}s',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasFleetSlot
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                size: 14,
                                color: hasFleetSlot
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasFleetSlot
                                    ? 'Fleet Slot Ready'
                                    : 'Fleet At Capacity',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hasFleetSlot
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white12, height: 16),

                // Itemized Manifest List
                Expanded(
                  child: staged.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Manifest is empty.\nAdd products from the Storefront to build a shipment.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          itemCount: staged.length,
                          separatorBuilder: (context, index) =>
                              const Divider(color: Colors.white10, height: 1),
                          itemBuilder: (context, index) {
                            final entry = staged.entries.elementAt(index);
                            final productId = entry.key;
                            final quantity = entry.value;

                            Product? product;
                            try {
                              product = GameData.products
                                  .firstWhere((p) => p.id == productId);
                            } catch (_) {}

                            final productName = product?.name ?? productId;
                            final productEmoji = product?.emoji ?? '📦';
                            final unitPrice = product?.sellPrice ?? 0.0;
                            final subtotal = unitPrice * quantity;
                            final stock = service.state.getProductCount(productId);

                            final canIncrement = quantity < stock &&
                                quantity < fleet.maxUnitsPerType &&
                                totalUnits < fleet.maxPayloadUnits;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  // Emoji & Info
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: GameIcon(
                                      itemId: productId,
                                      fallbackEmoji: productEmoji,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '\$${unitPrice.toStringAsFixed(2)} ea • Stock: $stock',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          '\$${subtotal.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.green[400],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Stepper Controls
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Decrement button
                                      _buildStepperButton(
                                        icon: Icons.remove,
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          service.updateManifestQuantity(
                                            productId,
                                            quantity - 1,
                                          );
                                        },
                                      ),
                                      // Quantity display
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        constraints:
                                            const BoxConstraints(minWidth: 32),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$quantity',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      // Increment button
                                      _buildStepperButton(
                                        icon: Icons.add,
                                        enabled: canIncrement,
                                        onPressed: canIncrement
                                            ? () {
                                                HapticFeedback.lightImpact();
                                                service.updateManifestQuantity(
                                                  productId,
                                                  quantity + 1,
                                                );
                                              }
                                            : null,
                                      ),
                                      const SizedBox(width: 4),
                                      // Max button
                                      InkWell(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          service.setManifestMaxForProduct(
                                            productId,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Colors.purple.withValues(
                                                alpha: 0.4,
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            'Max',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purpleAccent,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Remove button
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          service.removeFromManifest(productId);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const Divider(color: Colors.white12, height: 16),

                // Bottom Dispatch Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Clear button
                      TextButton.icon(
                        onPressed: staged.isEmpty
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                service.clearManifest();
                              },
                        icon: const Icon(Icons.delete_sweep,
                            size: 16, color: Colors.white54),
                        label: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dispatch button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (staged.isEmpty || !hasFleetSlot)
                              ? null
                              : () {
                                  HapticFeedback.mediumImpact();
                                  final scaffold = ScaffoldMessenger.of(context);
                                  final success = service.dispatchManifest(
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
                                    Navigator.pop(context);
                                    scaffold.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '🚚 Dispatched consolidated carrier! (Revenue: \$${totalRevenue.toStringAsFixed(2)})',
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            '🚚 Dispatch Carrier (\$${totalRevenue.toStringAsFixed(2)})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled ? Colors.white24 : Colors.white10,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? Colors.white : Colors.white24,
        ),
      ),
    );
  }
}
