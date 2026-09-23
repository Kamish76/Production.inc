import 'package:flutter/material.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';
import '../constants/game_constants.dart';
import '../services/production_game_service.dart';

/// Card widget that displays the Initial Public Offering (IPO / Prestige) Launchpad,
/// Corporate Valuation breakdown, Venture Perks store, and Prototype Blueprints showcase.
class PrestigeCard extends StatelessWidget {
  final ProductionGameService gameService;

  const PrestigeCard({
    super.key,
    required this.gameService,
  });

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '\$$whole.${parts[1]}';
  }

  String _formatCompact(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Golden Shares & Global Boost Banner
        _buildPrestigeHeaderBanner(context),
        const SizedBox(height: 16),

        // 2. IPO Valuation & Launchpad
        _buildIpoLaunchpadCard(context),
        const SizedBox(height: 16),

        // 3. Venture Perks Store
        _buildVenturePerksSection(context),
        const SizedBox(height: 16),

        // 4. Prototype Tech Blueprints Showcase
        _buildPrototypeShowcase(context),
      ],
    );
  }

  /// Header displaying current Golden Shares, global production speed boost, and lifetime stats
  Widget _buildPrestigeHeaderBanner(BuildContext context) {
    final state = gameService.state;
    final speedBoostPercent = (state.goldenShares * PrestigeConstants.speedBoostPerGoldenShare * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2006), Color(0xFF1E1700), Color(0xFF131722)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD54F),
                    width: 1.5,
                  ),
                ),
                child: const Text('🌟', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRODUCTION.INC HOLDINGS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${state.goldenShares}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Golden Shares',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFE082),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Global Speed Multiplier Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFB300).withValues(alpha: 0.3),
                      const Color(0xFFFF8F00).withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'BUILD SPEED',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+$speedBoostPercent%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0x33FFD54F), height: 1),
          const SizedBox(height: 12),
          // Lifetime metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricStat('Completed IPOs', '${state.prestigeCount}'),
              _buildMetricStat('Lifetime Shares', '${state.lifetimeGoldenShares}'),
              _buildMetricStat('Perks Owned', '${state.unlockedPrestigePerks.length} / ${GameData.prestigePerks.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFFFFECB3),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// IPO Launchpad card showing Valuation breakdown, progress to $1M, and Ring Bell action
  Widget _buildIpoLaunchpadCard(BuildContext context) {
    final state = gameService.state;
    final netWorth = state.netWorth;
    final progress = (netWorth / PrestigeConstants.ipoNetWorthThreshold).clamp(0.0, 1.0);
    final canIPO = state.canInitiateIPO;
    final pendingShares = state.pendingGoldenShares;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2433),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canIPO
              ? const Color(0xFFFFB300)
              : Colors.cyan.withValues(alpha: 0.25),
          width: canIPO ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                canIPO ? Icons.campaign : Icons.trending_up,
                color: canIPO ? const Color(0xFFFFD54F) : Colors.cyan[300],
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                'Initial Public Offering (IPO)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (canIPO)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: const Text(
                    'ELIGIBLE 🔔',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Liquidate and take Production.INC public on Wall Street once Net Worth reaches \$1,000,000. Earn Golden Shares based on total corporate valuation and shipped goods.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // Valuation Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Corporate Net Worth: ${_formatCurrency(netWorth)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: canIPO ? const Color(0xFFFFD54F) : Colors.cyan[300],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                canIPO ? const Color(0xFFFFB300) : Colors.cyan[400]!,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Goal: \$1,000,000.00',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              if (!canIPO)
                Text(
                  '${_formatCurrency(PrestigeConstants.ipoNetWorthThreshold - netWorth)} remaining',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Asset Breakdown Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FINANCIAL ASSET VALUATION',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildAssetTile(
                        icon: Icons.payments,
                        label: 'Cash on Hand',
                        value: _formatCompact(state.money),
                      ),
                    ),
                    Expanded(
                      child: _buildAssetTile(
                        icon: Icons.category,
                        label: 'Raw Materials',
                        value: _formatCompact(state.totalMaterialsMarketValue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildAssetTile(
                        icon: Icons.inventory_2,
                        label: 'Warehouse Stock',
                        value: _formatCompact(state.totalProductsMarketValue),
                      ),
                    ),
                    Expanded(
                      child: _buildAssetTile(
                        icon: Icons.precision_manufacturing,
                        label: 'Machine Capital',
                        value: _formatCompact(state.totalMachineCapitalValue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Projected Return & Ring the Bell Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: canIPO
                  ? const Color(0xFFFFB300).withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: canIPO
                    ? const Color(0xFFFFD54F).withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                const Text('🌟', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Projected IPO Yield',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        canIPO
                            ? '+$pendingShares Golden Shares'
                            : '0 Golden Shares (Reach \$1.0M)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: canIPO ? const Color(0xFFFFD54F) : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: canIPO ? () => _showIpoConfirmationDialog(context) : null,
              icon: const Text('🔔', style: TextStyle(fontSize: 18)),
              label: Text(
                canIPO
                    ? 'Ring Bell & Go Public (+$pendingShares 🌟)'
                    : 'IPO Locked (Needs ${_formatCompact(PrestigeConstants.ipoNetWorthThreshold)})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: Colors.black87,
                disabledBackgroundColor: Colors.grey[850],
                disabledForegroundColor: Colors.white30,
                elevation: canIPO ? 6 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.cyan[300]),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white54),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Venture Perks store listing all perks available for purchase with Golden Shares
  Widget _buildVenturePerksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('💼', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            const Text(
              'Venture Perks Catalog',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              'Spend 🌟 Shares',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber[200],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...GameData.prestigePerks.map((perk) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPerkCard(context, perk),
        )),
      ],
    );
  }

  Widget _buildPerkCard(BuildContext context, PrestigePerk perk) {
    final state = gameService.state;
    final isUnlocked = state.hasPrestigePerk(perk.id);
    final canAfford = state.goldenShares >= perk.goldenShareCost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? const Color(0xFF1B2A1E)
            : const Color(0xFF1E2433),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnlocked
              ? Colors.greenAccent.withValues(alpha: 0.6)
              : canAfford
                  ? const Color(0xFFFFD54F).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(perk.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perk.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      perk.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Highlights
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: perk.perkHighlights.map((highlight) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 13, color: Color(0xFFFFD54F)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        highlight,
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🌟', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    'Cost: ${perk.goldenShareCost} Golden Shares',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? Colors.white54
                          : (canAfford ? const Color(0xFFFFD54F) : Colors.white54),
                    ),
                  ),
                ],
              ),
              if (isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check, size: 14, color: Colors.greenAccent),
                      SizedBox(width: 4),
                      Text(
                        'ACQUIRED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: canAfford ? () => _buyPerk(context, perk) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey[800],
                    disabledForegroundColor: Colors.white30,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    canAfford ? 'Acquire Perk' : 'Need ${perk.goldenShareCost} 🌟',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Prototype Blueprints Showcase
  Widget _buildPrototypeShowcase(BuildContext context) {
    final state = gameService.state;
    final hasBlueprintPerk = state.hasPrestigePerk(PrestigeConstants.perkPrototypeBlueprints);
    final prototypes = GameData.products.where((p) => p.isPrototype).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasBlueprintPerk
              ? Colors.cyanAccent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔬', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'Prototype Flagship Blueprints',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasBlueprintPerk
                      ? Colors.cyan.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: hasBlueprintPerk ? Colors.cyanAccent : Colors.orangeAccent,
                  ),
                ),
                child: Text(
                  hasBlueprintPerk ? 'ACTIVE ⚡' : 'PERK REQUIRED 🔒',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hasBlueprintPerk ? Colors.cyanAccent : Colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Cutting-edge prototypes designed for mega-scale valuations. Quantum computing components and the flagship Orbital Satellite deliver extraordinary revenues.',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
          ),
          const SizedBox(height: 14),

          ...prototypes.map((proto) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasBlueprintPerk
                    ? Colors.cyan.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    proto.id == 'orbital_satellite' ? '🛰️' : '⚛️',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proto.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        proto.id == 'orbital_satellite'
                            ? 'Requires Factory Tier 4 (Megafactory)'
                            : '${proto.levelId.name.toUpperCase()} Prototype',
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(proto.sellPrice),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                    Text(
                      '${proto.productionTimeSeconds.toStringAsFixed(1)}s build',
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// Buy a perk with confirmation and instant feedback
  Future<void> _buyPerk(BuildContext context, PrestigePerk perk) async {
    final success = await gameService.unlockPrestigePerk(perk.id);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🌟 Acquired ${perk.name}!'),
          backgroundColor: Colors.green[800],
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not unlock perk. Insufficient Golden Shares.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Confirmation dialog before taking the company public
  void _showIpoConfirmationDialog(BuildContext context) {
    final state = gameService.state;
    final pendingShares = state.pendingGoldenShares;
    final willReceiveAngel = state.hasPrestigePerk(PrestigeConstants.perkAngelSeedCapital);
    final startingCash = willReceiveAngel
        ? PrestigeConstants.angelSeedCapitalAmount
        : 100.0;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2433),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('🔔', style: TextStyle(fontSize: 26)),
            SizedBox(width: 10),
            Text(
              'Ring the Opening Bell?',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Production.INC is preparing its Initial Public Offering on Wall Street with a Net Worth of ${_formatCurrency(state.netWorth)}.',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),

            // Yield card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: Row(
                children: [
                  const Text('🌟', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Golden Shares Awarded',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                      Text(
                        '+$pendingShares Shares (+${pendingShares * 10}% Speed)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD54F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // What resets vs persists
            const Text(
              'WHAT RESETS:',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '• Cash resets to ${_formatCurrency(startingCash)}${willReceiveAngel ? " (Angel Investor boost!)" : ""}\n'
              '• Raw materials and warehouse inventories\n'
              '• Active productions and pending shipments\n'
              '• Standard machinery, Factory & Fleet tiers to Tier 1\n'
              '• Research Points and Tech Tree levels',
              style: const TextStyle(fontSize: 12, color: Colors.white60, height: 1.3),
            ),
            const SizedBox(height: 12),

            const Text(
              'WHAT PERSISTS (FOREVER):',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '• All Golden Shares (cumulative +10% build speed)\n'
              '• All purchased Venture Perks & Prototypes\n'
              '• All client reputation standings\n'
              '• All-time career statistics',
              style: TextStyle(fontSize: 12, color: Colors.white60, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final success = await gameService.initiateIPO();
              if (context.mounted && success) {
                _showIpoCelebrationDialog(context, pendingShares, startingCash);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Confirm IPO 🔔',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Celebratory dialog shown upon successful IPO
  void _showIpoCelebrationDialog(BuildContext context, int sharesAwarded, double startingCash) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131722),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFD54F), width: 2),
        ),
        title: const Column(
          children: [
            Text('🎊 🔔 🌟', style: TextStyle(fontSize: 32)),
            SizedBox(height: 10),
            Text(
              'PRODUCTION.INC IS PUBLIC!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'The opening bell has rung on Wall Street! Your industrial empire has officially completed its Initial Public Offering.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    '+$sharesAwarded Golden Shares',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD54F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+${sharesAwarded * 10}% Permanent Global Build Speed',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Starting Seed Capital: ${_formatCurrency(startingCash)}',
                    style: const TextStyle(fontSize: 12, color: Colors.greenAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Begin Next Chapter 🚀',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
