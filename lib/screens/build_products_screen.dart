import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;
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
                ProductionStatusPanel(gameService: gameService),

                const SizedBox(height: 16),

                // Products list - organized by tiers with unlock filtering
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Show welcome message for completely new players
                      if (gameService.state.unlockedProducts.isEmpty)
                        const MessageDisplay.welcome(),

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
    // Filter products to only show unlocked ones (v1.4.18)
    final unlockedProducts = products
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
          child: TierContentWidget(
            products: products,
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? Colors.blue.withValues(alpha: 77) : Colors.grey.withValues(alpha: 77),
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
                      ? Colors.blue.withValues(alpha: 51)
                      : Colors.red.withValues(alpha: 51),
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
                  color: Colors.cyan.withValues(alpha: 38),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.cyan.withValues(alpha: 77),
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
          
          // Info text
          const SizedBox(height: 8),
          Text(
            'Building ${machineCount * 2} products every 5s${enabled ? " (active)" : " (paused)"}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 128),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
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
