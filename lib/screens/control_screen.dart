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
                          // Settings Access Section
                          _buildSettingsAccessSection(context),
                          
                          const SizedBox(height: 20),
                          
                          // Machine Controls Section
                          _buildMachineControlsSection(context, gameService),
                          
                          const SizedBox(height: 20),
                          
                          // Dev Controls Section
                          _buildDevControlsSection(context, gameService),
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
          
          // Auto Buy Control
          _buildMachineControl(
            icon: Icons.shopping_cart_outlined,
            title: 'Auto Buy',
            subtitle: 'Automatically purchase materials',
            isEnabled: gameService.state.autoBuyEnabled,
            onToggle: () => gameService.toggleAutoBuy(),
            additionalInfo: gameService.state.autoBuyEnabled
                ? 'Machines: ${gameService.state.autoBuyMachinesOwned}'
                : null,
          ),
          
          const SizedBox(height: 12),
          
          // Auto Build Control (placeholder for future)
          _buildMachineControl(
            icon: Icons.build_circle_outlined,
            title: 'Auto Build',
            subtitle: 'Automatically produce products',
            isEnabled: false,
            onToggle: null, // Disabled - not implemented yet
            additionalInfo: 'Coming soon',
          ),
          
          const SizedBox(height: 12),
          
          // Auto Sell Control (placeholder for future)
          _buildMachineControl(
            icon: Icons.sell_outlined,
            title: 'Auto Sell',
            subtitle: 'Automatically sell products',
            isEnabled: false,
            onToggle: null, // Disabled - not implemented yet
            additionalInfo: 'Coming soon',
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

  /// Build a machine control widget
  Widget _buildMachineControl({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback? onToggle,
    String? additionalInfo,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: isEnabled ? Colors.blue[300] : Colors.grey, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
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
                if (additionalInfo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    additionalInfo,
                    style: TextStyle(
                      color: isEnabled ? Colors.blue[300] : Colors.grey,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onToggle != null ? (_) => onToggle() : null,
            activeColor: Colors.blue[400],
            activeTrackColor: Colors.blue[200],
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
}
