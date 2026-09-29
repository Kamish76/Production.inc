import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/production_game_service.dart';
import '../widgets/factory_tier_card.dart';
import '../widgets/tech_tree_card.dart';
import '../widgets/deconstruction_bay_card.dart';
import '../widgets/prestige_card.dart';
import '../widgets/machine_card.dart';
import 'settings_screen.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  // Toggle between 0 (Machines), 1 (Tiers), 2 (R&D Lab), and 3 (Prestige)
  int _selectedSection = 0;
  // Sub-tab for R&D Lab: 0 (Tech Tree), 1 (Deconstruction Bay)
  int _selectedRnDTab = 0;

  @override
  Widget build(BuildContext context) {
    final gameService = Provider.of<ProductionGameService>(context);
    final canIPO = gameService.state.canInitiateIPO;

    return Material(
      child: Container(
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
              // Screen title and section switcher
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune, color: Colors.cyan[400], size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Control Center',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Section switcher
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.cyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSectionButton(
                              icon: Icons.precision_manufacturing,
                              label: 'Machines',
                              isSelected: _selectedSection == 0,
                              onTap: () => setState(() => _selectedSection = 0),
                            ),
                          ),
                          Expanded(
                            child: _buildSectionButton(
                              icon: Icons.layers,
                              label: 'Tiers',
                              isSelected: _selectedSection == 1,
                              onTap: () => setState(() => _selectedSection = 1),
                            ),
                          ),
                          Expanded(
                            child: _buildSectionButton(
                              icon: Icons.science,
                              label: 'R&D Lab',
                              isSelected: _selectedSection == 2,
                              onTap: () => setState(() => _selectedSection = 2),
                            ),
                          ),
                          Expanded(
                            child: _buildSectionButton(
                              icon: Icons.auto_awesome,
                              label: 'Prestige',
                              isSelected: _selectedSection == 3,
                              activeColor: const Color(0xFFFFB300),
                              showBadge: canIPO,
                              onTap: () => setState(() => _selectedSection = 3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content area
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      _selectedSection == 0
                          ? _buildMachinesSection(context, gameService)
                          : _selectedSection == 1
                              ? _buildTiersSection(context, gameService)
                              : _selectedSection == 2
                                  ? _buildRnDLabSection(context, gameService)
                                  : _buildPrestigeSection(context, gameService),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build section button for switcher
  Widget _buildSectionButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
    bool showBadge = false,
  }) {
    final effectiveColor = activeColor ?? Colors.cyan;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? effectiveColor.withValues(alpha: 0.3)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? (activeColor ?? Colors.cyan[300]) : Colors.grey[400],
                size: 15,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[400],
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (showBadge) ...[
                const SizedBox(width: 2),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD54F),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build Machines Section
  Widget _buildMachinesSection(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('machines'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Machine Controls Section
          _buildMachineControlsSection(context, gameService),

          const SizedBox(height: 20),

          // Settings Access Section
          _buildSettingsAccessSection(context),
        ],
      ),
    );
  }

  /// Build Tiers Section
  Widget _buildTiersSection(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('tiers'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Factory Tiers & Expansion Licensing System (Phase 1)
          FactoryTierCard(gameService: gameService),
        ],
      ),
    );
  }

  /// Build R&D Lab Section (Phase 4)
  Widget _buildRnDLabSection(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    final state = gameService.state;
    return SingleChildScrollView(
      key: const ValueKey('rnd_lab'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // R&D Lab Header Banner with RP Counter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1A47), Color(0xFF16213E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.science, color: Colors.purpleAccent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'R&D Department',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Deconstruct surplus parts & research factory upgrades.',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bubble_chart, color: Colors.purpleAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${state.researchPoints} RP',
                        style: const TextStyle(
                          color: Colors.purpleAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sub-Tab Switcher (Tech Tree vs Deconstruction Bay)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildRnDSubTabButton(
                    icon: Icons.account_tree_rounded,
                    label: 'Tech Tree',
                    badge: '${state.techLevels.values.fold(0, (a, b) => a + b)}/9',
                    isSelected: _selectedRnDTab == 0,
                    onTap: () => setState(() => _selectedRnDTab = 0),
                  ),
                ),
                Expanded(
                  child: _buildRnDSubTabButton(
                    icon: Icons.recycling_rounded,
                    label: 'Deconstruction',
                    badge: 'Bay',
                    isSelected: _selectedRnDTab == 1,
                    onTap: () => setState(() => _selectedRnDTab = 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Active Sub-Tab View
          if (_selectedRnDTab == 0)
            TechTreeCard(gameService: gameService)
          else
            DeconstructionBayCard(gameService: gameService),
        ],
      ),
    );
  }

  Widget _buildRnDSubTabButton({
    required IconData icon,
    required String label,
    required String badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purpleAccent.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.purpleAccent : Colors.grey[400],
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.purpleAccent.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: isSelected ? Colors.purpleAccent : Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Prestige Section (Phase 5)
  Widget _buildPrestigeSection(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('prestige_section'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrestigeCard(gameService: gameService),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Navigate to full settings screen
  void _openSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  /// Settings Access Section
  Widget _buildSettingsAccessSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.cyan[400], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openSettings(context),
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Access game settings, tutorials, and information',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Machine Controls Section
  Widget _buildMachineControlsSection(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.precision_manufacturing,
                  color: Colors.cyan[400],
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Machine Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Autonomous procurement and assembly fleet',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 1. Auto-Buy Procurement Fleet Card
        MachineCard.autoBuy(
          context: context,
          gameService: gameService,
        ),

        const SizedBox(height: 14),

        // 2. Auto-Sell Dispatchers Card (Phase 9B: Auto-Sell Dispatchers)
        AutoSellMachineCard(
          gameService: gameService,
        ),

        const SizedBox(height: 16),

        // Section Sub-header for Auto-Build Assembly Tiers
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.construction, size: 16, color: Colors.blue[300]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AUTO-BUILD ASSEMBLY TIERS',
                  style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Auto-Build: Basic Parts Card
        MachineCard.autoBuild(
          context: context,
          gameService: gameService,
          tier: 'basicParts',
          tierName: 'Basic Parts',
          accentColor: Colors.cyanAccent,
          icon: Icons.precision_manufacturing,
          subtitle: 'Automates basic components (Boxes, Gears, Coils)',
        ),

        const SizedBox(height: 14),

        // 3. Auto-Build: Intermediate Card
        MachineCard.autoBuild(
          context: context,
          gameService: gameService,
          tier: 'intermediate',
          tierName: 'Intermediate',
          accentColor: Colors.amberAccent,
          icon: Icons.handyman,
          subtitle: 'Automates sub-assemblies (Frames, Engines, Circuits)',
        ),

        const SizedBox(height: 14),

        // 4. Auto-Build: Complex Card
        MachineCard.autoBuild(
          context: context,
          gameService: gameService,
          tier: 'complex',
          tierName: 'Complex',
          accentColor: Colors.purpleAccent,
          icon: Icons.memory,
          subtitle: 'Automates high-tech products (Smartphones, Drones, Robotics)',
        ),
      ],
    );
  }
}

