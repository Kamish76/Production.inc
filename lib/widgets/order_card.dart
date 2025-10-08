import 'package:flutter/material.dart';
import '../models/game_models.dart' as game;
import 'order_items_list.dart';

enum OrderStatus {
  active,
  completed,
}

/// Universal order card widget that handles both current and historical orders
class OrderCard extends StatelessWidget {
  final String orderId;
  final double totalRevenue;
  final List<game.ShippingItem> items;
  final OrderStatus status;
  final double? progress;
  final double? remainingTime;
  final DateTime? completedTime;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.totalRevenue,
    required this.items,
    required this.status,
    this.progress,
    this.remainingTime,
    this.completedTime,
  });

  /// Constructor for active orders
  OrderCard.active({
    super.key,
    required game.ShippingOrder order,
  })  : orderId = order.id,
        totalRevenue = order.totalRevenue,
        items = order.items,
        status = OrderStatus.active,
        progress = order.progress,
        remainingTime = order.remainingTime,
        completedTime = null;

  /// Constructor for completed orders
  OrderCard.completed({
    super.key,
    required game.ShippingHistory record,
  })  : orderId = record.id,
        totalRevenue = record.totalRevenue,
        items = record.items,
        status = OrderStatus.completed,
        progress = null,
        remainingTime = null,
        completedTime = record.completedTime;

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
                Icon(
                  status == OrderStatus.active ? Icons.local_shipping : Icons.check_circle,
                  color: status == OrderStatus.active ? Colors.orange[400] : Colors.green[400],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order #${orderId.substring(orderId.length - 6)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '\$${totalRevenue.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[400],
                  ),
                ),
              ],
            ),
            
            // Completion time for completed orders
            if (status == OrderStatus.completed && completedTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Completed: ${_formatDateTime(completedTime!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],

            const SizedBox(height: 12),

            // Order items
            OrderItemsList(
              items: items,
              fontSize: 14,
              emojiSize: status == OrderStatus.active ? 20 : 16,
              verticalPadding: status == OrderStatus.active ? 4 : 2,
            ),

            // Progress section for active orders
            if (status == OrderStatus.active && progress != null && remainingTime != null) ...[
              const SizedBox(height: 12),
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
                        '${(progress! * 100).toInt()}%',
                        style: TextStyle(fontSize: 14, color: Colors.orange[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[700],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.orange[400]!,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time remaining: ${remainingTime!.toStringAsFixed(1)}s',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}