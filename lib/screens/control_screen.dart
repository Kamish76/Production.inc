import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/production_game_service.dart';
import 'settings_screen.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  /// Navigate to full settings screen
  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // Screen title
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.tune, color: Colors.cyan[400], size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Control Center',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Control content
              Expanded(
                child: Consumer<ProductionGameService>(
                  builder: (context, gameService, child) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Machine Controls Section
                          _buildMachineControlsSection(context, gameService),
                          
                          const SizedBox(height: 20),
                          
                          // Dev Controls Section
                          _buildDevControlsSection(context, gameService),
                          
                          const SizedBox(height: 20),
                          
                          // Settings Access Section
                          _buildSettingsAccessSection(context),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Settings Access Section
  Widget _buildSettingsAccessSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyan.withValues(alpha: 0.3),
        ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.precision_manufacturing, color: Colors.blue[400], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Machine Controls',
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
          
          // Auto Buy Machine Section
          _buildAutoBuyMachineControls(context, gameService),
          
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          
          // Auto Build Machines Section
          _buildAutoBuildMachinesControls(context, gameService),
        ],
      ),
    );
  }

  /// Auto Buy Machine Controls
  Widget _buildAutoBuyMachineControls(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.green[400], size: 20),
            const SizedBox(width: 8),
            const Text(
              'Auto-Buy Machines',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Machine Count Controls
        Row(
          children: [
            const Text(
              'Machines:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(width: 12),
            
            IconButton(
              onPressed: gameService.state.autoBuyMachinesOwned > 0
                  ? gameService.decrementAutoBuyMachines
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.red[400],
              disabledColor: Colors.grey,
              iconSize: 24,
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${gameService.state.autoBuyMachinesOwned}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            IconButton(
              onPressed: gameService.incrementAutoBuyMachines,
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.green[400],
              iconSize: 24,
            ),
            
            const Spacer(),
            
            // Enable/Disable Toggle
            Switch(
              value: gameService.state.autoBuyEnabled,
              onChanged: gameService.state.autoBuyMachinesOwned > 0
                  ? (_) => gameService.toggleAutoBuy()
                  : null,
              activeColor: Colors.green[400],
              activeTrackColor: Colors.green[200],
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Capacity Controls
        Row(
          children: [
            const Text(
              'Capacity:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(width: 12),
            
            IconButton(
              onPressed: gameService.state.autoBuyResourceCapacity > 10
                  ? gameService.decreaseAutoBuyCapacity
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.red[400],
              disabledColor: Colors.grey,
              iconSize: 24,
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${gameService.state.autoBuyResourceCapacity}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            IconButton(
              onPressed: gameService.increaseAutoBuyCapacity,
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.green[400],
              iconSize: 24,
            ),
            
            const SizedBox(width: 8),
            
            Expanded(
              child: Text(
                'per resource',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        
        // Status info
        if (gameService.state.autoBuyMachinesOwned > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: gameService.state.autoBuyEnabled
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Buying ${gameService.state.autoBuyMachinesOwned * 5} materials every 5s${gameService.state.autoBuyEnabled ? " (active)" : " (paused)"}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Auto Build Machines Controls
  Widget _buildAutoBuildMachinesControls(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.build, color: Colors.blue[400], size: 20),
            const SizedBox(width: 8),
            const Text(
              'Auto-Build Machines',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Tier controls
        _buildAutoBuildTierControl(context, gameService, 'basicParts', 'Basic Parts'),
        const SizedBox(height: 12),
        _buildAutoBuildTierControl(context, gameService, 'intermediate', 'Intermediate'),
        const SizedBox(height: 12),
        _buildAutoBuildTierControl(context, gameService, 'complex', 'Complex'),
      ],
    );
  }

  /// Auto Build Tier Control
  Widget _buildAutoBuildTierControl(
    BuildContext context,
    ProductionGameService gameService,
    String tier,
    String tierName,
  ) {
    final machineCount = gameService.state.autoBuildMachinesOwned[tier] ?? 0;
    final enabled = gameService.state.autoBuildEnabled[tier] ?? false;
    final capacity = gameService.state.autoBuildProductCapacity[tier] ?? 10;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier name and toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  tierName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                onChanged: machineCount > 0
                    ? (_) => gameService.toggleAutoBuild(tier)
                    : null,
                activeColor: Colors.blue[400],
                activeTrackColor: Colors.blue[200],
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Machine count
          Row(
            children: [
              const Text(
                'Machines:',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(width: 8),
              
              IconButton(
                onPressed: machineCount > 0
                    ? () => gameService.decrementAutoBuildMachines(tier)
                    : null,
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: Colors.red[400],
                disabledColor: Colors.grey,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              
              const SizedBox(width: 8),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$machineCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              IconButton(
                onPressed: () => gameService.incrementAutoBuildMachines(tier),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: Colors.green[400],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              
              const SizedBox(width: 16),
              
              // Capacity
              const Text(
                'Cap:',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(width: 8),
              
              IconButton(
                onPressed: capacity > 10
                    ? () => gameService.decreaseAutoBuildCapacity(tier)
                    : null,
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: Colors.red[400],
                disabledColor: Colors.grey,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              
              const SizedBox(width: 8),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$capacity',
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              IconButton(
                onPressed: () => gameService.increaseAutoBuildCapacity(tier),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: Colors.green[400],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dev Controls Section
  Widget _buildDevControlsSection(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.code, color: Colors.purple[400], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Developer Controls',
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
          
          // Add Money (Dev Tool)
          _buildDevControl(
            icon: Icons.add_circle_outline,
            title: 'Add Money',
            subtitle: 'Add \$1000 to balance',
            color: Colors.green,
            onPressed: () => _addDevMoney(context, gameService, 1000),
          ),
          
          const SizedBox(height: 12),
          
          // Add More Money (Dev Tool)
          _buildDevControl(
            icon: Icons.monetization_on_outlined,
            title: 'Add Big Money',
            subtitle: 'Add \$10000 to balance',
            color: Colors.amber,
            onPressed: () => _addDevMoney(context, gameService, 10000),
          ),
          
          const SizedBox(height: 12),
          
          // Complete All Productions (Dev Tool)
          _buildDevControl(
            icon: Icons.fast_forward,
            title: 'Complete Productions',
            subtitle: 'Instantly complete all active productions',
            color: Colors.blue,
            onPressed: () => _completeAllProductions(context, gameService),
          ),
          
          const SizedBox(height: 12),
          
          // Complete All Shipments (Dev Tool)
          _buildDevControl(
            icon: Icons.local_shipping,
            title: 'Complete Shipments',
            subtitle: 'Instantly complete all active shipments',
            color: Colors.orange,
            onPressed: () => _completeAllShipments(context, gameService),
          ),
          
          const SizedBox(height: 12),
          
          // Unlock All Products (Dev Tool)
          _buildDevControl(
            icon: Icons.lock_open,
            title: 'Unlock All Products',
            subtitle: 'Unlock all products for testing',
            color: Colors.teal,
            onPressed: () => _unlockAllProducts(context, gameService),
          ),
          
          const SizedBox(height: 12),
          
          // Force Unlock Check (Dev Tool)
          _buildDevControl(
            icon: Icons.refresh,
            title: 'Force Unlock Check',
            subtitle: 'Re-check unlock conditions for all products',
            color: Colors.purple,
            onPressed: () => _forceUnlockCheck(context, gameService),
          ),
          
          const SizedBox(height: 12),
          
          // Database Repair Tool
          _buildDevControl(
            icon: Icons.build_circle,
            title: 'Repair Database',
            subtitle: 'Fix database structure issues (recreates tables)',
            color: Colors.amber,
            onPressed: () => _repairDatabase(context, gameService),
          ),
          
          const SizedBox(height: 16),
          
          // Warning notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[300], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dev tools are for testing only. Use at your own risk!',
                    style: TextStyle(
                      color: Colors.red[300],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a dev control button
  Widget _buildDevControl({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  /// Dev tool: Add money
  void _addDevMoney(
    BuildContext context,
    ProductionGameService gameService,
    double amount,
  ) {
    gameService.addMoney(amount);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💰 Added \$${amount.toStringAsFixed(0)} (Dev)'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Dev tool: Complete all productions
  void _completeAllProductions(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    final activeProductions = gameService.state.activeProductions;
    if (activeProductions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active productions to complete'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final count = activeProductions.length;
    gameService.completeAllProductionsInstantly();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ Completed $count productions (Dev)'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Dev tool: Complete all shipments
  void _completeAllShipments(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    final activeShipments = gameService.state.activeShippingOrders;
    if (activeShipments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active shipments to complete'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final count = activeShipments.length;
    gameService.completeAllShipmentsInstantly();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ Completed $count shipments (Dev)'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Dev tool: Unlock all products
  void _unlockAllProducts(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    gameService.unlockAllProductsForTesting();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔓 All products unlocked (Dev)'),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Dev tool: Force unlock check
  void _forceUnlockCheck(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    gameService.forceUnlockCheck();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Unlock check completed'),
        backgroundColor: Colors.purple,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Dev tool: Repair database structure
  void _repairDatabase(
    BuildContext context,
    ProductionGameService gameService,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repair Database?'),
        content: const Text(
          'This will recreate missing database tables.\n\n'
          'Your current game data will be preserved.\n\n'
          'The app will restart after repair.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Repair'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await gameService.repairDatabase();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔧 Database repaired! Restart the app.'),
            backgroundColor: Colors.amber,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
