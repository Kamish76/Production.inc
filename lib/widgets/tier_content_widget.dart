import 'package:flutter/material.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;
import 'item_card.dart';

/// Content widget for a tier section showing products in a responsive grid
class TierContentWidget extends StatelessWidget {
  final List<game.Product> products;
  final ProductionGameService gameService;
  final String tierName;

  const TierContentWidget({
    Key? key,
    required this.products,
    required this.gameService,
    required this.tierName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filter products to only show unlocked ones
    final unlockedProducts = products
        .where((product) => gameService.isProductUnlocked(product.id))
        .toList();

    return Column(
      children: [
        // Show helpful message if no products are unlocked in this tier
        if (unlockedProducts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800]?.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[600]!,
                style: BorderStyle.solid,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: Colors.grey[400],
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'No products unlocked yet',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTierUnlockHint(tierName),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          // Responsive column grid: 2 columns for smaller screens, 3 for larger
          LayoutBuilder(
            builder: (context, constraints) {
              // Get actual screen width for more accurate responsive behavior
              final screenWidth = MediaQuery.of(context).size.width;

              // Use screen width to determine optimal column count
              // 480px breakpoint optimized for 720p/1080p vs high-res phones
              final columnsCount = screenWidth < 480 ? 2 : 3;

              const spacing = 8.0;

              // Group unlocked products into rows based on responsive column count
              final rows = <List<game.Product>>[];
              for (int i = 0; i < unlockedProducts.length; i += columnsCount) {
                final end = (i + columnsCount < unlockedProducts.length)
                    ? i + columnsCount
                    : unlockedProducts.length;
                rows.add(unlockedProducts.sublist(i, end));
              }

              return Column(
                children: rows.map((rowProducts) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < columnsCount; i++) ...[
                          if (i > 0) const SizedBox(width: spacing),
                          Expanded(
                            child: i < rowProducts.length
                                ? ItemCard(
                                    item: rowProducts[i],
                                    gameService: gameService,
                                    mode: ItemCardMode.build,
                                  )
                                : const SizedBox(), // Empty space for incomplete rows
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getTierUnlockHint(String tierName) {
    switch (tierName) {
      case 'Basic Parts':
        return 'Buy materials from the Buy Materials screen to unlock basic products';
      case 'Intermediate':
        return 'Produce basic parts to unlock intermediate products';
      case 'Complex':
        return 'Produce intermediate parts to unlock complex products';
      case 'Retail':
        return 'Produce complex parts to unlock retail products';
      default:
        return 'Complete previous tiers to unlock these products';
    }
  }
}