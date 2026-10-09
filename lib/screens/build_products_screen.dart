import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/production_game_service.dart';
import '../constants/game_constants.dart';
import '../models/game_models.dart' as game;
import '../models/game_data.dart';
import '../widgets/production_status_panel.dart';
import '../widgets/message_display.dart';
import '../widgets/tier_expansion_panel.dart';
import '../widgets/tier_content_widget.dart';

class BuildProductsScreen extends StatefulWidget {
  const BuildProductsScreen({super.key});

  @override
  State<BuildProductsScreen> createState() => _BuildProductsScreenState();
}

class _BuildProductsScreenState extends State<BuildProductsScreen> {
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
              ? Colors.blue.withValues(alpha: 0.25)
              : const Color(0xFF1E2638),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue[400]! : Colors.white24,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
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

                // Phase 3: Industry Branch Filter Bar
                _buildIndustryBranchFilterBar(),

                const SizedBox(height: 8),

                // Production status
                ProductionStatusPanel(gameService: gameService),

                const SizedBox(height: 12),

                // Products list - organized by tiers with unlock filtering (virtualized)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final showWelcome = gameService.state.unlockedProducts.isEmpty;
                      final visibleTierEntries = gameService.productsByTier.entries
                          .where((entry) => entry.value.isNotEmpty)
                          .where((entry) {
                            if (_selectedBranch == null) return true;
                            return entry.value.any((p) => p.industryBranch == _selectedBranch);
                          })
                          .toList();
                      final int itemCount = (showWelcome ? 1 : 0) + visibleTierEntries.length;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          if (showWelcome && index == 0) {
                            return const MessageDisplay.welcome();
                          }
                          final tierIndex = showWelcome ? index - 1 : index;
                          final entry = visibleTierEntries[tierIndex];
                          return _buildTierSection(
                            context,
                            gameService.getTierName(entry.key),
                            entry.value,
                            gameService,
                            tierLevel: entry.key,
                          ) ?? const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget? _buildTierSection(
    BuildContext context,
    String tierName,
    List<game.Product> products,
    ProductionGameService gameService, {
    game.ProductLevel? tierLevel,
  }) {
    // Phase 3: Filter products by selected industry branch if active
    final branchFilteredProducts = _selectedBranch == null
        ? products
        : products
            .where((product) => product.industryBranch == _selectedBranch)
            .toList();

    // If filtering by branch and this tier has no items in that branch, omit section
    if (_selectedBranch != null && branchFilteredProducts.isEmpty) {
      return null;
    }

    // Filter products to only show unlocked ones (v1.4.18)
    final unlockedProducts = branchFilteredProducts
        .where((product) => gameService.isProductUnlocked(product.id))
        .toList();

    // Count products with available materials for this tier
    final availableCount = unlockedProducts
        .where(
          (product) =>
              gameService.state.hasMaterialsFor(product.requiredMaterials),
        )
        .length;

    // Get tier progress for display (v1.4.18)
    final tierProgressString =
        tierLevel != null ? gameService.getTierProgressString(tierLevel) : '';

    // Create badge text
    final badgeText =
        '${unlockedProducts.length}${availableCount > 0 ? ' ($availableCount ready)' : ''}';

    // Get tier key for auto-build
    final tierKey = _getTierKey(tierName);

    return Column(
      children: [
        // Auto-Build status with controls (v1.5.0 Phase 2) - now integrated
        if (tierKey != null && (gameService.state.autoBuildMachinesOwned[tierKey] ?? 0) > 0)
          _buildAutoBuildStatusWithControls(gameService, tierKey, tierName),
        
        // Tier section with products
        TierExpansionPanel(
          title: tierName,
          subtitle: tierProgressString,
          icon: _getTierIcon(tierName),
          badge: badgeText,
          initiallyExpanded: _tierExpanded[tierName] ?? true,
          onExpansionChanged: (expanded) {
            setState(() {
              _tierExpanded[tierName] = expanded;
            });
            _saveTierPreference(tierName, expanded);
          },
          contentBuilder: (_) => TierContentWidget(
            products: branchFilteredProducts,
            gameService: gameService,
            tierName: tierName,
          ),
        ),
      ],
    );
  }

