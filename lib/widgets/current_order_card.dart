import 'package:flutter/material.dart';
import '../models/game_models.dart' as game;
import 'order_items_list.dart';

class CurrentOrderCard extends StatelessWidget {
  final game.ShippingOrder order;

  const CurrentOrderCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.orange[400], size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order #${order.id.substring(order.id.length - 6)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '\$${order.totalRevenue.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Order items
            OrderItemsList(items: order.items),

            const SizedBox(height: 12),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Shipping Progress',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    Text(
                      '${(order.progress * 100).toInt()}%',
                      style: TextStyle(fontSize: 14, color: Colors.orange[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: order.progress,
                  backgroundColor: Colors.grey[700],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.orange[400]!,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Time remaining: ${order.remainingTime.toStringAsFixed(1)}s',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}