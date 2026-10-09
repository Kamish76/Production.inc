import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;
import '../models/auto_sell_log_entry.dart';
import '../utils/responsive_utils.dart';
import '../widgets/screen_header.dart';
import '../widgets/financial_status_display.dart';
import '../widgets/message_display.dart';
import '../widgets/tier_expansion_panel.dart';
import '../widgets/item_card.dart';
import '../widgets/game_dialog.dart';
import '../widgets/client_reputation_bar.dart';
import '../widgets/shipping_manifest_tray.dart';
import '../widgets/auto_sell_status_card.dart';
import '../widgets/machine_setup_view.dart';
import '../widgets/lazy_tab_loader.dart';
import '../widgets/game_icon.dart';
import '../models/game_data.dart';

class SellProductsScreen extends StatefulWidget {
  const SellProductsScreen({super.key});

  @override
  State<SellProductsScreen> createState() => _SellProductsScreenState();
}

class _SellProductsScreenState extends State<SellProductsScreen>
    with TickerProviderStateMixin {
  Map<String, bool> _tierExpanded = {};
  game.IndustryBranch? _selectedBranch;
  late TabController _mainTabController;
  late TabController _b2bSubTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _b2bSubTabController = TabController(length: 3, vsync: this);
    _loadTierPreferences();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _b2bSubTabController.dispose();
    super.dispose();
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
      margin: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
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

  void _openAutomationSetup(BuildContext context) {
    _mainTabController.animateTo(2);
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
                ScreenHeader(
                  icon: Icons.attach_money,
                  title: 'Sales Hub',
                  iconColor: Colors.purple[400]!,
                  actions: [
                    InkWell(
                      onTap: () => _openAutomationSetup(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: gameService.state.autoSellEnabled && gameService.state.autoSellMachinesOwned > 0
                              ? Colors.purple.withValues(alpha: 0.25)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: gameService.state.autoSellEnabled && gameService.state.autoSellMachinesOwned > 0
                                ? Colors.purple[300]!
                                : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.smart_toy_outlined,
                              size: 16,
                              color: gameService.state.autoSellEnabled && gameService.state.autoSellMachinesOwned > 0
                                  ? Colors.purple[300]
                                  : Colors.white60,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              gameService.state.autoSellEnabled && gameService.state.autoSellMachinesOwned > 0
                                  ? 'Auto: ON'
                                  : 'Auto: OFF',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: gameService.state.autoSellEnabled && gameService.state.autoSellMachinesOwned > 0
                                    ? Colors.purple[200]
                                    : Colors.white60,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.tune, size: 14, color: Colors.white54),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Main TabBar: Storefront | B2B Contracts
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2438),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TabBar(
                    controller: _mainTabController,
                    indicator: BoxDecoration(
                      color: Colors.purple[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[400],
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.storefront, size: 18),
                        text: 'Storefront',
                      ),
                      Tab(
                        icon: Icon(Icons.handshake_outlined, size: 18),
                        text: 'B2B Contracts',
                      ),
                      Tab(
                        icon: Icon(Icons.precision_manufacturing_outlined, size: 18),
                        text: 'Machine Setup',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Tab content (Storefront eager, Contracts & Setup lazy)
                Expanded(
                  child: TabBarView(
                    controller: _mainTabController,
                    children: [
                      _buildStorefrontTab(gameService),
                      LazyTabLoader(
                        index: 1,
                        controller: _mainTabController,
                        builder: (ctx) => _buildB2BContractsTab(ctx, gameService),
                      ),
                      LazyTabLoader(
                        index: 2,
                        controller: _mainTabController,
                        builder: (_) => const MachineSetupView(),
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

  Widget _buildStorefrontTab(ProductionGameService gameService) {
    return Column(
      children: [
        // Phase 3: Industry Branch Filter Bar with expand/collapse toggle
        Row(
          children: [
            Expanded(child: _buildIndustryBranchFilterBar()),
            IconButton(
              onPressed: _toggleAllTiers,
              tooltip:
                  _areAllTiersExpanded() ? 'Collapse All' : 'Expand All',
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
            const SizedBox(width: 8),
          ],
        ),

        const SizedBox(height: 6),

        // Money and portfolio display
        FinancialStatusDisplay(
          gameService: gameService,
          mode: FinancialDisplayMode.portfolio,
        ),

        const SizedBox(height: 8),

        // Phase 12: Sales Hub Selling Automation Live Status Card
        AutoSellStatusCard(
          onOpenSetup: () => _openAutomationSetup(context),
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
          Expanded(
            child: Builder(
              builder: (context) {
                final visibleTierEntries = gameService.productsByTier.entries
                    .where((entry) => entry.value.any((product) {
                      if (_selectedBranch != null && product.industryBranch != _selectedBranch) {
                        return false;
                      }
                      return gameService.state.getProductCount(product.id) > 0;
                    }))
                    .toList();

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    gameService.stagedManifest.isNotEmpty ? 80 : 16,
                  ),
                  itemCount: visibleTierEntries.length,
                  itemBuilder: (context, index) {
                    final entry = visibleTierEntries[index];
                    return _buildEnhancedTierSection(
                      context,
                      gameService.getTierName(entry.key),
                      entry.value,
                      gameService,
                    ) ?? const SizedBox.shrink();
                  },
                );
              },
            ),
          ),

        // Phase 11: Docked Commercial Dispatch Manifest Tray
        const ShippingManifestTray(),
      ],
    );
  }

  Widget _buildB2BContractsTab(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    return Column(
      children: [
        // Auto-Ship Toggle Header
        _buildAutoShipToggles(gameService),

        const SizedBox(height: 8),

        // Client Reputation Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClientReputationBar(gameService: gameService),
        ),

        const SizedBox(height: 8),

        // Subtab filter: All | Retail | Manufacturing
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1E30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: TabBar(
            controller: _b2bSubTabController,
            indicator: BoxDecoration(
              color: Colors.purple[700],
              borderRadius: BorderRadius.circular(6),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[500],
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            tabs: const [
              Tab(text: '📋 All'),
              Tab(text: '🏷️ Retail'),
              Tab(text: '🏭 Manufacturing'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Contract list filtered by subtab
        Expanded(
          child: TabBarView(
            controller: _b2bSubTabController,
            children: [
              _buildContractList(context, gameService, null),
              _buildContractList(context, gameService, game.ContractType.retail),
              _buildContractList(
                context,
                gameService,
                game.ContractType.manufacturing,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutoShipToggles(ProductionGameService gameService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2438),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.autorenew, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          const Text(
            'Auto-Ship:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          // Retail toggle
          Expanded(
            child: InkWell(
              onTap: () => gameService.toggleAutoShipRetail(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gameService.state.autoShipRetail
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: gameService.state.autoShipRetail
                        ? Colors.blue[400]!
                        : Colors.white24,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🏷️ Retail',
                      style: TextStyle(
                        fontSize: 11,
                        color: gameService.state.autoShipRetail
                            ? Colors.blue[300]
                            : Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      gameService.state.autoShipRetail
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 14,
                      color: gameService.state.autoShipRetail
                          ? Colors.blue[400]
                          : Colors.white38,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Manufacturing toggle
          Expanded(
            child: InkWell(
              onTap: () => gameService.toggleAutoShipManufacturing(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gameService.state.autoShipManufacturing
                      ? Colors.amber.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: gameService.state.autoShipManufacturing
                        ? Colors.amber[600]!
                        : Colors.white24,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🏭 Mfg',
                      style: TextStyle(
                        fontSize: 11,
                        color: gameService.state.autoShipManufacturing
                            ? Colors.amber[300]
                            : Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      gameService.state.autoShipManufacturing
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 14,
                      color: gameService.state.autoShipManufacturing
                          ? Colors.amber[600]
                          : Colors.white38,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractList(
    BuildContext context,
    ProductionGameService gameService,
    game.ContractType? filterType,
  ) {
    final contracts = gameService.state.corporateContracts;

    // Filter by type if specified
    final filtered = filterType == null
        ? contracts
        : contracts.where((c) => c.contractType == filterType).toList();

    // Available contracts (Available to review and ship)
    final available = filtered
        .where((c) =>
            c.status == game.ContractStatus.available ||
            c.status == game.ContractStatus.active)
        .toList()
      ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));

    // Shipping contracts (Currently in transit on fleet couriers)
    final shipping = filtered
        .where((c) => c.status == game.ContractStatus.shipping)
        .toList();

    // Completed contracts
    final completed = filtered
        .where((c) => c.status == game.ContractStatus.completed)
        .toList()
      ..sort((a, b) =>
          (b.completedAt ?? b.expiresAt).compareTo(a.completedAt ?? a.expiresAt));

    // Older automation dispatches (overflow beyond the top 3 shown in Machine Setup)
    final olderAutoDispatches = gameService.state.autoSellRecentLog.length > 3
        ? gameService.state.autoSellRecentLog.sublist(3)
        : <AutoSellLogEntry>[];

    final totalCompletedCount = completed.length + olderAutoDispatches.length;

    if (available.isEmpty && shipping.isEmpty && totalCompletedCount == 0) {
      return const MessageDisplay.empty(
        icon: Icons.handshake_outlined,
        title: 'No Contracts Available',
        subtitle: 'New contracts will appear shortly.',
      );
    }

    final maxSlots = gameService.state.maxContractSlots;
    final emptySlots = math.max(0, maxSlots - available.length);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      children: [
        // Slot info & Active Contracts Header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.assignment, color: Colors.purple[300], size: 16),
              const SizedBox(width: 6),
              Text(
                'Active Contracts (${available.length} / $maxSlots)',
                style: TextStyle(
                  color: Colors.purple[300],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '🚚 Fleet: ${gameService.state.activeShippingOrders.length} / ${gameService.state.maxSimultaneousShipments}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),

        // Active contracts
        ...available.map(
          (contract) => _buildContractCard(context, contract, gameService),
        ),

        // Replenishment buffer slot cards (generating new contract in 3s)
        if (emptySlots > 0)
          ...List.generate(emptySlots, (index) {
            final seconds = gameService.nextContractRefillSeconds;
            final timeLabel = seconds != null && seconds > 0
                ? '${seconds.toStringAsFixed(1)}s'
                : '3.0s';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purpleAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Acquiring New B2B Contract...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Client requisition incoming in $timeLabel',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      timeLabel,
                      style: TextStyle(
                        color: Colors.purple[200],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

        // In Transit / Shipping contracts (PULLED DOWN BELOW ACTIVE CONTRACTS)
        if (shipping.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.local_shipping,
                    color: Colors.orangeAccent, size: 16),
                const SizedBox(width: 6),
                Text(
                  'In Transit (${shipping.length})',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Couriers En Route',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          ...shipping.map(
            (contract) =>
                _buildShippingContractCard(context, contract, gameService),
          ),
        ],

        // Completed contracts accordion
        if (totalCompletedCount > 0) ...[
          const SizedBox(height: 10),
          ExpansionTile(
            initiallyExpanded: false,
            maintainState: false,
            title: Text(
              'Completed Requisitions ($totalCompletedCount)',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            subtitle: olderAutoDispatches.isNotEmpty
                ? Text(
                    '${completed.length} corporate contracts • ${olderAutoDispatches.length} auto dispatches',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  )
                : null,
            iconColor: Colors.white54,
            collapsedIconColor: Colors.white38,
            children: [
              ...completed.map(
                (contract) =>
                    _buildContractCard(context, contract, gameService),
              ),
              ...olderAutoDispatches.map(
                (dispatch) => _buildCompletedDispatchCard(context, dispatch),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildShippingContractCard(
    BuildContext context,
    game.CorporateContract contract,
    ProductionGameService gameService,
  ) {
    final client = GameData.getCorporateClient(contract.clientId);
    final isRetail = contract.contractType == game.ContractType.retail;
    final badgeLabel = isRetail ? '🏷️ RETAIL' : '🏭 MFG';

    // Look up active shipping order for live delivery progress
    final matchingOrder = gameService.state.activeShippingOrders
        .cast<game.ShippingOrder?>()
        .firstWhere(
          (o) =>
              o?.contractId == contract.id ||
              (contract.shippingOrderId != null && o?.id == contract.shippingOrderId),
          orElse: () => null,
        );

    final progress = matchingOrder?.progress ?? 0.0;
    final remainingSeconds = matchingOrder?.remainingTime ?? 0.0;
    final remainingText = remainingSeconds > 60
        ? '${(remainingSeconds / 60).ceil()}m remaining'
        : '${remainingSeconds.toStringAsFixed(1)}s remaining';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E243A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Client + Badge + Transit pill
            Row(
              children: [
                Text(client?.emoji ?? '📋', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        client?.name ?? '',
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping, color: Colors.orange, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'In Transit',
                        style: TextStyle(
                          color: Colors.orange[300],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Shipped products summary
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: contract.requiredProducts.entries.map((entry) {
                final product = GameData.getProduct(entry.key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${product?.emoji ?? "📦"} ${product?.name ?? entry.key} x${entry.value}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            // Live Courier Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery Transit',
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                    Text(
                      remainingText,
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Reward preview
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Reward: +\$${contract.cashReward.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.green[300],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${contract.repReward} Rep',
                    style: TextStyle(
                      color: Colors.purple[300],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  badgeLabel,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedDispatchCard(
    BuildContext context,
    AutoSellLogEntry dispatch,
  ) {
    final isContract = dispatch.actionType == AutoSellActionType.b2bContract;
    final badgeColor = isContract ? Colors.orangeAccent : Colors.purpleAccent;
    final badgeText = isContract ? 'B2B CONTRACT' : 'STOREFRONT';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2238),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 0.8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dispatch.clientOrBatchName ?? dispatch.title,
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
                '+\$${dispatch.totalRevenue.toStringAsFixed(2)}',
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
                  children: dispatch.items.entries.map((item) {
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
                            size: 11,
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
                '${dispatch.timestamp.hour.toString().padLeft(2, "0")}:${dispatch.timestamp.minute.toString().padLeft(2, "0")}',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(
    BuildContext context,
    game.CorporateContract contract,
    ProductionGameService gameService,
  ) {
    final client = GameData.getCorporateClient(contract.clientId);
    final isRetail = contract.contractType == game.ContractType.retail;
    final badgeColor = isRetail ? Colors.blue : Colors.amber;
    final badgeLabel = isRetail ? '🏷️ RETAIL' : '🏭 MFG';
    final canFulfill = contract.canFulfill(gameService.state.products);
    final hasFleetSlot = gameService.state.canShipMore(
      gameService.state.activeShippingOrders.length,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E2742),
            Color(isRetail ? 0xFF1A2540 : 0xFF2A2520),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: contract.isShipping
              ? Colors.orange.withValues(alpha: 0.5)
              : badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Client + Badge + Timer
            Row(
              children: [
                Text(client?.emoji ?? '📋', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        client?.name ?? '',
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: badgeColor[300],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Required products list
            ...contract.requiredProducts.entries.map((entry) {
              final product = GameData.getProduct(entry.key);
              final owned = gameService.state.getProductCount(entry.key);
              final needed = entry.value;
              final hasEnough = owned >= needed;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(product?.emoji ?? '📦', style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${product?.name ?? entry.key}: $needed needed',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasEnough
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hasEnough ? '$owned ✅' : '$owned / $needed ❌',
                        style: TextStyle(
                          color: hasEnough ? Colors.green[300] : Colors.red[300],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 10),

            // Footer: Rewards + Timer/Status + Action Button
            Row(
              children: [
                // Rewards
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '\$${contract.cashReward.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.green[300],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${contract.repReward} Rep',
                    style: TextStyle(
                      color: Colors.purple[300],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                // Status / Action
                if (contract.status == game.ContractStatus.completed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text('Honored', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                else if (contract.isShipping)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping, color: Colors.orange, size: 14),
                        SizedBox(width: 4),
                        Text('In Transit', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                else ...[
                  // Timer
                  Text(
                    '${contract.remainingDuration.inMinutes}m',
                    style: TextStyle(
                      color: contract.remainingDuration.inMinutes < 5
                          ? Colors.red[300]
                          : Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Ship button
                  ElevatedButton.icon(
                    onPressed: canFulfill && hasFleetSlot
                        ? () => gameService.shipContract(contract.id)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canFulfill && hasFleetSlot
                          ? Colors.green[700]
                          : Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.local_shipping, size: 14),
                    label: Text(
                      canFulfill
                          ? (hasFleetSlot ? 'Ship' : 'Fleet Full')
                          : 'Need Stock',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
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
      contentBuilder: (_) => Column(
        children: [
          // Responsive row-grid matching TierContentWidget
          LayoutBuilder(
            builder: (context, constraints) {
              final columnsCount =
                  ResponsiveUtils.getGridColumnCount(constraints.maxWidth);
              const spacing = ResponsiveUtils.defaultGridSpacing;

              // Group products into rows based on dynamic column count
              final rows = <List<game.Product>>[];
              for (int i = 0; i < availableProducts.length; i += columnsCount) {
                final end = (i + columnsCount < availableProducts.length)
                    ? i + columnsCount
                    : availableProducts.length;
                rows.add(availableProducts.sublist(i, end));
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
                                    mode: ItemCardMode.sell,
                                    onProductDetails: () => showDialog(
                                      context: context,
                                      builder: (context) =>
                                          GameDialog.productDetails(
                                        product: rowProducts[i],
                                        gameService: gameService,
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
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
