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
    final product = GameData.getProduct(contract.targetProductId);
    final clientColor = client != null
        ? Color(client.primaryColorHex)
        : Colors.cyanAccent;

    final inStock = gameService.state.getProductCount(contract.targetProductId);
    final needed = contract.requiredQuantity - contract.deliveredQuantity;
    final canDeliverSome = inStock > 0 && needed > 0;
    final canFulfillAll = inStock >= needed && needed > 0;

    final remaining = contract.remainingDuration;
    final remainingText = remaining.inMinutes > 0
        ? '${remaining.inMinutes}m remaining'
        : '${remaining.inSeconds}s remaining';

    final isCompleted = contract.status == ContractStatus.completed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.greenAccent.withValues(alpha: 0.6)
              : clientColor.withValues(alpha: 0.35),
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
                        Text(
                          client?.name ?? 'Corporate Partner',
                          style: TextStyle(
                            color: clientColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted
                            ? Colors.greenAccent.withValues(alpha: 0.5)
                            : Colors.orangeAccent.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted ? Icons.check_circle : Icons.timer_outlined,
                          size: 12,
                          color: isCompleted ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCompleted ? 'Fulfilled' : remainingText,
                          style: TextStyle(
                            color: isCompleted ? Colors.greenAccent : Colors.orangeAccent,
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
                  // Requested Product Information
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131726),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          product?.emoji ?? '📦',
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product?.name ?? contract.targetProductId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Target: ${contract.requiredQuantity} units (${contract.deliveredQuantity} delivered)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'In Warehouse: $inStock units available',
                              style: TextStyle(
                                color: inStock >= needed
                                    ? Colors.greenAccent
                                    : (inStock > 0 ? Colors.amberAccent : Colors.white38),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: contract.progress,
                      minHeight: 8,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? Colors.greenAccent : clientColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Rewards & Actions
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

                      // Action Button
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
                      else if (contract.status == ContractStatus.available && !canDeliverSome)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: clientColor.withValues(alpha: 0.2),
                            foregroundColor: clientColor,
                            side: BorderSide(color: clientColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            gameService.acceptContract(contract.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Accepted ${contract.title}! Deliver units before timeout.'),
                                backgroundColor: clientColor,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Accept'),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canFulfillAll ? Colors.green[600] : Colors.orange[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: canDeliverSome
                              ? () {
                                  final success = gameService.fulfillContract(contract.id);
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          canFulfillAll
                                              ? '🎉 Contract Completed! Received \$${contract.cashReward.toStringAsFixed(0)} & +${contract.repReward} Rep!'
                                              : 'Delivered $inStock units to contract!',
                                        ),
                                        backgroundColor: canFulfillAll ? Colors.green : Colors.orange,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          icon: Icon(
                            canFulfillAll ? Icons.done_all : Icons.local_shipping,
                            size: 16,
                          ),
                          label: Text(
                            canFulfillAll
                                ? 'Fulfill All'
                                : (canDeliverSome ? 'Deliver ($inStock)' : 'Need Goods'),
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
