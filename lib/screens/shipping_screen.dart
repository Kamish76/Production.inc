import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;

import '../widgets/screen_header.dart';
import '../widgets/message_display.dart';
import '../widgets/order_card.dart';
import '../widgets/fleet_upgrade_card.dart';

/// Phase 2: Upgraded Commercial Dispatch & B2B Logistics Center
class ShippingScreen extends StatelessWidget {
  const ShippingScreen({super.key});

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
                  icon: Icons.local_shipping,
                  title: 'Logistics & Dispatch Center',
                  iconColor: Colors.orange[400]!,
                ),

                // Tab bar for Fleet Dispatch and History
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2438),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: TabBar(
                            indicator: BoxDecoration(
                              color: Colors.orange[600],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey[400],
                            indicatorSize: TabBarIndicatorSize.tab,
                            tabs: const [
                              Tab(
                                icon: Icon(Icons.local_shipping_outlined, size: 18),
                                text: 'Fleet Dispatch',
                              ),
                              Tab(
                                icon: Icon(Icons.history, size: 18),
                                text: 'History',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildFleetDispatchTab(gameService),
                              _buildHistoryTab(gameService),
                            ],
                          ),
                        ),
                      ],
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

  /// Tab 1: Logistics Fleet Status & Active Shipments
  Widget _buildFleetDispatchTab(ProductionGameService gameService) {
    final activeOrders = gameService.state.activeShippingOrders;
    final currentTier = gameService.currentFleetTier;
    final maxSlots = currentTier.maxSimultaneousShipments;
    final isAtCapacity = activeOrders.length >= maxSlots;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Logistics Fleet Upgrade & Overview Card
        FleetUpgradeCard(gameService: gameService),

        // Section Title: Active Shipments
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
          child: Row(
            children: [
              Icon(
                Icons.local_shipping,
                color: isAtCapacity ? Colors.redAccent : Colors.orangeAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Active Dispatches (${activeOrders.length} / $maxSlots)',
                style: TextStyle(
                  color: isAtCapacity ? Colors.redAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (isAtCapacity) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FULL',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        if (activeOrders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: MessageDisplay.empty(
              icon: Icons.inventory_2_outlined,
              title: 'Fleet Couriers Idle',
              subtitle: 'Sell products in the warehouse or dispatch orders to start shipping!',
            ),
          )
        else
          ...activeOrders.map((order) {
            final card = OrderCard.active(order: order);
            if (order.contractId == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: card,
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      '📋 B2B Contract',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  card,
                ],
              ),
            );
          }),
      ],
    );
  }

  /// Tab 2: Combined Shipping & Contract History
  Widget _buildHistoryTab(ProductionGameService gameService) {
    final history = List<game.ShippingHistory>.from(
      gameService.state.shippingHistory.reversed,
    );

    if (history.isEmpty) {
      return const Center(
        child: MessageDisplay.empty(
          icon: Icons.history,
          title: 'No Shipping History',
          subtitle: 'Complete deliveries or corporate contracts to see history here!',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final record = history[index];
        return OrderCard.completed(record: record);
      },
    );
  }
}
