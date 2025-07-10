import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;

// Helper class for grouped production display in v1.4.14
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

class BuildProductsScreen extends StatefulWidget {
  const BuildProductsScreen({super.key});

  @override
  State<BuildProductsScreen> createState() => _BuildProductsScreenState();
}

class _BuildProductsScreenState extends State<BuildProductsScreen> {
  bool _isProductionExpanded = false;
  Map<String, bool> _tierExpanded = {};

  @override
  void initState() {
    super.initState();
    _loadTierPreferences();
  }

  Future<void> _loadTierPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tierExpanded = {
        'Basic Parts': prefs.getBool('tier_basic_parts') ?? true,
        'Intermediate': prefs.getBool('tier_intermediate') ?? true,
        'Complex': prefs.getBool('tier_complex') ?? true,
        'Retail': prefs.getBool('tier_retail') ?? true,
      };
    });
  }

  Future<void> _saveTierPreference(String tierName, bool expanded) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tier_${tierName.toLowerCase().replaceAll(' ', '_')}';
    await prefs.setBool(key, expanded);
  }

  void _toggleTierExpansion(String tierName) {
    setState(() {
      _tierExpanded[tierName] = !(_tierExpanded[tierName] ?? true);
    });
    _saveTierPreference(tierName, _tierExpanded[tierName] ?? true);
  }

  void _toggleAllTiers() {
    final allExpanded = _areAllTiersExpanded();
    setState(() {
      for (final tierName in _tierExpanded.keys) {
        _tierExpanded[tierName] = !allExpanded;
      }
    });
    // Save all preferences
    for (final tierName in _tierExpanded.keys) {
      _saveTierPreference(tierName, _tierExpanded[tierName] ?? true);
    }
  }

  bool _areAllTiersExpanded() {
    return _tierExpanded.values.every((expanded) => expanded);
  }

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
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.build, color: Colors.blue[400], size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Build Products',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Expand/Collapse All button
                      IconButton(
                        onPressed: _toggleAllTiers,
                        icon: Icon(
                          _areAllTiersExpanded()
                              ? Icons.unfold_less
                              : Icons.unfold_more,
                          color: Colors.blue[400],
                        ),
                        tooltip:
                            _areAllTiersExpanded()
                                ? 'Collapse All'
                                : 'Expand All',
                      ),
                    ],
                  ),
                ),

                // Production status
                if (gameService.state.activeProductions.isNotEmpty)
                  Container(
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
                          // Show all productions when expanded - v1.4.14: Now grouped
                          SizedBox(
                            height: 200,
                            child: Builder(
                              builder: (context) {
                                final groupedProductions =
                                    _groupProductionTasks(
                                      gameService.state.activeProductions,
                                    );
                                return ListView.builder(
                                  itemCount: groupedProductions.length,
                                  itemBuilder: (context, index) {
                                    final groupedProduction =
                                        groupedProductions[index];
                                    return _buildGroupedProductionItem(
                                      groupedProduction,
                                      gameService,
                                    );
                                  },
                                );
                              },
                            ),
                          )
                        else
                          // Show only the next production to finish when collapsed - v1.4.14: Now grouped
                          Builder(
                            builder: (context) {
                              // Check if there are any active productions
                              if (gameService.state.activeProductions.isEmpty) {
                                return const Text(
                                  'No active productions',
                                  style: TextStyle(color: Colors.white70),
                                );
                              }

                              // Group productions and find the one with highest progress
                              final groupedProductions = _groupProductionTasks(
                                gameService.state.activeProductions,
                              );
                              final nextGroupedProduction = groupedProductions
                                  .reduce(
                                    (a, b) =>
                                        a.currentProgress > b.currentProgress
                                            ? a
                                            : b,
                                  );
                              return _buildGroupedProductionItem(
                                nextGroupedProduction,
                                gameService,
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Products list - organized by tiers with unlock filtering
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Show welcome message for completely new players
                      if (gameService.state.unlockedProducts.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue[900]!.withValues(alpha: 0.3),
                                Colors.blue[800]!.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue[400]!.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.blue[400],
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Welcome to Production.Inc!',
                                style: TextStyle(
                                  color: Colors.blue[300],
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Visit the Buy Materials screen to purchase materials and discover what you can build!',
                                style: TextStyle(
                                  color: Colors.blue[200],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start with cardboard to unlock your first product: Box 📦',
                                style: TextStyle(
                                  color: Colors.blue[100],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                      // Build sections for each tier (always show for discovery)
                      ...gameService.productsByTier.entries
                          .where((entry) => entry.value.isNotEmpty)
                          .map(
                            (entry) => _buildTierSection(
                              context,
                              gameService.getTierName(entry.key),
                              entry.value,
                              gameService,
                              tierLevel: entry.key,
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTierSection(
    BuildContext context,
    String tierName,
    List<game.Product> products,
    ProductionGameService gameService, {
    game.ProductLevel? tierLevel,
  }) {
    final isExpanded = _tierExpanded[tierName] ?? true;

    // Filter products to only show unlocked ones (v1.4.18)
    final unlockedProducts =
        products
            .where((product) => gameService.isProductUnlocked(product.id))
            .toList();

    // Count products with available materials for this tier
    final availableCount =
        unlockedProducts
            .where(
              (product) =>
                  gameService.state.hasMaterialsFor(product.requiredMaterials),
            )
            .length;

    // Get tier progress for display (v1.4.18)
    final tierProgressString =
        tierLevel != null ? gameService.getTierProgressString(tierLevel) : '';

    // Always show tier headers, even when empty, to give players context
    // This is especially important for new players who have no unlocked products

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapsible Tier header
        GestureDetector(
          onTap: () => _toggleTierExpansion(tierName),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue[900]!.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue[400]!.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(_getTierIcon(tierName), color: Colors.blue[400], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$tierName $tierProgressString',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[400],
                    ),
                  ),
                ),
                // Product count badge (now showing unlocked count)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[400]!.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${unlockedProducts.length}${availableCount > 0 ? ' ($availableCount ready)' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[300],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Expand/collapse icon
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    color: Colors.blue[400],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Collapsible content with grid layout - Fixed layout issues
        if (isExpanded)
          Column(
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
                // Adapts to phone resolution for better UI on mid/low-end devices
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
                    for (
                      int i = 0;
                      i < unlockedProducts.length;
                      i += columnsCount
                    ) {
                      final end =
                          (i + columnsCount < unlockedProducts.length)
                              ? i + columnsCount
                              : unlockedProducts.length;
                      rows.add(unlockedProducts.sublist(i, end));
                    }

                    return Column(
                      children:
                          rows.map((rowProducts) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (int i = 0; i < columnsCount; i++) ...[
                                    if (i > 0) const SizedBox(width: spacing),
                                    Expanded(
                                      child:
                                          i < rowProducts.length
                                              ? _buildEnhancedProductCard(
                                                context,
                                                rowProducts[i],
                                                gameService,
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
          ),
      ],
    );
  }

  IconData _getTierIcon(String tierName) {
    switch (tierName) {
      case 'Basic Parts':
        return Icons.construction;
      case 'Intermediate':
        return Icons.precision_manufacturing;
      case 'Complex':
        return Icons.smart_toy;
      case 'Retail':
        return Icons.storefront;
      default:
        return Icons.category;
    }
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

  Widget _buildEnhancedProductCard(
    BuildContext context,
    game.Product product,
    ProductionGameService gameService,
  ) {
    // Check if we can produce this product
    final canProduce = gameService.state.hasMaterialsFor(
      product.requiredMaterials,
    );

    // Check if this product is currently in production
    final isInProduction = gameService.state.activeProductions.any(
      (task) => task.productId == product.id,
    );

    // Calculate available quantity
    final availableQuantity = gameService.state.getProductCount(product.id);

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.all(4),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              canProduce
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // V1.4.10: Entire card is now clickable for production
          final quantity = gameService.getBuildQuantityPreference(product.id);
          if (canProduce) {
            HapticFeedback.mediumImpact();
            gameService.startProduction(product.id, quantity);
          } else {
            HapticFeedback.lightImpact();
          }
        },
        onLongPress: () => _showProductDetails(context, product, gameService),
        child: Container(
          // Add orange production indicator as background overlay
          decoration:
              isInProduction
                  ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.orange.withValues(alpha: 0.2),
                  )
                  : null,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center align content
            children: [
              // Product emoji and name with enhanced styling
              Row(
                children: [
                  GestureDetector(
                    onLongPress:
                        () =>
                            _showProductDetails(context, product, gameService),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.emoji,
                        style: const TextStyle(
                          fontSize: 26, // Increased by 2 (was 24)
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14, // Increased by 2 (was 12)
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(product.productionTimeSeconds / 60).toStringAsFixed(1)}m',
                          style: TextStyle(
                            fontSize: 12, // Increased by 2 (was 10)
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Production capability indicator with better design
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: canProduce ? Colors.green[700] : Colors.red[700],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canProduce ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        canProduce ? 'Ready to Build' : 'Need Materials',
                        style: const TextStyle(
                          fontSize: 13, // Increased by 2 (was 11)
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Available quantity and production status indicators
              Row(
                children: [
                  // Available quantity indicator
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Available: $availableQuantity',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (isInProduction) ...[
                    const SizedBox(width: 4),
                    // Production status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.build, size: 12, color: Colors.white),
                          const SizedBox(width: 2),
                          const Text(
                            'In Production',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Material requirements as chips (visible, not just tooltip)
              if (product.requiredMaterials.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Materials:',
                    style: TextStyle(
                      fontSize: 13, // Increased by 2 (was 11)
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Material requirements as chips with dynamic sizing
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight:
                        100, // Fixed max height to prevent conflicts with IntrinsicHeight
                    minHeight: 40,
                  ),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      alignment: WrapAlignment.center,
                      children:
                          product.requiredMaterials.entries.map((entry) {
                            final materialId = entry.key;
                            final required = entry.value;
                            final owned =
                                gameService.state.getMaterialCount(materialId) +
                                gameService.state.getProductCount(materialId);
                            final hasEnough = owned >= required;

                            final materialName =
                                gameService.getMaterial(materialId)?.name ??
                                gameService.getProduct(materialId)?.name ??
                                materialId;

                            // Simple truncation for material names (no TextPainter to avoid layout conflicts)
                            String displayName =
                                materialName.length > 18
                                    ? '${materialName.substring(0, 8)}...'
                                    : materialName;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    hasEnough
                                        ? Colors.green[600]
                                        : Colors.red[600],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$displayName: $owned/$required',
                                style: const TextStyle(
                                  fontSize: 10, // Increased by 2 (was 8)
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Production buttons (1 and 10 as requested) - V1.4.10: Now quantity selectors
              Row(
                children: [
                  Flexible(
                    child: _buildQuantitySelectorButton(
                      context,
                      product,
                      1,
                      gameService,
                    ),
                  ),
                  const SizedBox(
                    width: 4,
                  ), // Reduced spacing for narrow columns
                  Flexible(
                    child: _buildQuantitySelectorButton(
                      context,
                      product,
                      10,
                      gameService,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelectorButton(
    BuildContext context,
    game.Product product,
    int quantity,
    ProductionGameService gameService,
  ) {
    final isSelected =
        gameService.getBuildQuantityPreference(product.id) == quantity;

    // Calculate queued and active counts for this product
    final activeCount = gameService.getActiveProductionCount(product.id);
    final queuedCount = gameService.getQueuedCount(product.id);

    // Calculate total production time for this quantity
    final totalTimeMinutes = (product.productionTimeSeconds * quantity / 60);
    final timeText =
        totalTimeMinutes < 60
            ? '${totalTimeMinutes.toStringAsFixed(1)}m'
            : '${(totalTimeMinutes / 60).toStringAsFixed(1)}h';

    return SizedBox(
      height: 40, // Slightly taller for better visibility
      child: ElevatedButton(
        onPressed: () {
          // V1.4.10: This is now a quantity selector, not a direct build button
          HapticFeedback.lightImpact();
          gameService.setBuildQuantityPreference(product.id, quantity);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue[600] : Colors.grey[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side:
                isSelected
                    ? BorderSide(color: Colors.blue[300]!, width: 2)
                    : BorderSide.none,
          ),
          elevation: isSelected ? 6 : 2,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                quantity == 1 ? 'Build 1' : 'Build 10',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '($timeText)',
                style: const TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
              ),
              // Show queue info if there's any production
              if (activeCount > 0 || queuedCount > 0)
                Text(
                  activeCount > 0
                      ? (queuedCount > 0 ? 'Active+${queuedCount}Q' : 'Active')
                      : '${queuedCount}Q',
                  style: TextStyle(
                    fontSize: 8,
                    color:
                        activeCount > 0
                            ? Colors.orange[300]
                            : Colors.yellow[300],
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetails(
    BuildContext context,
    game.Product product,
    ProductionGameService gameService,
  ) {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Text(product.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.description,
                  style: TextStyle(color: Colors.grey[300], fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Production stats
                _buildStatRow(
                  'Production Time',
                  '${(product.productionTimeSeconds / 60).toStringAsFixed(1)} minutes',
                ),
                _buildStatRow(
                  'Sell Price',
                  '\$${product.sellPrice.toStringAsFixed(2)}',
                ),
                _buildStatRow('Tier', gameService.getTierName(product.levelId)),

                const SizedBox(height: 16),

                // Required materials
                if (product.requiredMaterials.isNotEmpty) ...[
                  const Text(
                    'Required Materials:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...product.requiredMaterials.entries.map((entry) {
                    final materialId = entry.key;
                    final required = entry.value;
                    final owned =
                        gameService.state.getMaterialCount(materialId) +
                        gameService.state.getProductCount(materialId);
                    final hasEnough = owned >= required;

                    final materialName =
                        gameService.getMaterial(materialId)?.name ??
                        gameService.getProduct(materialId)?.name ??
                        materialId;

                    final emoji =
                        gameService.getMaterial(materialId)?.emoji ??
                        gameService.getProduct(materialId)?.emoji ??
                        '📦';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              materialName,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  hasEnough
                                      ? Colors.green[600]
                                      : Colors.red[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$owned/$required',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Colors.blue[400])),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // v1.4.14 - Group production tasks by product type for cleaner display
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

  // v1.4.14 - Build grouped production item widget with consolidated display
  Widget _buildGroupedProductionItem(
    GroupedProduction groupedProduction,
    ProductionGameService gameService,
  ) {
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
              Icon(Icons.access_time, size: 12, color: Colors.white60),
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

  // v1.4.14 - Calculate remaining time for grouped production
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
