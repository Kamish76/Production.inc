import 'package:flutter/material.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';
import '../services/production_game_service.dart';

/// Card widget that displays the current factory tier, next tier upgrade
/// requirements, and the full roadmap of factory expansion licenses.
class FactoryTierCard extends StatelessWidget {
  final ProductionGameService gameService;

  const FactoryTierCard({
    super.key,
    required this.gameService,
  });

  @override
  Widget build(BuildContext context) {
    final currentTier = gameService.currentFactoryTier;
    final nextTier = gameService.nextFactoryTier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Current License Status Card
        _buildCurrentTierCard(context, currentTier),

        const SizedBox(height: 16),

        // 2. Next Tier Upgrade / Max Tier Banner
        if (nextTier != null)
          _buildNextTierUpgradeCard(context, nextTier)
        else
          _buildMaxTierBanner(context, currentTier),

        const SizedBox(height: 16),

        // 3. Factory Progression Roadmap
        _buildRoadmapCard(context, currentTier),
      ],
    );
  }

  /// Card displaying the currently active factory license and perks
  Widget _buildCurrentTierCard(BuildContext context, FactoryTier currentTier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2A1B4E).withValues(alpha: 0.9),
            const Color(0xFF1E1538).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.purple[300]!.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  currentTier.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple[700],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'TIER ${currentTier.tierNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ACTIVE LICENSE',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentTier.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
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
            currentTier.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // Active perks pill list
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildPerkPill(
                icon: Icons.inventory_2_outlined,
                label: 'Auto-Buy Cap: ${currentTier.autoBuyCapacityLimit}u',
              ),
              ...currentTier.perkHighlights.map(
                (p) => _buildPerkPill(icon: Icons.check_circle_outline, label: p),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card displaying requirements and action button for the next tier
  Widget _buildNextTierUpgradeCard(BuildContext context, FactoryTier nextTier) {
    final state = gameService.state;
    final canUpgrade = gameService.canUpgradeFactoryTier;
    final moneyProgress = (state.money / nextTier.upgradeCost).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canUpgrade
              ? Colors.greenAccent.withValues(alpha: 0.6)
              : Colors.cyan.withValues(alpha: 0.3),
          width: canUpgrade ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(nextTier.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Next License: Tier ${nextTier.tierNumber} - ${nextTier.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            nextTier.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'Upgrade Requirements',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // 1. Capital Requirement
          _buildRequirementRow(
            icon: Icons.attach_money,
            title: 'Capital Required',
            currentText: '\$${state.money.toStringAsFixed(0)}',
            targetText: '\$${nextTier.upgradeCost.toStringAsFixed(0)}',
            progress: moneyProgress,
            isMet: state.money >= nextTier.upgradeCost,
          ),

          // 2. Shipped Products Requirements
          ...nextTier.requiredShippedProducts.entries.map((req) {
            final product = GameData.getProduct(req.key);
            final currentShipped = state.getShippedProductCount(req.key);
            final targetShipped = req.value;
            final progress = (currentShipped / targetShipped).clamp(0.0, 1.0);
            final isMet = currentShipped >= targetShipped;

            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildRequirementRow(
                icon: Icons.local_shipping_outlined,
                title: '${product?.emoji ?? "📦"} ${product?.name ?? req.key} Shipped',
                currentText: '$currentShipped',
                targetText: '$targetShipped',
                progress: progress,
                isMet: isMet,
              ),
            );
          }),

          const SizedBox(height: 16),

          // Upgrade Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canUpgrade
                  ? () => _handleUpgrade(context, nextTier)
                  : null,
              icon: Icon(
                canUpgrade ? Icons.upgrade : Icons.lock_outline,
                size: 20,
              ),
              label: Text(
                canUpgrade
                    ? 'Acquire Tier ${nextTier.tierNumber} License (\$${nextTier.upgradeCost.toStringAsFixed(0)})'
                    : 'Prerequisites Incomplete (\$${nextTier.upgradeCost.toStringAsFixed(0)})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canUpgrade ? Colors.green[600] : Colors.grey[800],
                foregroundColor: canUpgrade ? Colors.white : Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Banner shown when player reaches the highest factory tier
  Widget _buildMaxTierBanner(BuildContext context, FactoryTier currentTier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('👑', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Maximum Factory License Reached!',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your enterprise has achieved peak manufacturing capabilities. Look forward to future IPO prestige features!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Visual roadmap of all factory tiers
  Widget _buildRoadmapCard(BuildContext context, FactoryTier currentTier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.purple[300], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Factory Expansion Roadmap',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tiers list
          ...GameData.factoryTiers.map((tier) {
            final isCompleted = tier.tierNumber < currentTier.tierNumber;
            final isCurrent = tier.tierNumber == currentTier.tierNumber;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  // Status Icon
                  Icon(
                    isCompleted
                        ? Icons.check_circle
                        : (isCurrent ? Icons.play_circle_fill : Icons.lock_outline),
                    color: isCompleted
                        ? Colors.greenAccent
                        : (isCurrent ? Colors.purpleAccent : Colors.white30),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    tier.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tier ${tier.tierNumber}: ${tier.name}',
                      style: TextStyle(
                        color: isCurrent
                            ? Colors.white
                            : (isCompleted ? Colors.white70 : Colors.white38),
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'CURRENT',
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Helper row widget for upgrade requirement progress
  Widget _buildRequirementRow({
    required IconData icon,
    required String title,
    required String currentText,
    required String targetText,
    required double progress,
    required bool isMet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isMet ? Icons.check : icon,
                  size: 15,
                  color: isMet ? Colors.greenAccent : Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: isMet ? Colors.greenAccent : Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Text(
              '$currentText / $targetText',
              style: TextStyle(
                color: isMet ? Colors.greenAccent : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              isMet ? Colors.greenAccent : Colors.cyanAccent,
            ),
          ),
        ),
      ],
    );
  }

  /// Helper perk pill widget
  Widget _buildPerkPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.purple[200]),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.purple[100],
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Handles license upgrade with feedback
  Future<void> _handleUpgrade(BuildContext context, FactoryTier nextTier) async {
    final success = await gameService.upgradeFactoryTier();
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(nextTier.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🎉 Upgraded to ${nextTier.name}! New production capabilities unlocked.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.purple[800],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot upgrade: requirements not met.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
