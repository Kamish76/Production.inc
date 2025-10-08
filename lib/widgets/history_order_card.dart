import 'package:flutter/material.dart';
import '../models/game_models.dart' as game;
import 'order_items_list.dart';

class HistoryOrderCard extends StatelessWidget {
  final game.ShippingHistory record;

  const HistoryOrderCard({
    super.key,
    required this.record,
  });

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

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
                Icon(Icons.check_circle, color: Colors.green[400], size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order #${record.id.substring(record.id.length - 6)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '\$${record.totalRevenue.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Completion time
            Text(
              'Completed: ${_formatDateTime(record.completedTime)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),

            const SizedBox(height: 12),

            // Order items
            OrderItemsList(
              items: record.items,
              fontSize: 14,
              emojiSize: 16,
              verticalPadding: 2,
            ),
          ],
        ),
      ),
    );
  }
}