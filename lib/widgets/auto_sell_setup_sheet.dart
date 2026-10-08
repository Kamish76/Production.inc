import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auto_sell_preview.dart';
import '../models/game_data.dart';
import '../models/game_models.dart' hide Material;
import '../services/production_game_service.dart';
import 'game_icon.dart';

/// Modal bottom sheet for configuring Selling Automation rules,
/// live queue preview, and the product whitelist matrix.
class AutoSellSetupSheet extends StatefulWidget {
  const AutoSellSetupSheet({super.key});

  /// Displays the sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AutoSellSetupSheet(),
    );
  }

  @override
  State<AutoSellSetupSheet> createState() => _AutoSellSetupSheetState();
}

class _AutoSellSetupSheetState extends State<AutoSellSetupSheet> {
  ProductLevel? _selectedTierFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionGameService>(
      builder: (context, gameService, _) {
        final nextAction = gameService.getAutoSellNextAction();

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
                _buildHeader(context, gameService),

                const Divider(color: Colors.white12, height: 1),

                // Scrollable content
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // Section 1: Live Queue & Next Dispatch Card
                      _buildLiveQueueCard(nextAction, gameService),

                      const SizedBox(height: 16),

                      // Section 2: Automation Dispatch Rules
                      _buildDispatchRulesSection(gameService),

                      const SizedBox(height: 16),

                      // Section 3: Product Whitelist Matrix
                      _buildWhitelistMatrixSection(gameService),
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

  Widget _buildHeader(BuildContext context, ProductionGameService gameService) {
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
                    Icon(badgeIcon, color: badgeColor, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Couriers active badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_shipping, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${gameService.state.activeShippingOrders.length}/${gameService.state.maxSimultaneousShipments} Couriers',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
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
          const SizedBox(height: 2),
          Text(
            action.subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          if (action.isReady && action.stagedItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Chips showing staged items
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: action.stagedItems.entries.map((entry) {
                final prod = GameData.getProduct(entry.key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameIcon.forProduct(
                        id: entry.key,
                        fallbackEmoji: prod?.emoji ?? '📦',
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${prod?.name ?? entry.key} x${entry.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attach_money, color: Colors.greenAccent, size: 16),
                    Text(
                      action.estimatedRevenue.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.blueAccent, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      '~${action.estimatedTransitSeconds.toStringAsFixed(0)}s transit',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
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
        const SizedBox(height: 10),

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
          onChanged: (val) => setState(() => _searchQuery = val),
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
                      setState(() => _searchQuery = '');
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
              child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, index) {
                final product = products[index];
                final isWhitelisted = whitelistedIds.contains(product.id);
                final stock = gameService.state.getProductCount(product.id);

                return InkWell(
                  onTap: () => gameService.toggleProductAutoSellWhitelist(product.id),
                  borderRadius: index == 0
                      ? const BorderRadius.vertical(top: Radius.circular(14))
                      : index == products.length - 1
                          ? const BorderRadius.vertical(bottom: Radius.circular(14))
                          : BorderRadius.zero,
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
                );
              },
            ),
          ),
        ),
      ],
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
      onTap: () => setState(() => _selectedTierFilter = tier),
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
}
