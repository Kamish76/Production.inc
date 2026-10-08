import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auto_sell_preview.dart';
import '../models/game_data.dart';
import '../models/game_models.dart' hide Material;
import '../services/production_game_service.dart';
import 'game_icon.dart';

/// Full-page or bottom-sheet view for configuring Sales Hub Selling Automation rules,
/// live queue preview diagnostics, dispatch policies, and the product sales whitelist matrix.
class MachineSetupView extends StatefulWidget {
  final bool isBottomSheet;

  const MachineSetupView({
    super.key,
    this.isBottomSheet = false,
  });

  @override
  State<MachineSetupView> createState() => _MachineSetupViewState();
}

class _MachineSetupViewState extends State<MachineSetupView> {
  static const int _batchSize = 15;
  int _displayedLimit = _batchSize;
  ProductLevel? _selectedTierFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification, int totalFilteredCount) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is ScrollUpdateNotification || notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      if (metrics.maxScrollExtent > 0 && metrics.pixels >= metrics.maxScrollExtent - 250) {
        if (_displayedLimit < totalFilteredCount) {
          setState(() {
            _displayedLimit = math.min(_displayedLimit + _batchSize, totalFilteredCount);
          });
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionGameService>(
      builder: (context, gameService, _) {
        final nextAction = gameService.getAutoSellNextAction();

        // Calculate total filtered product count for lazy loading scroll notifications
        List<Product> filteredProducts = GameData.products;
        if (_selectedTierFilter != null) {
          filteredProducts = filteredProducts.where((p) => p.levelId == _selectedTierFilter).toList();
        }
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.trim().toLowerCase();
          filteredProducts = filteredProducts
              .where((p) => p.name.toLowerCase().contains(q) || p.id.toLowerCase().contains(q))
              .toList();
        }
        final totalFilteredCount = filteredProducts.length;

        if (widget.isBottomSheet) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Sheet Header
                  _buildSheetHeader(context, gameService),

                  const Divider(color: Colors.white12, height: 1),

                  // Scrollable content
                  Flexible(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) => _onScrollNotification(n, totalFilteredCount),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        children: [
                          _buildLiveQueueCard(nextAction, gameService),
                          const SizedBox(height: 16),
                          _buildRecentAutoSoldLogCard(gameService),
                          const SizedBox(height: 16),
                          _buildDispatchRulesSection(gameService),
                          const SizedBox(height: 16),
                          _buildWhitelistMatrixSection(gameService),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Full-page Tab Mode
        return NotificationListener<ScrollNotification>(
          onNotification: (n) => _onScrollNotification(n, totalFilteredCount),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Tab Header Banner with Master Switch & Machine Stats
              _buildTabHeaderBanner(context, gameService),
              const SizedBox(height: 16),

              // Section 1: Live Queue & Next Dispatch Diagnostics Card
              _buildLiveQueueCard(nextAction, gameService),
              const SizedBox(height: 16),

              // Section 1B: Recent Automation Dispatches Activity Log
              _buildRecentAutoSoldLogCard(gameService),
              const SizedBox(height: 16),

              // Section 2: Automation Dispatch Rules
              _buildDispatchRulesSection(gameService),
              const SizedBox(height: 16),

              // Section 3: Product Whitelist Matrix
              _buildWhitelistMatrixSection(gameService),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  /// Full-tab Header Banner with Master Switch & Machine Stats
  Widget _buildTabHeaderBanner(BuildContext context, ProductionGameService gameService) {
    final state = gameService.state;
    final isEnabled = state.autoSellEnabled && state.autoSellMachinesOwned > 0;
    final machinesOwned = state.autoSellMachinesOwned;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF22263C),
            isEnabled ? const Color(0xFF1E2135) : const Color(0xFF191B2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? Colors.purple.withValues(alpha: 0.4)
              : Colors.white12,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
                ),
                child: const Icon(
                  Icons.precision_manufacturing_outlined,
                  color: Colors.purpleAccent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selling Automation & Machine Setup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      machinesOwned <= 0
                          ? 'Acquire dispatchers in Machines tab to start sales'
                          : 'Speed: ${state.autoSellThroughputLevel}x  •  $machinesOwned Active Dispatchers',
                      style: TextStyle(
                        color: machinesOwned > 0 ? Colors.purple[200] : Colors.white54,
                        fontSize: 12,
                        fontWeight: machinesOwned > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Master Power Switch
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEnabled ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: isEnabled ? Colors.purple[200] : Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: isEnabled,
                      activeThumbColor: Colors.purpleAccent,
                      activeTrackColor: Colors.purple.withValues(alpha: 0.4),
                      inactiveThumbColor: Colors.white38,
                      inactiveTrackColor: Colors.white10,
                      onChanged: machinesOwned > 0
                          ? (_) => gameService.toggleAutoSell()
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (machinesOwned <= 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amberAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Auto-Sell Dispatchers must be acquired in the Machines tab to run automated shipping cycles.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Sheet Header for modal bottom sheet presentation
  Widget _buildSheetHeader(BuildContext context, ProductionGameService gameService) {
    final isEnabled = gameService.state.autoSellEnabled &&
        gameService.state.autoSellMachinesOwned > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.purpleAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selling Automation Setup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Storefront Fleet & B2B Rules',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Master switch
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEnabled ? 'ON' : 'OFF',
                style: TextStyle(
                  color: isEnabled ? Colors.purple[200] : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: isEnabled,
                  activeThumbColor: Colors.purpleAccent,
                  activeTrackColor: Colors.purple.withValues(alpha: 0.4),
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white10,
                  onChanged: gameService.state.autoSellMachinesOwned > 0
                      ? (_) => gameService.toggleAutoSell()
                      : null,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildLiveQueueCard(
    AutoSellNextAction action,
    ProductionGameService gameService,
  ) {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (action.actionType) {
      case AutoSellActionType.b2bContract:
        badgeColor = Colors.orangeAccent;
        badgeIcon = Icons.handshake_outlined;
        badgeText = 'B2B CONTRACT';
        break;
      case AutoSellActionType.batchDispatch:
        badgeColor = Colors.purpleAccent;
        badgeIcon = Icons.inventory_2_outlined;
        badgeText = 'STOREFRONT BATCH';
        break;
      case AutoSellActionType.waitingStock:
        badgeColor = Colors.amberAccent;
        badgeIcon = Icons.hourglass_empty;
        badgeText = 'WAITING STOCK';
        break;
      case AutoSellActionType.waitingFleet:
        badgeColor = Colors.blueAccent;
        badgeIcon = Icons.local_shipping_outlined;
        badgeText = 'FLEET BUSY';
        break;
      case AutoSellActionType.idleDisabled:
        badgeColor = Colors.white38;
        badgeIcon = Icons.pause_circle_outline;
        badgeText = 'AUTOMATION PAUSED';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2338),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 13, color: badgeColor),
                    const SizedBox(width: 5),
                    Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (action.isReady)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 12, color: Colors.greenAccent),
                      SizedBox(width: 3),
                      Text(
                        'DISPATCH READY',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            action.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            action.subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),

          // Items and estimated revenue row
          if (action.stagedItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Assembled Payload:',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      Text(
                        'Est. Revenue: \$${action.estimatedRevenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: action.stagedItems.entries.map((entry) {
                      final product = GameData.getProduct(entry.key);
                      final name = product?.name ?? entry.key;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GameIcon.forProduct(
                              id: entry.key,
                              fallbackEmoji: product?.emoji ?? '📦',
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$name x${entry.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDispatchRulesSection(ProductionGameService gameService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AUTOMATION DISPATCH RULES',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: const Color(0xFF1E2338),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Auto-Dispatch Storefront Batches',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Assembles whitelisted inventory into fleet shipments',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  value: gameService.state.autoSellBatchDispatch,
                  activeThumbColor: Colors.purpleAccent,
                  onChanged: (val) => gameService.setAutoSellBatchDispatch(val),
                ),
                const Divider(color: Colors.white10, height: 1),
                SwitchListTile(
                  title: const Text(
                    'Auto-Fulfill B2B Contracts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Fulfills corporate contracts when required stock is ready',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  value: gameService.state.autoSellFulfillContracts,
                  activeThumbColor: Colors.purpleAccent,
                  onChanged: (val) => gameService.setAutoSellFulfillContracts(val),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWhitelistMatrixSection(ProductionGameService gameService) {
    final whitelistedIds = gameService.state.autoSellWhitelistedProductIds;

    // Filter products
    List<Product> products = GameData.products;
    if (_selectedTierFilter != null) {
      products = products.where((p) => p.levelId == _selectedTierFilter).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      products = products
          .where((p) => p.name.toLowerCase().contains(q) || p.id.toLowerCase().contains(q))
          .toList();
    }

    // Partition products: Selected (pinned to top) vs Unselected
    // Order selected products with most recently selected first (based on whitelist insertion order)
    final whitelistList = whitelistedIds.toList();
    final selectedProductsMap = {
      for (final p in products.where((p) => whitelistedIds.contains(p.id))) p.id: p
    };

    final selectedProducts = <Product>[];
    for (int i = whitelistList.length - 1; i >= 0; i--) {
      final id = whitelistList[i];
      final prod = selectedProductsMap[id];
      if (prod != null) {
        selectedProducts.add(prod);
      }
    }
    // Any remaining selected products not captured in whitelistList
    for (final prod in selectedProductsMap.values) {
      if (!selectedProducts.contains(prod)) {
        selectedProducts.add(prod);
      }
    }

    final unselectedProducts =
        products.where((p) => !whitelistedIds.contains(p.id)).toList();

    // Combined list with selected products at the very top
    final sortedProducts = [...selectedProducts, ...unselectedProducts];

    // Lazy load slice
    final displayedProducts = sortedProducts.take(_displayedLimit).toList();
    final displayedSelected =
        displayedProducts.where((p) => whitelistedIds.contains(p.id)).toList();
    final displayedUnselected =
        displayedProducts.where((p) => !whitelistedIds.contains(p.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PRODUCT WHITELIST MATRIX',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${whitelistedIds.length}/${GameData.products.length} Whitelisted',
              style: TextStyle(
                color: whitelistedIds.isEmpty ? Colors.amberAccent : Colors.purple[200],
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Select products automation is permitted to sell. Unchecked items will never be sold.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),

        // Global Minimum Reserve Safeguard
        _buildMinimumReserveSubSection(gameService),
        const SizedBox(height: 14),

        // Bulk action buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildBulkButton(
                label: 'Select All',
                icon: Icons.done_all,
                onTap: () => gameService.setAllProductsAutoSellWhitelist(true),
              ),
              const SizedBox(width: 8),
              _buildBulkButton(
                label: 'Clear All',
                icon: Icons.clear_all,
                onTap: () => gameService.setAllProductsAutoSellWhitelist(false),
              ),
              const SizedBox(width: 8),
              _buildBulkButton(
                label: 'Retail Only',
                icon: Icons.store_outlined,
                onTap: () {
                  gameService.setTierAutoSellWhitelist(ProductLevel.basicParts, false);
                  gameService.setTierAutoSellWhitelist(ProductLevel.intermediate, false);
                  gameService.setTierAutoSellWhitelist(ProductLevel.complex, false);
                  gameService.setTierAutoSellWhitelist(ProductLevel.retail, true);
                },
              ),
              const SizedBox(width: 8),
              _buildBulkButton(
                label: 'Complex Only',
                icon: Icons.memory,
                onTap: () {
                  gameService.setTierAutoSellWhitelist(ProductLevel.basicParts, false);
                  gameService.setTierAutoSellWhitelist(ProductLevel.intermediate, false);
                  gameService.setTierAutoSellWhitelist(ProductLevel.complex, true);
                  gameService.setTierAutoSellWhitelist(ProductLevel.retail, false);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Tier filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTierChip('All', null),
              const SizedBox(width: 6),
              _buildTierChip('Basic', ProductLevel.basicParts),
              const SizedBox(width: 6),
              _buildTierChip('Intermediate', ProductLevel.intermediate),
              const SizedBox(width: 6),
              _buildTierChip('Complex', ProductLevel.complex),
              const SizedBox(width: 6),
              _buildTierChip('Retail', ProductLevel.retail),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Search Bar
        TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
              _displayedLimit = _batchSize;
            });
          },
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search products to whitelist...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _displayedLimit = _batchSize;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF1E2338),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.purple[300]!),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Product whitelist items
        if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No matching products found',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          )
        else
          Material(
            color: const Color(0xFF1E2338),
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Section 1: Selected / Whitelisted Items (Pinned to Top)
                  if (displayedSelected.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: Colors.purple.withValues(alpha: 0.15),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 14, color: Colors.purpleAccent),
                          const SizedBox(width: 6),
                          Text(
                            'SELECTED FOR AUTO-SELL (${selectedProducts.length})',
                            style: const TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Tap to unselect',
                            style: TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    for (int i = 0; i < displayedSelected.length; i++) ...[
                      if (i > 0) const Divider(color: Colors.white10, height: 1),
                      _buildProductRow(
                        product: displayedSelected[i],
                        isWhitelisted: true,
                        stock: gameService.state.getProductCount(displayedSelected[i].id),
                        gameService: gameService,
                      ),
                    ],
                  ],

                  // Section 2: Available Products
                  if (displayedUnselected.isNotEmpty) ...[
                    if (displayedSelected.isNotEmpty)
                      const Divider(color: Colors.white24, height: 1),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: Colors.white.withValues(alpha: 0.03),
                      child: Row(
                        children: [
                          const Icon(Icons.add_circle_outline, size: 14, color: Colors.white60),
                          const SizedBox(width: 6),
                          Text(
                            'AVAILABLE PRODUCTS (${unselectedProducts.length})',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Tap to enable & pin to top',
                            style: TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    for (int i = 0; i < displayedUnselected.length; i++) ...[
                      if (i > 0) const Divider(color: Colors.white10, height: 1),
                      _buildProductRow(
                        product: displayedUnselected[i],
                        isWhitelisted: false,
                        stock: gameService.state.getProductCount(displayedUnselected[i].id),
                        gameService: gameService,
                      ),
                    ],
                  ],

                  // Lazy Load Footer (if not all items are currently displayed)
                  if (displayedProducts.length < sortedProducts.length) ...[
                    const Divider(color: Colors.white10, height: 1),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1B1F33),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${displayedProducts.length} of ${sortedProducts.length} products',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _displayedLimit = sortedProducts.length;
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                'Show All',
                                style: TextStyle(
                                  color: Colors.purpleAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductRow({
    required Product product,
    required bool isWhitelisted,
    required int stock,
    required ProductionGameService gameService,
  }) {
    return RepaintBoundary(
      child: Material(
        color: isWhitelisted
            ? Colors.purple.withValues(alpha: 0.08)
            : Colors.transparent,
        child: InkWell(
          onTap: () => gameService.toggleProductAutoSellWhitelist(product.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Checkbox(
                  value: isWhitelisted,
                  activeColor: Colors.purpleAccent,
                  checkColor: Colors.white,
                  onChanged: (_) =>
                      gameService.toggleProductAutoSellWhitelist(product.id),
                ),
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: GameIcon.forProduct(
                    id: product.id,
                    fallbackEmoji: product.emoji,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          color: isWhitelisted ? Colors.white : Colors.white60,
                          fontSize: 13,
                          fontWeight: isWhitelisted ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '\$${product.sellPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: stock > 0
                                  ? Colors.blue.withValues(alpha: 0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Stock: $stock',
                              style: TextStyle(
                                color: stock > 0 ? Colors.blue[200] : Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Whitelist status indicator
                Icon(
                  isWhitelisted ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: isWhitelisted ? Colors.purpleAccent : Colors.white24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulkButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF242A42),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.purple[200]),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierChip(String label, ProductLevel? tier) {
    final isSelected = _selectedTierFilter == tier;
    return InkWell(
      onTap: () {
        if (_selectedTierFilter != tier) {
          setState(() {
            _selectedTierFilter = tier;
            _displayedLimit = _batchSize;
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.withValues(alpha: 0.3) : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.purpleAccent : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Global Minimum Stock Reserve Sub-Section
  Widget _buildMinimumReserveSubSection(ProductionGameService gameService) {
    final reserve = gameService.state.autoSellMinReserve;
    const presets = [0, 5, 10, 25, 50, 100];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2338),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reserve > 0
              ? Colors.purple.withValues(alpha: 0.35)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    reserve > 0 ? Icons.shield : Icons.shield_outlined,
                    size: 16,
                    color: reserve > 0 ? Colors.purpleAccent : Colors.white60,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Global Stock Reserve',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: reserve > 0
                      ? Colors.purple.withValues(alpha: 0.2)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: reserve > 0 ? Colors.purple[300]! : Colors.white24,
                  ),
                ),
                child: Text(
                  reserve > 0 ? 'Buffer: $reserve units' : 'Disabled (0)',
                  style: TextStyle(
                    color: reserve > 0 ? Colors.purple[200] : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Keep this amount in stock across all items. Only surplus stock above this threshold is auto-sold. (B2B contracts bypass this to avoid penalties).',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Stepper controls
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF242A42),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16, color: Colors.white70),
                      onPressed: reserve > 0
                          ? () => gameService.incrementAutoSellMinReserve(-1)
                          : null,
                      visualDensity: VisualDensity.compact,
                      splashRadius: 18,
                      tooltip: 'Decrease Reserve',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$reserve',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16, color: Colors.white70),
                      onPressed: () => gameService.incrementAutoSellMinReserve(1),
                      visualDensity: VisualDensity.compact,
                      splashRadius: 18,
                      tooltip: 'Increase Reserve',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Quick Presets
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: presets.map((val) {
                      final isSelected = reserve == val;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => gameService.setAutoSellMinReserve(val),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.purple.withValues(alpha: 0.3)
                                  : const Color(0xFF242A42),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? Colors.purpleAccent : Colors.white12,
                              ),
                            ),
                            child: Text(
                              val == 0 ? '0 (Off)' : '$val',
                              style: TextStyle(
                                color: isSelected ? Colors.purple[100] : Colors.white70,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Recent Automation Dispatches Activity Log Card
  Widget _buildRecentAutoSoldLogCard(ProductionGameService gameService) {
    final logs = gameService.state.autoSellRecentLog;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2338),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white12,
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: Colors.purpleAccent,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'RECENT AUTOMATION DISPATCHES',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              if (logs.isNotEmpty)
                Text(
                  '${logs.length} Logged',
                  style: TextStyle(
                    color: Colors.purple[200],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (logs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 28, color: Colors.white24),
                  SizedBox(height: 8),
                  Text(
                    'No automated dispatches recorded yet',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'When dispatchers run storefront batches or fulfill B2B contracts, the latest 10 sales appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 16),
              itemBuilder: (context, index) {
                final entry = logs[index];
                final isContract = entry.actionType == AutoSellActionType.b2bContract;
                final badgeColor = isContract ? Colors.orangeAccent : Colors.purpleAccent;
                final badgeIcon =
                    isContract ? Icons.handshake_outlined : Icons.inventory_2_outlined;
                final badgeText = isContract ? 'B2B CONTRACT' : 'STOREFRONT';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, size: 10, color: badgeColor),
                              const SizedBox(width: 4),
                              Text(
                                badgeText,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.clientOrBatchName ?? entry.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '+ \$${entry.totalRevenue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: entry.items.entries.map((item) {
                              final product = GameData.getProduct(item.key);
                              final name = product?.name ?? item.key;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GameIcon.forProduct(
                                      id: item.key,
                                      fallbackEmoji: product?.emoji ?? '📦',
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$name x${item.value}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(entry.timestamp),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 45) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
  }
}
