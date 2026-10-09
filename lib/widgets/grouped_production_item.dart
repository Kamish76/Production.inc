import 'package:flutter/material.dart';
import '../services/production_game_service.dart';
import 'production_status_panel.dart'; // For GroupedProduction class

/// Widget that displays a single grouped production item with progress
class GroupedProductionItem extends StatelessWidget {
  final GroupedProduction groupedProduction;
  final ProductionGameService gameService;

  const GroupedProductionItem({
    super.key,
    required this.groupedProduction,
    required this.gameService,
  });

  Color _getTierColor(String tierName) {
    switch (tierName) {
      case 'Basic Parts':
        return Colors.cyanAccent;
      case 'Intermediate':
        return Colors.amberAccent;
      case 'Complex':
        return Colors.purpleAccent;
      case 'Retail':
        return Colors.tealAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = gameService.getProduct(groupedProduction.productId);
    if (product == null) {
      return const SizedBox.shrink(); // Handle missing product gracefully
    }

    final progress = (groupedProduction.currentProgress * 100).toInt();
    final quantity = groupedProduction.quantity;
    final tierColor = _getTierColor(groupedProduction.tierName);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tierColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
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
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              if (groupedProduction.tierName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: tierColor.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    groupedProduction.tierName,
                    style: TextStyle(
                      color: tierColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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
          const SizedBox(height: 5),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            tween: Tween<double>(
              begin: 0,
              end: groupedProduction.currentProgress,
            ),
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                  minHeight: 6,
                ),
              );
            },
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.white60),
              const SizedBox(width: 4),
              Text(
                _getGroupedRemainingTime(groupedProduction),
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
              const Spacer(),
              // Throughput / Parallel Track info badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.amberAccent.withValues(alpha: 0.35),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 12, color: Colors.amberAccent),
                    const SizedBox(width: 3),
                    Text(
                      groupedProduction.queuedCount > 0
                          ? '${groupedProduction.activeCount} Active • ${groupedProduction.queuedCount} Queued (Lv.${groupedProduction.throughputLevel})'
                          : '${groupedProduction.activeCount} Active Parallel (Lv.${groupedProduction.throughputLevel})',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Calculate remaining time for grouped production (parallel-aware)
  String _getGroupedRemainingTime(GroupedProduction groupedProduction) {
    final remaining = groupedProduction.remainingSeconds.ceil();

    if (remaining <= 0) return 'Completing...';

    if (remaining < 60) {
      return '${remaining}s remaining';
    } else if (remaining < 3600) {
      final minutes = (remaining / 60).floor();
      final seconds = remaining % 60;
      return '${minutes}m ${seconds}s remaining';
    } else {
      final hours = (remaining / 3600).floor();
      final minutes = ((remaining % 3600) / 60).floor();
      return '${hours}h ${minutes}m remaining';
    }
  }
}
