import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;

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
                      const Text(
                        'Build Products',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
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
                          // Show all productions when expanded
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount:
                                  gameService.state.activeProductions.length,
                              itemBuilder: (context, index) {
                                final production =
                                    gameService.state.activeProductions[index];
                                return _buildProductionItem(
                                  production,
                                  gameService,
                                );
                              },
                            ),
                          )
                        else
                          // Show only the next production to finish when collapsed
                          Builder(
                            builder: (context) {
                              // Check if there are any active productions
                              if (gameService.state.activeProductions.isEmpty) {
                                return const Text(
                                  'No active productions',
                                  style: TextStyle(color: Colors.white70),
                                );
                              }

                              // Find the production that will finish first (highest progress)
                              final nextProduction = gameService
                                  .state
                                  .activeProductions
                                  .reduce(
                                    (a, b) => a.progress > b.progress ? a : b,
                                  );
                              return _buildProductionItem(
                                nextProduction,
                                gameService,
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Products list - organized by tiers
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Build sections for each tier that has products
                      ...gameService.productsByTier.entries
                          .where((entry) => entry.value.isNotEmpty)
                          .map(
                            (entry) => _buildTierSection(
                              context,
                              gameService.getTierName(entry.key),
                              entry.value,
                              gameService,
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
    ProductionGameService gameService,
  ) {
    final isExpanded = _tierExpanded[tierName] ?? true;

    // Count products with available materials for this tier
    final availableCount =
        products
            .where(
              (product) =>
                  gameService.state.hasMaterialsFor(product.requiredMaterials),
            )
            .length;

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
              color: Colors.blue[900]!.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[400]!.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(_getTierIcon(tierName), color: Colors.blue[400], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tierName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[400],
                    ),
                  ),
                ),
                // Product count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[400]!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${products.length}${availableCount > 0 ? ' ($availableCount ready)' : ''}',
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

        // Collapsible content with grid layout
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isExpanded ? null : 0,
          child:
              isExpanded
                  ? Column(
                    children: [
                      // Dynamic Grid layout with proper sizing
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Force 3 columns on most devices, only use 2 on very narrow screens
                          int crossAxisCount =
                              constraints.maxWidth < 400 ? 2 : 3;
                          double cardWidth =
                              (constraints.maxWidth -
                                  (crossAxisCount - 1) * 8 - // Reduced spacing
                                  24) / // Reduced margins
                              crossAxisCount;

                          return Wrap(
                            spacing: 8, // Reduced spacing to fit 3 columns
                            runSpacing: 12,
                            children:
                                products.map((product) {
                                  return SizedBox(
                                    width: cardWidth,
                                    child: _buildEnhancedProductCard(
                                      context,
                                      product,
                                      gameService,
                                    ),
                                  );
                                }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  )
                  : const SizedBox.shrink(),
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

  Widget _buildEnhancedProductCard(
    BuildContext context,
    game.Product product,
    ProductionGameService gameService,
  ) {
    // Check if we can produce this product
    final canProduce = gameService.state.hasMaterialsFor(
      product.requiredMaterials,
    );

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.all(4),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              canProduce
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => HapticFeedback.lightImpact(),
        onLongPress: () => _showProductDetails(context, product, gameService),
        child: Padding(
          padding: const EdgeInsets.all(10), // Reduced from 12 to fit 3 columns
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product emoji and name with enhanced styling
              Row(
                children: [
                  GestureDetector(
                    onLongPress:
                        () =>
                            _showProductDetails(context, product, gameService),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.emoji,
                        style: const TextStyle(
                          fontSize: 32,
                        ), // Increased from 24px
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
                            fontSize:
                                14, // Kept at good mobile size but reduced from 15 to fit 3 cols
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(product.productionTimeSeconds / 60).toStringAsFixed(1)}m',
                          style: TextStyle(
                            fontSize: 12, // Kept readable but reduced from 13
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Production capability indicator with better design
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: canProduce ? Colors.green[700] : Colors.red[700],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      canProduce ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        canProduce ? 'Ready to Build' : 'Need Materials',
                        style: const TextStyle(
                          fontSize: 12, // Increased from 11
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Material requirements as chips (visible, not just tooltip)
              if (product.requiredMaterials.isNotEmpty) ...[
                Text(
                  'Materials:',
                  style: TextStyle(
                    fontSize: 12, // Increased from 11
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 2, // Reduced from 4 to save space
                  runSpacing: 2, // Reduced from 4
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

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4, // Reduced from 6 to save space
                            vertical: 1, // Reduced from 2
                          ),
                          decoration: BoxDecoration(
                            color:
                                hasEnough ? Colors.green[600] : Colors.red[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$materialName: $owned/$required',
                            style: const TextStyle(
                              fontSize: 10, // Increased from 9
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 8),
              ],

              // Production buttons (1 and 10 as requested)
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedProduceButton(
                      context,
                      product,
                      1,
                      gameService,
                      canProduce,
                    ),
                  ),
                  const SizedBox(width: 4), // Reduced from 6 to save space
                  Expanded(
                    child: _buildEnhancedProduceButton(
                      context,
                      product,
                      10,
                      gameService,
                      canProduce,
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

  Widget _buildEnhancedProduceButton(
    BuildContext context,
    game.Product product,
    int quantity,
    ProductionGameService gameService,
    bool canProduce,
  ) {
    // Check if we have materials for this quantity
    final requiredMaterials = <String, int>{};
    for (final entry in product.requiredMaterials.entries) {
      requiredMaterials[entry.key] = entry.value * quantity;
    }

    final canProduceQuantity = gameService.state.hasMaterialsFor(
      requiredMaterials,
    );

    // Calculate total production time for this quantity
    final totalTimeMinutes = (product.productionTimeSeconds * quantity / 60);
    final timeText =
        totalTimeMinutes < 60
            ? '${totalTimeMinutes.toStringAsFixed(1)}m'
            : '${(totalTimeMinutes / 60).toStringAsFixed(1)}h';

    return SizedBox(
      height: 32, // Reduced from 36 to save space for 3 columns
      child: ElevatedButton(
        onPressed:
            canProduceQuantity
                ? () {
                  HapticFeedback.mediumImpact();
                  gameService.startProduction(product.id, quantity);
                }
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canProduceQuantity ? Colors.blue[600] : Colors.grey[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: canProduceQuantity ? 4 : 1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Build $quantity',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ), // Increased from 10
            ),
            Text(
              '($timeText)',
              style: const TextStyle(fontSize: 9),
            ), // Increased from 8
          ],
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

  Widget _buildProductionItem(
    dynamic production,
    ProductionGameService gameService,
  ) {
    final product = gameService.getProduct(production.productId);
    if (product == null) {
      return const SizedBox.shrink(); // Handle missing product gracefully
    }
    final progress = (production.progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${product.emoji} ${product.name} x${production.quantity}',
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
            tween: Tween<double>(begin: 0, end: production.progress),
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
                _getRemainingTime(production),
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRemainingTime(dynamic production) {
    final elapsed = DateTime.now().difference(production.startTime).inSeconds;
    final total = production.durationSeconds;
    final remaining = total - elapsed;

    if (remaining <= 0) return 'Completing...';

    if (remaining < 60) {
      return '${remaining}s left';
    } else if (remaining < 3600) {
      final minutes = (remaining / 60).floor();
      final seconds = remaining % 60;
      return '${minutes}m ${seconds}s left';
    } else {
      final hours = (remaining / 3600).floor();
      final minutes = ((remaining % 3600) / 60).floor();
      return '${hours}h ${minutes}m left';
    }
  }
}
