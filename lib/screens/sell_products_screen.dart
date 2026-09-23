import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;
import '../widgets/screen_header.dart';
import '../widgets/financial_status_display.dart';
import '../widgets/message_display.dart';
import '../widgets/tier_expansion_panel.dart';
import '../widgets/item_card.dart';
import '../widgets/game_dialog.dart';

class SellProductsScreen extends StatefulWidget {
  const SellProductsScreen({super.key});

  @override
  State<SellProductsScreen> createState() => _SellProductsScreenState();
}

class _SellProductsScreenState extends State<SellProductsScreen> {
  Map<String, bool> _tierExpanded = {};
  game.IndustryBranch? _selectedBranch;

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

  Widget _buildIndustryBranchFilterBar() {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            label: 'All Branches',
            emoji: '🌐',
            isSelected: _selectedBranch == null,
            onTap: () => setState(() => _selectedBranch = null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Consumer Tech',
            emoji: '📱',
            isSelected: _selectedBranch == game.IndustryBranch.consumerTech,
            onTap: () => setState(
              () => _selectedBranch = game.IndustryBranch.consumerTech,
            ),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Robotics',
            emoji: '🤖',
            isSelected: _selectedBranch == game.IndustryBranch.robotics,
            onTap: () => setState(
              () => _selectedBranch = game.IndustryBranch.robotics,
            ),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Clean Energy',
            emoji: '⚡',
            isSelected: _selectedBranch == game.IndustryBranch.cleanEnergy,
            onTap: () => setState(
              () => _selectedBranch = game.IndustryBranch.cleanEnergy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.purple.withValues(alpha: 0.25)
              : const Color(0xFF1E2638),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.purple[400]! : Colors.white24,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
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
                ScreenHeader(
                  icon: Icons.attach_money,
                  title: 'Sell Products',
                  iconColor: Colors.purple[400]!,
                  actions: [
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

                // Phase 3: Industry Branch Filter Bar
                _buildIndustryBranchFilterBar(),

                const SizedBox(height: 6),

                // Money and portfolio display
                FinancialStatusDisplay(
                  gameService: gameService,
                  mode: FinancialDisplayMode.portfolio,
                ),

                const SizedBox(height: 12),

                // Products inventory
                if (gameService.state.products.isEmpty ||
                    gameService.state.products.values.every(
                      (count) => count == 0,
                    ))
                  const Expanded(
                    child: MessageDisplay.empty(
                      icon: Icons.inventory_2_outlined,
                      title: 'No Products to Sell',
                      subtitle: 'Build some products first to sell them here!',
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

  Widget? _buildEnhancedTierSection(
    BuildContext context,
    String tierName,
    List<game.Product> products,
    ProductionGameService gameService,
  ) {
    // Phase 3: Filter by industry branch if selected
    final branchFiltered = _selectedBranch == null
        ? products
        : products
            .where((product) => product.industryBranch == _selectedBranch)
            .toList();

    // Filter products to only show those we have in inventory
    final availableProducts = branchFiltered
        .where(
          (product) => gameService.state.getProductCount(product.id) > 0,
        )
        .toList();

    if (availableProducts.isEmpty) return null;

    final isExpanded = _tierExpanded[tierName] ?? true;

    return TierExpansionPanel(
      title: tierName,
      icon: _getTierIcon(tierName),
      badge: '${availableProducts.length} available',
      initiallyExpanded: isExpanded,
      primaryColor: Colors.purple[400]!,
      backgroundColor: Colors.purple[900]!.withValues(alpha: 0.3),
      onExpansionChanged: (expanded) => _toggleTierExpansion(tierName),
      child: Column(
        children: [
          // Dynamic Grid layout with proper mobile sizing
          LayoutBuilder(
            builder: (context, constraints) {
        // Responsive: 3 columns for wide displays (>=1080px), otherwise 2
        int crossAxisCount = constraints.maxWidth >= 1080 ? 3 : 2;
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
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ItemCard(
                                  item: product,
                                  gameService: gameService,
                                  mode: ItemCardMode.sell,
                                  onProductDetails: () => showDialog(
                                    context: context,
                                    builder: (context) => GameDialog.productDetails(
                                      product: product,
                                      gameService: gameService,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
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


}
