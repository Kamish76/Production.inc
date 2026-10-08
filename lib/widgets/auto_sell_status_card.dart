import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auto_sell_preview.dart';
import '../services/production_game_service.dart';
import 'auto_sell_setup_sheet.dart';

/// Compact live status banner placed at the top of the Storefront tab.
/// Displays master on/off switch, owned machines/speed, live queue ticker,
/// and quick access to the Selling Automation Setup sheet.
class AutoSellStatusCard extends StatelessWidget {
  final VoidCallback? onOpenSetup;

  const AutoSellStatusCard({
    super.key,
    this.onOpenSetup,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionGameService>(
      builder: (context, gameService, _) {
        final state = gameService.state;
        final machinesOwned = state.autoSellMachinesOwned;
        final isEnabled = state.autoSellEnabled && machinesOwned > 0;
        final nextAction = gameService.getAutoSellNextAction();

        Color statusColor;
        IconData actionIcon;
        String actionBadgeText;

        switch (nextAction.actionType) {
          case AutoSellActionType.b2bContract:
            statusColor = Colors.orangeAccent;
            actionIcon = Icons.handshake_outlined;
            actionBadgeText = 'B2B Contract';
            break;
          case AutoSellActionType.batchDispatch:
            statusColor = Colors.purpleAccent;
            actionIcon = Icons.inventory_2_outlined;
            actionBadgeText = 'Batch Dispatch';
            break;
          case AutoSellActionType.waitingStock:
            statusColor = Colors.amberAccent;
            actionIcon = Icons.hourglass_empty;
            actionBadgeText = 'Waiting Stock';
            break;
          case AutoSellActionType.waitingFleet:
            statusColor = Colors.blueAccent;
            actionIcon = Icons.local_shipping_outlined;
            actionBadgeText = 'Couriers Busy';
            break;
          case AutoSellActionType.idleDisabled:
            statusColor = Colors.white38;
            actionIcon = Icons.pause_circle_outline;
            actionBadgeText = 'Paused';
            break;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF22263C),
                isEnabled
                    ? const Color(0xFF1E2135)
                    : const Color(0xFF191B2A),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEnabled
                  ? Colors.purple.withValues(alpha: 0.35)
                  : Colors.white12,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Machine status & Master switch
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? Colors.purple.withValues(alpha: 0.2)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isEnabled
                            ? Colors.purple.withValues(alpha: 0.4)
                            : Colors.white12,
                      ),
                    ),
                    child: Icon(
                      Icons.smart_toy_outlined,
                      color: isEnabled ? Colors.purpleAccent : Colors.white38,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Flexible(
                              child: Text(
                                'Auto-Sell Dispatcher',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Machines owned badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: machinesOwned > 0
                                    ? Colors.purple.withValues(alpha: 0.25)
                                    : Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$machinesOwned Active',
                                style: TextStyle(
                                  color: machinesOwned > 0
                                      ? Colors.purple[200]
                                      : Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          machinesOwned <= 0
                              ? 'Get dispatchers in Machines tab to automate sales'
                              : 'Speed: ${state.autoSellThroughputLevel}x  •  ${state.autoSellWhitelistedProductIds.length} whitelisted items',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Master switch
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isEnabled,
                      activeThumbColor: Colors.purpleAccent,
                      activeTrackColor: Colors.purple.withValues(alpha: 0.4),
                      inactiveThumbColor: Colors.white38,
                      inactiveTrackColor: Colors.white10,
                      onChanged: machinesOwned > 0
                          ? (_) => gameService.toggleAutoSell()
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 8),

              // Bottom row: Live Queue ticker & Setup button
              Row(
                children: [
                  // Next action ticker
                  Expanded(
                    child: InkWell(
                      onTap: onOpenSetup ?? () => AutoSellSetupSheet.show(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(actionIcon, size: 12, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    actionBadgeText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                nextAction.isReady && nextAction.estimatedRevenue > 0
                                    ? '${nextAction.title} (+\$${nextAction.estimatedRevenue.toStringAsFixed(0)})'
                                    : nextAction.subtitle,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Setup button
                  InkWell(
                    onTap: onOpenSetup ?? () => AutoSellSetupSheet.show(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune,
                            size: 13,
                            color: Colors.purple[200],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Setup',
                            style: TextStyle(
                              color: Colors.purple[100],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
