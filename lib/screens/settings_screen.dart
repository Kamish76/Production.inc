import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/production_game_service.dart';
import '../widgets/game_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Show confirmation dialog for resetting the game
  void _showResetConfirmation(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GameDialog.confirmation(
          title: 'Reset Game?',
          content:
              'This will permanently delete all your progress including:\n\n'
              '• All money and materials\n'
              '• All products and inventory\n'
              '• Active productions and shipments\n'
              '• All game history\n\n'
              'This action cannot be undone!',
          icon: Icons.warning,
          iconColor: Colors.red[400] ?? Colors.red,
          confirmText: 'Reset Game',
          onConfirm: () async {
            await gameService.resetGame();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 Game has been reset!'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
        );
      },
    );
  }

  /// Show How to Play tutorial dialog
  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.play_circle_outline, color: Colors.blue[400]),
              const SizedBox(width: 8),
              const Text(
                'How to Play',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHowToPlaySection(
                  '🎯 Goal',
                  'Build a production empire by buying materials, producing products, and selling them for profit!',
                ),
                const SizedBox(height: 16),
                _buildHowToPlaySection(
                  '💰 Getting Started',
                  '1. Buy materials from the "Buy Materials" screen\n'
                      '2. Produce products using those materials\n'
                      '3. Sell your products for profit\n'
                      '4. Reinvest profits to expand your operation',
                ),
                const SizedBox(height: 16),
                _buildHowToPlaySection(
                  '🏭 Production',
                  '• Each product requires specific materials\n'
                      '• Production takes time - watch the progress bars\n'
                      '• You can queue multiple productions\n'
                      '• Higher-tier products = more profit',
                ),
                const SizedBox(height: 16),
                _buildHowToPlaySection(
                  '🚚 Shipping',
                  '• Selling products creates shipping orders\n'
                      '• Shipping time depends on quantity\n'
                      '• Track your orders in the shipping history\n'
                      '• Payment arrives when shipping completes',
                ),
                const SizedBox(height: 16),
                _buildHowToPlaySection(
                  '📊 Strategy',
                  '• Monitor your inventory levels\n'
                      '• Plan production chains efficiently\n'
                      '• Balance material costs vs. profits\n'
                      '• Expand to higher-tier products gradually',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Got it!',
                style: TextStyle(color: Colors.blue, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show Game Tips dialog
  void _showGameTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.yellow[400]),
              const SizedBox(width: 8),
              const Text(
                'Game Tips',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGameTip(
                  '💡 Efficiency Tips',
                  '• Buy materials in bulk to save time\n'
                      '• Keep production queues full\n'
                      '• Don\'t let materials sit unused\n'
                      '• Monitor shipping times for planning',
                ),
                const SizedBox(height: 16),
                _buildGameTip(
                  '💰 Money Management',
                  '• Always keep some cash for materials\n'
                      '• Reinvest profits into higher-tier products\n'
                      '• Watch your cash flow vs. shipping delays\n'
                      '• Don\'t spend all money at once',
                ),
                const SizedBox(height: 16),
                _buildGameTip(
                  '🔄 Production Chains',
                  '• Learn which materials make which products\n'
                      '• Plan multi-tier production sequences\n'
                      '• Basic parts → Intermediate → Complex → Retail\n'
                      '• Higher tiers = better profit margins',
                ),
                const SizedBox(height: 16),
                _buildGameTip(
                  '⏰ Time Management',
                  '• Start long productions early\n'
                      '• Queue multiple short productions\n'
                      '• Consider shipping times when selling\n'
                      '• The game runs in real-time!',
                ),
                const SizedBox(height: 16),
                _buildGameTip(
                  '📱 Mobile Tips',
                  '• Game saves automatically when backgrounded\n'
                      '• Productions continue when app is closed\n'
                      '• Check back regularly for completed orders\n'
                      '• Battery optimized for mobile play',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Thanks!',
                style: TextStyle(color: Colors.yellow, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build a section for How to Play dialog
  Widget _buildHowToPlaySection(String title, String content) {
    return Column(
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
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Build a tip section for Game Tips dialog
  Widget _buildGameTip(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.yellow[300],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
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
                    Icon(Icons.settings, color: Colors.grey[400], size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Settings content
              Expanded(
                child: Consumer<ProductionGameService>(
                  builder: (context, gameService, child) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Game Data Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.save,
                                      color: Colors.blue[400],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Game Data',
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

                                // Save Game Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await gameService.saveGame();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '✅ Game saved successfully!',
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.save_alt),
                                    label: const Text('Save Game'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Reset Game Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        () => _showResetConfirmation(
                                          context,
                                          gameService,
                                        ),
                                    icon: const Icon(Icons.restart_alt),
                                    label: const Text('Reset Game'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // App Settings Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.tune,
                                      color: Colors.purple[400],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'App Settings',
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

                                // Notifications Toggle (Placeholder for future feature)
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.notifications,
                                            color: Colors.white70,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Notifications',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value:
                                          true, // Placeholder - would be from preferences
                                      onChanged: null, // Disabled for now
                                      activeThumbColor: Colors.green,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Sound Effects Toggle (Placeholder for future feature)
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.volume_up,
                                            color: Colors.white70,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Sound Effects',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value:
                                          false, // Placeholder - would be from preferences
                                      onChanged: null, // Disabled for now
                                      activeThumbColor: Colors.green,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Performance Mode Toggle
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.speed,
                                            color: Colors.white70,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Performance Mode',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Enabled',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Help & Tutorial Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.help_outline,
                                      color: Colors.yellow[600],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Help & Tutorial',
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

                                // How to Play Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showHowToPlay(context),
                                    icon: const Icon(Icons.play_circle_outline),
                                    label: const Text('How to Play'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Game Tips Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showGameTips(context),
                                    icon: const Icon(Icons.lightbulb_outline),
                                    label: const Text('Game Tips'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Game Information Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.orange[400],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Game Information',
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

                                // Game Stats
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Money:',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    Text(
                                      '\$${gameService.state.money.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Active Productions:',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    Text(
                                      '${gameService.state.activeProductions.length}',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Active Shipments:',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    Text(
                                      '${gameService.state.activeShippingOrders.length}',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'App State:',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          gameService.isAppPaused
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          size: 16,
                                          color:
                                              gameService.isAppPaused
                                                  ? Colors.orange
                                                  : Colors.green,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          gameService.isAppPaused
                                              ? 'Paused'
                                              : 'Active',
                                          style: TextStyle(
                                            color:
                                                gameService.isAppPaused
                                                    ? Colors.orange
                                                    : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Performance & Auto-save info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.autorenew,
                                      color: Colors.blue[300],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Auto-save: Every 30 seconds and when app goes to background',
                                        style: TextStyle(
                                          color: Colors.blue[300],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.battery_saver,
                                      color: Colors.green[300],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Battery optimized: Smart timers (1s active, 5s idle, paused when backgrounded)',
                                        style: TextStyle(
                                          color: Colors.green[300],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ], // closes Column children
          ), // closes Column widget
        ), // closes SafeArea
      ), // closes Container
    ); // closes Material
  }
}
