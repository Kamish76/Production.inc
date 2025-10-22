import 'package:flutter/material.dart';
import '../services/production_game_service.dart';
import 'grouped_production_item.dart';

/// Helper class for grouped production display
class GroupedProduction {
  final String productId;
  final int quantity;
  final double totalDuration;
  final double currentProgress; // Progress of the currently active item
  final bool isQueued;
  final DateTime earliestStartTime;

  GroupedProduction({
    required this.productId,
    required this.quantity,
    required this.totalDuration,
    required this.currentProgress,
    required this.isQueued,
    required this.earliestStartTime,
  });
}

/// Widget that displays active productions with collapsible expansion
class ProductionStatusPanel extends StatefulWidget {
  final ProductionGameService gameService;

  const ProductionStatusPanel({
    super.key,
    required this.gameService,
  });

  @override
  State<ProductionStatusPanel> createState() => _ProductionStatusPanelState();
}

class _ProductionStatusPanelState extends State<ProductionStatusPanel> {
  bool _isProductionExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.gameService.state.activeProductions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.orange[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isProductionExpanded = !_isProductionExpanded;
              });
            },
            child: Row(
              children: [
                const Text(
                  'Active Productions:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isProductionExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_isProductionExpanded)
            // Show all productions when expanded - Now grouped
            SizedBox(
              height: 200,
              child: Builder(
                builder: (context) {
                  final groupedProductions = _groupProductionTasks(
                    widget.gameService.state.activeProductions,
                  );
                  return ListView.builder(
                    itemCount: groupedProductions.length,
                    itemBuilder: (context, index) {
                      final groupedProduction = groupedProductions[index];
                      return GroupedProductionItem(
                        groupedProduction: groupedProduction,
                        gameService: widget.gameService,
                      );
                    },
                  );
                },
              ),
            )
          else
            // Show only the next production to finish when collapsed
            Builder(
              builder: (context) {
                // Check if there are any active productions
                if (widget.gameService.state.activeProductions.isEmpty) {
                  return const Text(
                    'No active productions',
                    style: TextStyle(color: Colors.white70),
                  );
                }

                // Group productions and find the one with highest progress
                final groupedProductions = _groupProductionTasks(
                  widget.gameService.state.activeProductions,
                );
                final nextGroupedProduction = groupedProductions.reduce(
                  (a, b) => a.currentProgress > b.currentProgress ? a : b,
                );
                return GroupedProductionItem(
                  groupedProduction: nextGroupedProduction,
                  gameService: widget.gameService,
                );
              },
            ),
        ],
      ),
    );
  }

  /// Group production tasks by product type for cleaner display
  List<GroupedProduction> _groupProductionTasks(List<dynamic> productions) {
    final Map<String, List<dynamic>> grouped = {};

    // Group by product ID
    for (final production in productions) {
      final productId = production.productId;
      grouped.putIfAbsent(productId, () => []).add(production);
    }

    // Convert to GroupedProduction objects
    return grouped.entries.map((entry) {
      final productId = entry.key;
      final tasks = entry.value;

      // Calculate consolidated information
      final quantity = tasks.length;
      final totalDuration = tasks.fold<double>(
        0,
        (sum, task) => sum + task.durationSeconds,
      );
      // Show progress of the currently active item (highest progress), not average
      final currentProgress = tasks
          .map((task) => task.progress)
          .reduce((a, b) => a > b ? a : b);
      final isQueued = tasks.any((task) => task.isQueued);
      final earliestStartTime = tasks
          .map((task) => task.startTime)
          .reduce((a, b) => a.isBefore(b) ? a : b);

      return GroupedProduction(
        productId: productId,
        quantity: quantity,
        totalDuration: totalDuration,
        currentProgress: currentProgress,
        isQueued: isQueued,
        earliestStartTime: earliestStartTime,
      );
    }).toList();
  }
}
