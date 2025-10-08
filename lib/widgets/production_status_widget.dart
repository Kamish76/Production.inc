import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../models/game_state.dart';
import '../models/game_data.dart';
import 'common_widgets.dart';

/// Production status display widget for showing active productions
///
/// This widget provides a consistent way to display production progress
/// across different screens with grouping support and progress indicators.
class ProductionStatusWidget extends StatelessWidget {
  final List<ProductionTask> productions;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;
  final String title;

  const ProductionStatusWidget({
    super.key,
    required this.productions,
    required this.isExpanded,
    this.onToggleExpanded,
    this.title = 'Active Productions',
  });

  @override
  Widget build(BuildContext context) {
    if (productions.isEmpty) {
      return const SizedBox.shrink();
    }

    return GameCard(
      backgroundColor: AppColors.productionActive.withValues(alpha: 0.1),
      showBorder: true,
      borderColor: AppColors.productionActive.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: UIConstants.standardSpacing),
          if (isExpanded) _buildExpandedView() else _buildCollapsedView(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: onToggleExpanded,
      child: Row(
        children: [
          const Icon(Icons.build_circle, color: AppColors.productionActive, size: 20),
          const SizedBox(width: UIConstants.standardSpacing),
          Expanded(
            child: Text(
              '$title (${productions.length})',
              style: const TextStyle(
                fontSize: TypographyConstants.productNameSize + 2,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (onToggleExpanded != null)
            AnimatedExpandIcon(
              isExpanded: isExpanded,
              onTap: onToggleExpanded,
              color: AppColors.productionActive,
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    final groupedProductions = _groupProductionTasks(productions);

    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: groupedProductions.length,
        itemBuilder: (context, index) {
          final groupedProduction = groupedProductions[index];
          return _buildGroupedProductionItem(groupedProduction);
        },
      ),
    );
  }

  Widget _buildCollapsedView() {
    // Show the production with highest progress
    final groupedProductions = _groupProductionTasks(productions);
    if (groupedProductions.isEmpty) {
      return const Text(
        'No active productions',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    final nextProduction = groupedProductions.reduce(
      (a, b) => a.currentProgress > b.currentProgress ? a : b,
    );

    return _buildGroupedProductionItem(nextProduction);
  }

  Widget _buildGroupedProductionItem(GroupedProduction groupedProduction) {
    final product = GameData.products.firstWhere(
      (p) => p.id == groupedProduction.productId,
    );

    final timeRemaining =
        groupedProduction.totalDuration *
        (1 - groupedProduction.currentProgress);
    final timeRemainingText =
        timeRemaining > 0
            ? '${timeRemaining.ceil()}s remaining'
            : 'Completing...';

    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.standardSpacing),
      child: GameCard(
        backgroundColor: AppColors.cardBackground,
        padding: const EdgeInsets.all(UIConstants.standardSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (product.emoji.isNotEmpty) ...[
                  Text(product.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: UIConstants.standardSpacing),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: TypographyConstants.productNameSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (groupedProduction.quantity > 1) ...[
                        Text(
                          'Quantity: ${groupedProduction.quantity}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: TypographyConstants.statusIndicatorSize,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeRemainingText,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: TypographyConstants.statusIndicatorSize,
                      ),
                    ),
                    Text(
                      '${(groupedProduction.currentProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: TypographyConstants.statusIndicatorSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: UIConstants.standardSpacing),
            GameProgressIndicator(
              progress: groupedProduction.currentProgress,
              showPulse: groupedProduction.currentProgress < 1.0,
              progressColor:
                  groupedProduction.isQueued
                      ? AppColors.productionQueued
                      : AppColors.productionActive,
            ),
            if (groupedProduction.isQueued) ...[
              const SizedBox(height: UIConstants.smallPadding),
              const Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppColors.productionQueued,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Queued',
                    style: TextStyle(
                      color: AppColors.productionQueued,
                      fontSize: TypographyConstants.statusIndicatorSize,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Group production tasks by product ID for cleaner display
  List<GroupedProduction> _groupProductionTasks(List<ProductionTask> tasks) {
    final Map<String, List<ProductionTask>> grouped = {};

    for (final task in tasks) {
      grouped.putIfAbsent(task.productId, () => []).add(task);
    }

    return grouped.entries.map((entry) {
      final productId = entry.key;
      final productTasks = entry.value;

      // Sort by start time to get the currently active one
      productTasks.sort((a, b) => a.startTime.compareTo(b.startTime));

      final now = DateTime.now();
      final totalQuantity = productTasks.fold<int>(
        0,
        (sum, task) => sum + task.quantity,
      );

      // Find the currently active task (if any)
      ProductionTask? activeTask;
      double totalProgress = 0.0;
      double totalDuration = 0.0;
      bool isQueued = true;

      for (final task in productTasks) {
        totalDuration += task.durationSeconds;
        final taskEndTime = task.startTime.add(
          Duration(seconds: task.durationSeconds.toInt()),
        );

        if (now.isBefore(taskEndTime)) {
          if (activeTask == null) {
            activeTask = task;
            isQueued = task.isQueued || now.isBefore(task.startTime);

            if (!isQueued) {
              final elapsed =
                  now.difference(task.startTime).inMilliseconds / 1000.0;
              final taskProgress = (elapsed / task.durationSeconds).clamp(
                0.0,
                1.0,
              );
              totalProgress = taskProgress / productTasks.length;
            }
          }
          break;
        } else {
          // Task is completed
          totalProgress += 1.0 / productTasks.length;
        }
      }

      return GroupedProduction(
        productId: productId,
        quantity: totalQuantity,
        totalDuration: totalDuration,
        currentProgress: totalProgress.clamp(0.0, 1.0),
        isQueued: isQueued,
        earliestStartTime: productTasks.first.startTime,
      );
    }).toList();
  }
}

/// Helper class for grouped production display
class GroupedProduction {
  final String productId;
  final int quantity;
  final double totalDuration;
  final double currentProgress;
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
