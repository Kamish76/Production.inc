import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;

import '../widgets/screen_header.dart';
import '../widgets/message_display.dart';
import '../widgets/order_card.dart';

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
                  title: 'Shipping Orders',
                  iconColor: Colors.orange[400]!,
                ),

                // Tab bar for Current and History
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TabBar(
                            indicator: BoxDecoration(
                              color: Colors.orange[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey[400],
                            tabs: const [
                              Tab(text: 'Current Orders'),
                              Tab(text: 'History'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildCurrentOrders(gameService),
                              _buildHistory(gameService),
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

  Widget _buildCurrentOrders(ProductionGameService gameService) {
    final activeOrders = gameService.state.activeShippingOrders;

    if (activeOrders.isEmpty) {
      return const Center(
        child: MessageDisplay.empty(
          icon: Icons.inventory_2_outlined,
          title: 'No Active Shipping Orders',
          subtitle: 'Sell products to create shipping orders!',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeOrders.length,
      itemBuilder: (context, index) {
        final order = activeOrders[index];
        return OrderCard.active(order: order);
      },
    );
  }

  Widget _buildHistory(ProductionGameService gameService) {
    final history = List<game.ShippingHistory>.from(
      gameService.state.shippingHistory.reversed,
    );

    if (history.isEmpty) {
      return const Center(
        child: MessageDisplay.empty(
          icon: Icons.history,
          title: 'No Shipping History',
          subtitle: 'Complete some orders to see history here!',
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
