import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;

class SellProductsScreen extends StatefulWidget {
  const SellProductsScreen({super.key});

  @override
  State<SellProductsScreen> createState() => _SellProductsScreenState();
}

class _SellProductsScreenState extends State<SellProductsScreen> {
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
        'Basic Parts': prefs.getBool('sell_tier_basic_parts') ?? true,
        'Intermediate': prefs.getBool('sell_tier_intermediate') ?? true,
        'Complex': prefs.getBool('sell_tier_complex') ?? true,
        'Retail': prefs.getBool('sell_tier_retail') ?? true,
      };
    });
  }

  Future<void> _saveTierPreference(String tierName, bool expanded) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'sell_tier_${tierName.toLowerCase().replaceAll(' ', '_')}';
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
                // Screen title with expand/collapse all button
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: Colors.purple[400],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Sell Products',
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
                        tooltip:
                            _areAllTiersExpanded()
                                ? 'Collapse All'
                                : 'Expand All',
                        icon: AnimatedRotation(
                          turns: _areAllTiersExpanded() ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.expand_more,
                            color: Colors.purple[400],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Money and portfolio display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.purple[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Money: \$${gameService.state.money.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Total Products',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple[200],
                                ),
                              ),
                              Text(
                                '${gameService.state.products.values.fold(0, (sum, count) => sum + count)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.purple[400],
                          ),
                          Column(
                            children: [
                              Text(
                                'Portfolio Value',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple[200],
                                ),
                              ),
                              Text(
                                '\$${_calculatePortfolioValue(gameService).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Products inventory
                if (gameService.state.products.isEmpty ||
                    gameService.state.products.values.every(
                      (count) => count == 0,
                    ))
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Products to Sell',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Build some products first to sell them here!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Products list - organized by tiers with enhanced grid layout
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Build sections for each tier that has available products
                        ...gameService.productsByTier.entries
                            .map(
                              (entry) => _buildEnhancedTierSection(
                                context,
                                gameService.getTierName(entry.key),
                                entry.value,
                                gameService,
                              ),
                            )
                            .where((widget) => widget != null)
                            .cast<Widget>(),
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

  double _calculatePortfolioValue(ProductionGameService gameService) {
    double totalValue = 0;
    for (final entry in gameService.state.products.entries) {
      final productId = entry.key;
      final quantity = entry.value;
      final product = gameService.getProduct(productId);
      if (product != null && quantity > 0) {
        totalValue += product.sellPrice * quantity;
      }
    }
    return totalValue;
  }

  Widget? _buildEnhancedTierSection(
    BuildContext context,
    String tierName,
    List<game.Product> products,
    ProductionGameService gameService,
  ) {
    // Filter products to only show those we have in inventory
    final availableProducts =
        products
            .where(
              (product) => gameService.state.getProductCount(product.id) > 0,
            )
            .toList();

    if (availableProducts.isEmpty) return null;

    final isExpanded = _tierExpanded[tierName] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced tier header with tap to expand/collapse
        GestureDetector(
          onTap: () => _toggleTierExpansion(tierName),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.purple[900]!.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purple[400]!.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getTierIcon(tierName),
                  color: Colors.purple[400],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  tierName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[400],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple[400]!.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${availableProducts.length} available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple[300],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    color: Colors.purple[400],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Collapsible content with enhanced grid layout
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isExpanded ? null : 0,
          child:
              isExpanded
                  ? Column(
                    children: [
                      // Dynamic Grid layout with proper mobile sizing
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive: 2 columns for <480px (720p/1080p), 3 for high-res
                          int crossAxisCount =
                              constraints.maxWidth < 480 ? 2 : 3;
                          double cardWidth =
                              (constraints.maxWidth -
                                  (crossAxisCount - 1) *
                                      8 - // Spacing between cards
                                  24) / // Margins
                              crossAxisCount;

                          return Wrap(
                            spacing: 8, // Optimized spacing for mobile
                            runSpacing: 12,
                            children:
                                availableProducts.map((product) {
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
    final available = gameService.state.getProductCount(product.id);
    final stockLevel = _getStockLevel(available);

    // Check if this product is currently in production
    final isInProduction = gameService.state.activeProductions.any(
      (task) => task.productId == product.id,
    );

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.all(4),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStockLevelColor(stockLevel).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => HapticFeedback.lightImpact(),
        onLongPress:
            () => _showProductDetails(context, product, gameService, available),
        child: Container(
          // Add orange production indicator as background overlay
          decoration:
              isInProduction
                  ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.orange.withValues(alpha: 0.2),
                  )
                  : null,
          padding: const EdgeInsets.all(10), // Mobile-optimized padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product emoji and name with enhanced styling
              Row(
                children: [
                  GestureDetector(
                    onLongPress:
                        () => _showProductDetails(
                          context,
                          product,
                          gameService,
                          available,
                        ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.emoji,
                        style: const TextStyle(fontSize: 32), // Prominent emoji
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
                            fontSize: 14, // Mobile-optimized for 3 columns
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '\$${product.sellPrice.toStringAsFixed(2)} each',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stock availability indicator with color coding
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStockLevelColor(stockLevel),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStockLevelIcon(stockLevel),
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Available: $available',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Production status indicator (if product is being produced)
              if (isInProduction)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.build, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      const Text(
                        'Producing',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isInProduction) const SizedBox(height: 8),

              // Revenue potential display
              if (available > 0) ...[
                Text(
                  'Revenue Potential:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: \$${(product.sellPrice * available).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green[300],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Sell buttons (1 and 10 as requested)
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedSellButton(
                      context,
                      product,
                      1,
                      gameService,
                      available,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildEnhancedSellButton(
                      context,
                      product,
                      10,
                      gameService,
                      available,
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

  String _getStockLevel(int available) {
    if (available >= 20) return 'high';
    if (available >= 5) return 'medium';
    return 'low';
  }

  Color _getStockLevelColor(String stockLevel) {
    switch (stockLevel) {
      case 'high':
        return Colors.green[700]!;
      case 'medium':
        return Colors.orange[700]!;
      case 'low':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  IconData _getStockLevelIcon(String stockLevel) {
    switch (stockLevel) {
      case 'high':
        return Icons.trending_up;
      case 'medium':
        return Icons.trending_flat;
      case 'low':
        return Icons.trending_down;
      default:
        return Icons.inventory;
    }
  }

  Widget _buildEnhancedSellButton(
    BuildContext context,
    game.Product product,
    int quantity,
    ProductionGameService gameService,
    int available,
  ) {
    final canSell = available >= quantity;
    final revenue = product.sellPrice * quantity;

    return ElevatedButton(
      onPressed:
          canSell
              ? () {
                HapticFeedback.lightImpact();
                gameService.sellProduct(product.id, quantity);
              }
              : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canSell ? Colors.purple[600] : Colors.grey[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sell $quantity',
            style: const TextStyle(
              fontSize: 11, // Mobile-optimized button text
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '\$${revenue.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 9, // Revenue display
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(
    BuildContext context,
    game.Product product,
    ProductionGameService gameService,
    int available,
  ) {
    final totalValue = product.sellPrice * available;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
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
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.description,
                  style: TextStyle(fontSize: 16, color: Colors.grey[300]),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Sell Price:',
                  '\$${product.sellPrice.toStringAsFixed(2)}',
                ),
                _buildDetailRow('Available:', '$available units'),
                _buildDetailRow(
                  'Total Value:',
                  '\$${totalValue.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Level: ${product.levelId.toString().split('.').last}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.purple[300],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(color: Colors.purple[400]),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