  String? _getTierKey(String tierName) {
    switch (tierName) {
      case 'Basic Parts':
        return 'basicParts';
      case 'Intermediate':
        return 'intermediate';
      case 'Complex':
        return 'complex';
      case 'Retail':
        return 'retail';
      default:
        return null;
    }
  }

  /// Build auto-build machine status with embedded controls (v1.5.0 Phase 2)
  Widget _buildAutoBuildStatusWithControls(
    ProductionGameService gameService,
    String tier,
    String tierName,
  ) {
    final machineCount = gameService.state.autoBuildMachinesOwned[tier] ?? 0;
    final enabled = gameService.state.autoBuildEnabled[tier] ?? false;
    final capacity = gameService.state.autoBuildProductCapacity[tier] ?? 10;
    final nextProduct = gameService.getNextProductToBuild(tier);
    final secondsRemaining = gameService.getSecondsUntilNextAutoBuildTick(tier);
    final throughputLevel = gameService.getAutoBuildThroughputLevel(tier);
    final itemsPerTick = machineCount * throughputLevel;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with On/Off toggle
          Row(
            children: [
              Icon(
                Icons.precision_manufacturing,
                color: enabled ? Colors.blue[300] : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AUTO-BUILD: $tierName',
                style: TextStyle(
                  color: enabled ? Colors.blue[300] : Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              // On/Off toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: enabled
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: enabled ? Colors.blue : Colors.red,
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  onTap: machineCount > 0
                      ? () => gameService.toggleAutoBuild(tier)
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        enabled ? Icons.power_settings_new : Icons.power_off,
                        color: enabled ? Colors.blue : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        enabled ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: enabled ? Colors.blue : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status info grid
          Row(
            children: [
              // Machines count
              Expanded(
                child: _buildTierStatusItem(
                  icon: Icons.settings_input_component,
                  label: 'Machines',
                  value: '$machineCount',
                  valueColor: Colors.white,
                ),
              ),
              
              // Throughput
              Expanded(
                child: _buildTierStatusItem(
                  icon: Icons.bolt,
                  label: 'Throughput',
                  value: 'Lv.$throughputLevel',
                  valueColor: Colors.amberAccent,
                ),
              ),

              // Next tick countdown
              Expanded(
                child: _buildTierStatusItem(
                  icon: Icons.timer_outlined,
                  label: 'Next Tick',
                  value: enabled
                      ? (secondsRemaining != null ? '${secondsRemaining}s' : '--')
                      : 'Paused',
                  valueColor: enabled
                      ? (secondsRemaining != null && secondsRemaining <= 2
                          ? Colors.orange
                          : Colors.blue[300]!)
                      : Colors.grey,
                ),
              ),
              
              // Current/next product
              Expanded(
                child: _buildTierStatusItem(
                  icon: Icons.build_circle_outlined,
                  label: 'Building',
                  value: enabled ? (nextProduct ?? '--') : 'Paused',
                  valueColor: enabled ? Colors.blue[300]! : Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          
          // Capacity controls embedded in status
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: Colors.cyan[300],
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Capacity per Product:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              
              // Decrement button
              IconButton(
                onPressed: capacity > 10
                    ? () => gameService.decreaseAutoBuildCapacity(tier)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red[400],
                disabledColor: Colors.grey,
                iconSize: 24,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              
              const SizedBox(width: 12),
              
              // Capacity display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.cyan.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '$capacity',
                  style: TextStyle(
                    color: Colors.cyan[300],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Increment button
              IconButton(
                onPressed: () => gameService.increaseAutoBuildCapacity(tier),
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.green[400],
                iconSize: 24,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),

          // Priority Queue Controls & Strip
          _buildPriorityQueueSection(gameService, tier, tierName, capacity),

          const SizedBox(height: 10),

          // Info text
          Text(
            'Building $itemsPerTick product${itemsPerTick == 1 ? "" : "s"} every ${AutoBuildConstants.tickIntervalSeconds}s${enabled ? " (active)" : " (paused)"}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the priority queue strip inside the tier status card
  Widget _buildPriorityQueueSection(
    ProductionGameService gameService,
    String tier,
    String tierName,
    int capacity,
  ) {
    final pinned = gameService.getPinnedProducts(tier);
    final hasPinned = pinned.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.push_pin,
              color: hasPinned ? Colors.amberAccent : Colors.white54,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Priority Queue:',
              style: TextStyle(
                color: hasPinned ? Colors.amberAccent : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            if (hasPinned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amberAccent, width: 0.8),
                ),
                child: Text(
                  '${pinned.length} pinned',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Spacer(),
            InkWell(
              onTap: () => _showPriorityQueueModal(
                context,
                gameService,
                tier,
                tierName,
                capacity,
              ),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasPinned ? Icons.tune : Icons.add_circle_outline,
                      size: 14,
                      color: Colors.cyanAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasPinned ? 'Manage' : 'Prioritize',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (hasPinned)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < pinned.length; i++) ...[
                  _buildPinnedProductChip(
                    gameService,
                    tier,
                    pinned[i],
                    i + 1,
                    capacity,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.white38),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Standard order. Tap 📌 on products below to prioritize them.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build a compact chip representing a pinned product
  Widget _buildPinnedProductChip(
    ProductionGameService gameService,
    String tier,
    String productId,
    int rank,
    int capacity,
  ) {
    final product = GameData.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => game.Product(
        id: productId,
        name: productId,
        description: '',
        sellPrice: 0,
        emoji: '📦',
        requiredMaterials: const {},
        productionTimeSeconds: 1,
        baseShippingTimeSeconds: 0,
        levelId: game.ProductLevel.basicParts,
      ),
    );

    final currentCount = (gameService.state.products[productId] ?? 0) +
        gameService.state.activeProductions
            .where((t) => t.productId == productId)
            .fold(0, (sum, t) => sum + t.quantity);
    final isAtCap = currentCount >= capacity;

    return Container(
      padding: const EdgeInsets.only(left: 6, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: isAtCap
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAtCap ? Colors.greenAccent : Colors.amberAccent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isAtCap ? Colors.green : Colors.amber,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            product.emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            product.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$currentCount/$capacity',
            style: TextStyle(
              color: isAtCap ? Colors.greenAccent : Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => gameService.unpinProduct(productId),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 14, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  /// Show modal bottom sheet to manage, reorder, or add to tier priority queue
  void _showPriorityQueueModal(
    BuildContext context,
    ProductionGameService gameService,
    String tier,
    String tierName,
    int capacity,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final pinned = gameService.getPinnedProducts(tier);
            final defaultOrder = AutoBuildConstants.productOrderByTier[tier] ?? [];
            final unlockedInTier = defaultOrder
                .where((id) => gameService.isProductUnlocked(id))
                .toList();
            final unpinnedUnlocked = unlockedInTier
                .where((id) => !pinned.contains(id))
                .toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF181B2C),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Header
                      Row(
                        children: [
                          const Icon(Icons.push_pin, color: Colors.amberAccent, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$tierName Queue Priority',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Top items build until capacity is filled first',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (pinned.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                gameService.clearPinnedProducts(tier);
                                setSheetState(() {});
                              },
                              icon: const Icon(Icons.clear_all, size: 16, color: Colors.redAccent),
                              label: const Text(
                                'Clear All',
                                style: TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 12),

                      // Section 1: Active Priority Queue
                      Expanded(
                        child: ListView(
                          children: [
                            Text(
                              'PRIORITY QUEUE (${pinned.length})',
                              style: TextStyle(
                                color: Colors.amberAccent.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (pinned.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.low_priority, size: 32, color: Colors.white30),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'No Products Pinned',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Machines build using standard order. Tap + below to add products to the top of the queue.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              for (int i = 0; i < pinned.length; i++) ...[
                                _buildModalPriorityItem(
                                  gameService: gameService,
                                  tier: tier,
                                  productId: pinned[i],
                                  rank: i + 1,
                                  capacity: capacity,
                                  isFirst: i == 0,
                                  isLast: i == pinned.length - 1,
                                  onMoveUp: () {
                                    gameService.movePinnedProductPriority(tier, i, true);
                                    setSheetState(() {});
                                  },
                                  onMoveDown: () {
                                    gameService.movePinnedProductPriority(tier, i, false);
                                    setSheetState(() {});
                                  },
                                  onRemove: () {
                                    gameService.unpinProduct(pinned[i]);
                                    setSheetState(() {});
                                  },
                                ),
                                const SizedBox(height: 6),
                              ],

                            const SizedBox(height: 16),

                            // Section 2: Add Unpinned Products
                            if (unpinnedUnlocked.isNotEmpty) ...[
                              Text(
                                'ADD UNLOCKED PRODUCTS TO QUEUE',
                                style: TextStyle(
                                  color: Colors.cyanAccent.withValues(alpha: 0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final productId in unpinnedUnlocked) ...[
                                    _buildModalAddProductChip(
                                      productId: productId,
                                      onAdd: () {
                                        gameService.pinProduct(productId);
                                        setSheetState(() {});
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(modalContext).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalPriorityItem({
    required ProductionGameService gameService,
    required String tier,
    required String productId,
    required int rank,
    required int capacity,
    required bool isFirst,
    required bool isLast,
    required VoidCallback onMoveUp,
    required VoidCallback onMoveDown,
    required VoidCallback onRemove,
  }) {
    final product = GameData.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => game.Product(
        id: productId,
        name: productId,
        description: '',
        sellPrice: 0,
        emoji: '📦',
        requiredMaterials: const {},
        productionTimeSeconds: 1,
        baseShippingTimeSeconds: 0,
        levelId: game.ProductLevel.basicParts,
      ),
    );

    final currentCount = (gameService.state.products[productId] ?? 0) +
        gameService.state.activeProductions
            .where((t) => t.productId == productId)
            .fold(0, (sum, t) => sum + t.quantity);
    final isAtCap = currentCount >= capacity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF22283C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAtCap
              ? Colors.greenAccent.withValues(alpha: 0.4)
              : Colors.amberAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isAtCap ? Colors.green : Colors.amber,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(product.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isAtCap
                      ? 'At capacity ($currentCount/$capacity)'
                      : '$currentCount/$capacity items',
                  style: TextStyle(
                    color: isAtCap ? Colors.greenAccent : Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 18),
            color: isFirst ? Colors.white24 : Colors.cyanAccent,
            onPressed: isFirst ? null : onMoveUp,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            tooltip: 'Move up in priority',
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 18),
            color: isLast ? Colors.white24 : Colors.cyanAccent,
            onPressed: isLast ? null : onMoveDown,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            tooltip: 'Move down in priority',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.redAccent,
            onPressed: onRemove,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            tooltip: 'Remove from priority',
          ),
        ],
      ),
    );
  }

  Widget _buildModalAddProductChip({
    required String productId,
    required VoidCallback onAdd,
  }) {
    final product = GameData.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => game.Product(
        id: productId,
        name: productId,
        description: '',
        sellPrice: 0,
        emoji: '📦',
        requiredMaterials: const {},
        productionTimeSeconds: 1,
        baseShippingTimeSeconds: 0,
        levelId: game.ProductLevel.basicParts,
      ),
    );

    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 14, color: Colors.cyanAccent),
            const SizedBox(width: 4),
            Text(product.emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              product.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a single tier status item
  Widget _buildTierStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
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
}
