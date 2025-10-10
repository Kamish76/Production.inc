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
        // Auto-Build dev controls (v1.5.0 Phase 2)
        if (tierKey != null) _buildAutoBuildDevControls(gameService, tierKey, tierName),
        
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

  /// Build auto-build machine dev controls (v1.5.0 Phase 2 - temporary for development)
  Widget _buildAutoBuildDevControls(ProductionGameService gameService, String tier, String tierName) {
    final machineCount = gameService.state.autoBuildMachinesOwned[tier] ?? 0;
    final enabled = gameService.state.autoBuildEnabled[tier] ?? false;
    final capacity = gameService.state.autoBuildProductCapacity[tier] ?? 10;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dev mode header
          Row(
            children: [
              Icon(Icons.construction, color: Colors.orange[400], size: 20),
              const SizedBox(width: 8),
              Text(
                'AUTO-BUILD: $tierName (DEV MODE)',
                style: TextStyle(
                  color: Colors.orange[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Machine count controls
          Row(
            children: [
              const Text(
                'Machines:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(width: 12),
              
              // Decrement button
              IconButton(
                onPressed: machineCount > 0
                    ? () => gameService.decrementAutoBuildMachines(tier)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red[400],
                disabledColor: Colors.grey,
                iconSize: 28,
              ),
              
              // Count display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$machineCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Increment button
              IconButton(
                onPressed: () => gameService.incrementAutoBuildMachines(tier),
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.green[400],
                iconSize: 28,
              ),
              
              const Spacer(),
              
              // On/Off toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: enabled
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: enabled ? Colors.green : Colors.red,
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
                        enabled
                            ? Icons.power_settings_new
                            : Icons.power_off,
                        color: enabled ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        enabled ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: enabled ? Colors.green : Colors.red,
                          fontSize: 14,
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

          // Capacity controls
          Row(
            children: [
              const Text(
                'Capacity:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(width: 12),
              
              // Decrement button
              IconButton(
                onPressed: capacity > 10
                    ? () => gameService.decreaseAutoBuildCapacity(tier)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red[400],
                disabledColor: Colors.grey,
                iconSize: 28,
              ),
              
              // Capacity display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$capacity',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Increment button
              IconButton(
                onPressed: () => gameService.increaseAutoBuildCapacity(tier),
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.green[400],
                iconSize: 28,
              ),
              
              const SizedBox(width: 8),
              
              // Info text
              Expanded(
                child: Text(
                  'per product',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          
          // Info text
          if (machineCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Building ${machineCount * 2} products every 5s${enabled ? " (active)" : " (paused)"}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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
