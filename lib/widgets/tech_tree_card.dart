import 'package:flutter/material.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';
import '../constants/game_constants.dart';
import '../services/production_game_service.dart';

/// Card widget that displays the Technology Tree branches, active perks,
/// upgrade requirements, and research action buttons.
class TechTreeCard extends StatelessWidget {
  final ProductionGameService gameService;

  const TechTreeCard({
    super.key,
    required this.gameService,
  });

  @override
  Widget build(BuildContext context) {
    final state = gameService.state;
    final factoryOverclockLevel = state.getTechLevel('factory_overclocking');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Factory Overdrive & Diagnostic Control Panel (if Overclocking >= 2)
        if (factoryOverclockLevel >= 2) ...[
          _buildOverdrivePanel(context),
          const SizedBox(height: 16),
        ],

        // 2. Tech Branches
        ...GameData.technologies.map(
          (tech) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTechNodeCard(context, tech),
          ),
        ),
      ],
    );
  }

  /// Interactive control panel for engaging Overclock and servicing maintenance
  Widget _buildOverdrivePanel(BuildContext context) {
    final state = gameService.state;
    final isEngaged = state.isOverclockEngaged;
    final isToggleOn = state.overclockActive;
    final wearPercent = (state.maintenanceWear * 100).toInt();
    final needsService = state.maintenanceWear <= 0.0;
    final canAffordService = state.money >= ResearchConstants.maintenanceCheckupFee;
    final isPristine = state.maintenanceWear >= 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E2842).withValues(alpha: 0.95),
            const Color(0xFF151C30).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEngaged
              ? Colors.amber.withValues(alpha: 0.7)
              : Colors.cyan.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isEngaged
                ? Colors.amber.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isEngaged ? Colors.amber : Colors.cyan)
                      .withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.electric_bolt,
                  color: isEngaged ? Colors.amber : Colors.cyan[300],
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FACTORY OVERDRIVE SYSTEM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      isEngaged
                          ? 'Supercharged (+${((state.overclockSpeedMultiplier - 1.0) * 100).toInt()}% speed)'
                          : needsService
                              ? 'Overdrive paused: maintenance required'
                              : 'Standby mode (Standard speed)',
                      style: TextStyle(
                        color: isEngaged
                            ? Colors.amberAccent
                            : needsService
                                ? Colors.redAccent
                                : Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isToggleOn,
                activeThumbColor: Colors.amber,
                activeTrackColor: Colors.amber.withValues(alpha: 0.4),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.white10,
                onChanged: needsService
                    ? null
                    : (val) {
                        gameService.toggleOverclock(val);
                      },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Maintenance Wear progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Machine Maintenance Condition',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '$wearPercent%',
                style: TextStyle(
                  color: wearPercent > 50
                      ? Colors.greenAccent
                      : wearPercent > 20
                          ? Colors.amberAccent
                          : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: state.maintenanceWear.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                wearPercent > 50
                    ? Colors.greenAccent
                    : wearPercent > 20
                        ? Colors.amberAccent
                        : Colors.redAccent,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Diagnostic Checkup Service button
          Row(
            children: [
              Expanded(
                child: Text(
                  'Diagnostic checkup costs \$${ResearchConstants.maintenanceCheckupFee.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
              ElevatedButton.icon(
                onPressed: isPristine || !canAffordService
                    ? null
                    : () {
                        final success = gameService.performMaintenanceCheckup();
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🔧 Factory maintenance complete! Machinery restored to 100%.'),
                              backgroundColor: Colors.teal,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.build, size: 14),
                label: const Text('Service Machinery', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Individual card for each tech tree branch
  Widget _buildTechNodeCard(BuildContext context, TechNode tech) {
    final state = gameService.state;
    final currentLevel = state.getTechLevel(tech.id);
    final isMaxLevel = currentLevel >= tech.maxLevel;
    final nextLevelInfo = tech.getNextLevelInfo(currentLevel);
    final canAfford = nextLevelInfo != null && state.researchPoints >= nextLevelInfo.rpCost;
    final meetsTier = nextLevelInfo != null && state.factoryTier >= nextLevelInfo.requiredFactoryTier;
    final canResearch = nextLevelInfo != null && canAfford && meetsTier;

    Color branchAccent;
    switch (tech.branch) {
      case TechBranch.materialScience:
        branchAccent = Colors.purpleAccent;
        break;
      case TechBranch.factoryOverclocking:
        branchAccent = Colors.amberAccent;
        break;
      case TechBranch.logisticsOptimization:
        branchAccent = Colors.cyanAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1E34).withValues(alpha: 0.95),
            const Color(0xFF161626).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMaxLevel
              ? Colors.greenAccent.withValues(alpha: 0.6)
              : branchAccent.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isMaxLevel ? Colors.greenAccent : branchAccent)
                .withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Emoji, Title, Level Stars, Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: branchAccent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: branchAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  tech.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tech.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Level Stars
                        Row(
                          children: List.generate(tech.maxLevel, (index) {
                            final isResearched = index < currentLevel;
                            return Icon(
                              isResearched ? Icons.star : Icons.star_border,
                              color: isResearched ? branchAccent : Colors.white24,
                              size: 16,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tech.description,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),

          // Active perk description
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Icon(
                  currentLevel > 0 ? Icons.check_circle : Icons.info_outline,
                  size: 16,
                  color: currentLevel > 0 ? Colors.greenAccent : Colors.white38,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentLevel > 0
                        ? 'Current: ${tech.levels[currentLevel - 1].title} (${tech.levels[currentLevel - 1].description})'
                        : 'Unresearched: No active perk bonuses.',
                    style: TextStyle(
                      color: currentLevel > 0 ? Colors.white : Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Next Upgrade Info / Max Level Banner
          if (!isMaxLevel && nextLevelInfo != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: branchAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: branchAccent.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Next: Level ${nextLevelInfo.level} — ${nextLevelInfo.title}',
                        style: TextStyle(
                          color: branchAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '🧪 ${nextLevelInfo.rpCost} RP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextLevelInfo.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  if (nextLevelInfo.requiredFactoryTier > 1)
                    Text(
                      'Requires: Tier ${nextLevelInfo.requiredFactoryTier} ${GameData.factoryTiers.firstWhere((t) => t.tierNumber == nextLevelInfo.requiredFactoryTier).name} ${meetsTier ? "✅" : "❌"}',
                      style: TextStyle(
                        color: meetsTier ? Colors.greenAccent : Colors.orangeAccent,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Research Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canResearch
                    ? () {
                        final success = gameService.researchTechnology(tech.id);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🎉 Researched ${tech.name} Level ${nextLevelInfo.level}!'),
                              backgroundColor: Colors.purple[700],
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: branchAccent,
                  foregroundColor: Colors.black87,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white30,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  !meetsTier
                      ? 'Requires Tier ${nextLevelInfo.requiredFactoryTier} Factory'
                      : !canAfford
                          ? 'Need ${nextLevelInfo.rpCost} RP (Have ${state.researchPoints})'
                          : 'Research Level ${nextLevelInfo.level} (${nextLevelInfo.rpCost} RP)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified, color: Colors.greenAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'BRANCH MAXED OUT 🌟',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
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
}
