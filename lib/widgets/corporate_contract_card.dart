import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../models/game_data.dart';
import '../services/production_game_service.dart';

/// Card widget representing an individual B2B Corporate Contract
class CorporateContractCard extends StatelessWidget {
  final CorporateContract contract;
  final ProductionGameService gameService;

  const CorporateContractCard({
    super.key,
    required this.contract,
    required this.gameService,
  });

  @override
  Widget build(BuildContext context) {
    final client = GameData.getCorporateClient(contract.clientId);
    final clientColor = client != null
        ? Color(client.primaryColorHex)
        : Colors.cyanAccent;

    final isRetail = contract.contractType == ContractType.retail;
    final isCompleted = contract.status == ContractStatus.completed;
    final isShipping = contract.status == ContractStatus.shipping;

    final hasStock = contract.canFulfill(gameService.state.products);
    final hasFleetCapacity = gameService.state.canShipMore(
      gameService.state.activeShippingOrders.length,
    );
    final canShip = hasStock &&
        hasFleetCapacity &&
        !contract.isExpired &&
        !isShipping &&
        !isCompleted;

    final remaining = contract.remainingDuration;
    final remainingText = contract.isExpired
        ? 'Expired'
        : (remaining.inMinutes > 0
            ? '${remaining.inMinutes}m remaining'
            : '${remaining.inSeconds}s remaining');

    Color borderColor;
    if (isCompleted) {
      borderColor = Colors.greenAccent.withValues(alpha: 0.6);
    } else if (isShipping) {
      borderColor = Colors.cyanAccent.withValues(alpha: 0.6);
    } else {
      borderColor = clientColor.withValues(alpha: 0.35);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Client & Expiration
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: clientColor.withValues(alpha: 0.12),
              child: Row(
                children: [
                  Text(client?.emoji ?? '🏢', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                client?.name ?? 'Corporate Partner',
                                style: TextStyle(
                                  color: clientColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isRetail
                                    ? Colors.blue.withValues(alpha: 0.2)
                                    : Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isRetail
                                      ? Colors.lightBlueAccent.withValues(alpha: 0.6)
                                      : Colors.amberAccent.withValues(alpha: 0.6),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isRetail ? '🏷️ RETAIL' : '🏭 MANUFACTURING',
                                style: TextStyle(
                                  color: isRetail
                                      ? Colors.lightBlueAccent
                                      : Colors.amberAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          contract.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withValues(alpha: 0.2)
                          : (isShipping
                              ? Colors.cyan.withValues(alpha: 0.2)
                              : (contract.isExpired
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : Colors.orange.withValues(alpha: 0.2))),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted
                            ? Colors.greenAccent.withValues(alpha: 0.5)
                            : (isShipping
                                ? Colors.cyanAccent.withValues(alpha: 0.5)
                                : (contract.isExpired
                                    ? Colors.redAccent.withValues(alpha: 0.5)
                                    : Colors.orangeAccent.withValues(alpha: 0.5))),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : (isShipping
                                  ? Icons.local_shipping
                                  : (contract.isExpired
                                      ? Icons.timer_off_outlined
                                      : Icons.timer_outlined)),
                          size: 12,
                          color: isCompleted
                              ? Colors.greenAccent
                              : (isShipping
                                  ? Colors.cyanAccent
                                  : (contract.isExpired
                                      ? Colors.redAccent
                                      : Colors.orangeAccent)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCompleted
                              ? 'Fulfilled'
                              : (isShipping
                                  ? 'In Transit'
                                  : remainingText),
                          style: TextStyle(
                            color: isCompleted
                                ? Colors.greenAccent
                                : (isShipping
                                    ? Colors.cyanAccent
                                    : (contract.isExpired
                                        ? Colors.redAccent
                                        : Colors.orangeAccent)),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Required Products Section (B4)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Required Products (${contract.totalRequiredUnits} units total):',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Required Products List (B4)
                  ...contract.requiredProducts.entries.map((entry) {
                    final productId = entry.key;
                    final requiredQty = entry.value;
                    final prod = GameData.getProduct(productId);
                    final inStock = gameService.state.getProductCount(productId);
                    final hasEnough = inStock >= requiredQty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131726),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasEnough
                              ? Colors.greenAccent.withValues(alpha: 0.25)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              prod?.emoji ?? '📦',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prod?.name ?? productId,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Warehouse: $inStock / $requiredQty',
                                  style: TextStyle(
                                    color: hasEnough
                                        ? Colors.greenAccent
                                        : (inStock > 0
                                            ? Colors.amberAccent
                                            : Colors.white38),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: hasEnough
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: hasEnough
                                    ? Colors.greenAccent.withValues(alpha: 0.3)
                                    : Colors.white12,
                              ),
                            ),
                            child: Text(
                              '$requiredQty units',
                              style: TextStyle(
                                color: hasEnough
                                    ? Colors.greenAccent
                                    : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 10),

                  // Rewards & Actions Row (B5)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reward summary
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.greenAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  color: Colors.greenAccent,
                                  size: 14,
                                ),
                                Text(
                                  '\$${contract.cashReward.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.purpleAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.purpleAccent,
                                  size: 14,
                                ),
                                Text(
                                  '+${contract.repReward} Rep',
                                  style: const TextStyle(
                                    color: Colors.purpleAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Action Button (B5)
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.greenAccent),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check,
                                color: Colors.greenAccent,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Honored',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (contract.status == ContractStatus.shipping)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.cyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.cyanAccent),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_shipping,
                                color: Colors.cyanAccent,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'In Transit',
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canShip ? Colors.orange[600] : Colors.grey[800],
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white12,
                            disabledForegroundColor: Colors.white38,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          onPressed: canShip
                              ? () {
                                  final success =
                                      gameService.shipContract(contract.id);
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '🚚 Dispatched ${contract.title}! Shipment underway.',
                                        ),
                                        backgroundColor: Colors.orange[800],
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          child: Text(
                            !hasStock
                                ? 'Need Stock'
                                : (!hasFleetCapacity
                                    ? 'Fleet Full'
                                    : (contract.isExpired
                                        ? 'Expired'
                                        : 'Ship Contract 🚚')),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
