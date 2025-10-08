import 'package:flutter/material.dart';
import '../services/production_game_service.dart';
import 'production_status_panel.dart'; // For GroupedProduction class

/// Widget that displays a single grouped production item with progress
class GroupedProductionItem extends StatelessWidget {
  final GroupedProduction groupedProduction;
  final ProductionGameService gameService;

  const GroupedProductionItem({
    Key? key,
    required this.groupedProduction,
    required this.gameService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = gameService.getProduct(groupedProduction.productId);
    if (product == null) {
      return const SizedBox.shrink(); // Handle missing product gracefully
    }

    final progress = (groupedProduction.currentProgress * 100).toInt();
    final quantity = groupedProduction.quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${product.emoji} ${product.name} x$quantity',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$progress%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            tween: Tween<double>(
              begin: 0,
              end: groupedProduction.currentProgress,
            ),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[600],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[400]!),
                minHeight: 6,
              );
            },
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.white60),
              const SizedBox(width: 4),
              Text(
                _getGroupedRemainingTime(groupedProduction),
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Calculate remaining time for grouped production
  String _getGroupedRemainingTime(GroupedProduction groupedProduction) {
    final now = DateTime.now();
    final elapsed =
        now.difference(groupedProduction.earliestStartTime).inSeconds;
    final totalSeconds = groupedProduction.totalDuration;
    final remaining = (totalSeconds - elapsed).round();

    if (remaining <= 0) return 'Completing...';

    if (remaining < 60) {
      return '${remaining}s total';
    } else if (remaining < 3600) {
      final minutes = (remaining / 60).floor();
      final seconds = remaining % 60;
      return '${minutes}m ${seconds}s total';
    } else {
      final hours = (remaining / 3600).floor();
      final minutes = ((remaining % 3600) / 60).floor();
      return '${hours}h ${minutes}m total';
    }
  }
}
