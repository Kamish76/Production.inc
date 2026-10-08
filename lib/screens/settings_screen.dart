import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_data.dart';
import '../services/production_game_service.dart';
import '../widgets/game_dialog.dart';
import '../widgets/game_icon.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Handle code redemption logic
  void _handleRedeem(BuildContext context, ProductionGameService gameService) {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please enter a redeem code.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final result = gameService.redeemCode(code);
    _codeController.clear();

    Color snackBarColor;
    switch (result.status) {
      case RedeemCodeResult.devUnlocked:
        snackBarColor = Colors.purple;
        break;
      case RedeemCodeResult.rewardClaimed:
        snackBarColor = Colors.green;
        break;
      case RedeemCodeResult.alreadyRedeemed:
        snackBarColor = Colors.orange;
        break;
      case RedeemCodeResult.invalid:
        snackBarColor = Colors.red;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: snackBarColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
                  '💡 Early Game',
                  'Start with Simple Widgets - they produce quickly and provide steady initial income.',
                ),
                const SizedBox(height: 12),
                _buildGameTip(
                  '📦 Batch Shipping',
                  'Ship larger batches to maximize revenue efficiency and reduce overall shipping time.',
                ),
                const SizedBox(height: 12),
                _buildGameTip(
                  '🔄 Automation',
                  'Invest in Auto-Buy and Auto-Build machines early to keep production running smoothly.',
                ),
                const SizedBox(height: 12),
                _buildGameTip(
                  '📈 Tier Expansion',
                  'Fulfill tier shipping requirements to unlock higher tier factories and advanced logistics.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.yellow, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show Privacy Policy dialog (100% Offline, Zero Data Collection)
  void _showPrivacyPolicy(BuildContext context) {
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
              Icon(Icons.privacy_tip_outlined, color: Colors.teal[400]),
              const SizedBox(width: 8),
              const Text(
                'Privacy Policy',
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
                  '🛡️ 100% Offline Single-Player',
                  'Production.Inc does not collect, record, track, transmit, or share any personal information, telemetry, device identifiers, or gameplay analytics.',
                ),
                const SizedBox(height: 12),
                _buildGameTip(
                  '💾 Local Storage Only',
                  'All game progress, factory tiers, contracts, and settings are saved strictly on your local device within the private application sandbox (SQLite & SharedPreferences).',
                ),
                const SizedBox(height: 12),
                _buildGameTip(
                  '🚫 Zero Ads & Zero Tracking',
                  'The game contains zero third-party advertising SDKs, zero analytics trackers, and requires no account registration or cloud sign-in.',
                ),
                const SizedBox(height: 12),
                _buildGameTip(
                  '🌐 External Links',
                  'Any external community links (such as the community Discord button) open externally via your device browser or installed app and never transmit in-game data.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.tealAccent, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

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
    return Scaffold(
      body: Container(
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
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: Colors.grey[400],
                      iconSize: 28,
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 8),
                    GameIcon.forUi(
                      id: 'ui_settings',
                      fallbackEmoji: '⚙️',
                      size: 28,
                    ),
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
              // Virtualized lazy loaded settings content
              Expanded(
                child: Consumer<ProductionGameService>(
                  builder: (context, gameService, child) {
                    final isDevUnlocked = gameService.isDeveloperModeUnlocked;
                    final itemCount = isDevUnlocked ? 7 : 6;

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        Widget sectionWidget;
                        switch (index) {
                          case 0:
                            sectionWidget = _buildGameDataSection(context, gameService);
                            break;
                          case 1:
                            sectionWidget = _buildRedeemCodeSection(context, gameService);
                            break;
                          case 2:
                            sectionWidget = _buildAppSettingsSection();
                            break;
                          case 3:
                            sectionWidget = _buildHelpTutorialSection(context);
                            break;
                          case 4:
                            sectionWidget = _buildGameInfoSection(gameService);
                            break;
                          case 5:
                            if (isDevUnlocked) {
                              sectionWidget = _buildDeveloperToolsSection(context, gameService);
                            } else {
                              sectionWidget = _buildBatteryOptimizationSection();
                            }
                            break;
                          case 6:
                            sectionWidget = _buildBatteryOptimizationSection();
                            break;
                          default:
                            sectionWidget = const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: sectionWidget,
                        );
                      },
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

  /// Section 0: Game Data Section
  Widget _buildGameDataSection(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    return Container(
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Game saved successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const GameIcon(
                itemId: 'ui_save_cloud',
                fallbackEmoji: '💾',
                size: 22,
              ),
              label: const Text('Save Game'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Reset Game Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showResetConfirmation(context, gameService),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset Game'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section 1: Redeem Code Section
  Widget _buildRedeemCodeSection(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.amber[400], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Redeem Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          const Text(
            'Enter launch celebration codes or ephemeral developer debug keys:',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('redeem_code_field'),
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. PRODUCTION2026',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontWeight: FontWeight.normal,
                      letterSpacing: 0.5,
                    ),
                    filled: true,
                    fillColor: Colors.black26,
                    prefixIcon: const Icon(Icons.vpn_key, color: Colors.white70, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.amber[400]!),
                    ),
                  ),
                  onSubmitted: (_) => _handleRedeem(context, gameService),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                key: const ValueKey('redeem_code_button'),
                onPressed: () => _handleRedeem(context, gameService),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Redeem'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  /// Section 2: App Settings Section
  Widget _buildAppSettingsSection() {
    return Container(
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

          // Notifications Toggle
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Switch(
                value: true,
                onChanged: null,
                activeThumbColor: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Sound Effects Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    GameIcon.forUi(
                      id: 'ui_audio_on',
                      fallbackEmoji: '🔊',
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Sound Effects',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Switch(
                value: false,
                onChanged: null,
                activeThumbColor: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Performance Mode Toggle
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      style: TextStyle(color: Colors.white70),
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
    );
  }

  /// Section 3: Help & Tutorial Section
  Widget _buildHelpTutorialSection(BuildContext context) {
    return Container(
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
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Privacy Policy Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showPrivacyPolicy(context),
              icon: const Icon(Icons.privacy_tip_outlined),
              label: const Text('Privacy Policy'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section 4: Game Information / Telemetry Section
  Widget _buildGameInfoSection(ProductionGameService gameService) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    color: gameService.isAppPaused
                        ? Colors.orange
                        : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    gameService.isAppPaused ? 'Paused' : 'Active',
                    style: TextStyle(
                      color: gameService.isAppPaused
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
    );
  }

  /// Section 5: Developer Tools Section (only built when unlocked via 888888)
  Widget _buildDeveloperToolsSection(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    return Container(
      key: const ValueKey('developer_tools_section'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              IconButton(
                key: const ValueKey('relock_dev_tools_button'),
                icon: const Icon(Icons.lock, color: Colors.purpleAccent, size: 20),
                tooltip: 'Relock Developer Tools',
                onPressed: () {
                  gameService.setDeveloperModeUnlocked(false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔒 Developer tools locked.'),
                      backgroundColor: Colors.purple,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),

          // 1. Cycle Factory Tier (Dev Tool)
          _buildDevControl(
            icon: Icons.military_tech,
            title: 'Cycle Factory Tier (Current: T${gameService.state.factoryTier})',
            subtitle: 'Dev: Cycle between Factory Tiers 1-4 for testing',
            color: Colors.purple,
            onPressed: () => _cycleDevFactoryTier(context, gameService),
          ),

          const SizedBox(height: 12),

          // 2. Cycle Logistics Fleet Tier (Dev Tool - Phase 2)
          _buildDevControl(
            icon: Icons.local_shipping,
            title: 'Cycle Fleet Tier (Current: T${gameService.state.fleetTier})',
            subtitle: 'Dev: Cycle Logistics Fleet Tiers 1-4 for testing',
            color: Colors.cyan,
            onPressed: () => _cycleDevFleetTier(context, gameService),
          ),

          const SizedBox(height: 12),

          // 3. Boost Corporate Reputation (Dev Tool - Phase 2)
          _buildDevControl(
            icon: Icons.handshake,
            title: 'Boost Corporate Reputation (+100)',
            subtitle: 'Dev: Add 100 reputation points to all clients',
            color: Colors.indigo,
            onPressed: () => _boostDevReputation(context, gameService),
          ),

          const SizedBox(height: 12),

          // 4. Refresh Contracts (Dev Tool - Phase 2)
          _buildDevControl(
            icon: Icons.assignment,
            title: 'Refresh Corporate Contracts',
            subtitle: 'Dev: Force regenerate 3 active B2B contracts',
            color: Colors.teal,
            onPressed: () => _refreshDevContracts(context, gameService),
          ),

          const SizedBox(height: 12),

          // 5. Add Research Points (Dev Tool - Phase 4)
          _buildDevControl(
            icon: Icons.science,
            title: 'Add Research Points (+250 RP)',
            subtitle: 'Dev: Grant 250 RP for testing technology upgrades',
            color: Colors.purpleAccent,
            onPressed: () => _addDevRP(context, gameService, 250),
          ),

          const SizedBox(height: 12),

          // 6. Reset Maintenance Wear (Dev Tool - Phase 4)
          _buildDevControl(
            icon: Icons.healing,
            title: 'Reset Maintenance Wear (0%)',
            subtitle: 'Dev: Restore factory wear to 0% perfect health',
            color: Colors.lightGreen,
            onPressed: () => _resetDevMaintenanceWear(context, gameService),
          ),

          const SizedBox(height: 12),

          // 7. Simulate Critical Wear (Dev Tool - Phase 4)
          _buildDevControl(
            icon: Icons.build,
            title: 'Simulate Critical Wear (100%)',
            subtitle: 'Dev: Force wear to 100% to test overclock shutdown',
            color: Colors.deepOrange,
            onPressed: () => _simulateCriticalWear(context, gameService),
          ),

          const SizedBox(height: 12),

          // 8. Add Golden Shares (Dev Tool - Phase 5)
          _buildDevControl(
            icon: Icons.star,
            title: 'Add Golden Shares (+10)',
            subtitle: 'Dev: Instantly grant 10 Golden Shares (+100% speed)',
            color: const Color(0xFFFFB300),
            onPressed: () => _addDevGoldenShares(context, gameService, 10),
          ),

          const SizedBox(height: 12),

          // 9. Add $1,000,000 Cash for IPO Testing (Dev Tool - Phase 5)
          _buildDevControl(
            icon: Icons.account_balance,
            title: 'Add \$1,000,000 Cash',
            subtitle: 'Dev: Instantly qualify for Initial Public Offering',
            color: Colors.amberAccent,
            onPressed: () => _addDevMoney(context, gameService, 1000000),
          ),

          const SizedBox(height: 12),

          // 10. Add Money (Dev Tool)
          _buildDevControl(
            icon: Icons.add_circle_outline,
            title: 'Add Money',
            subtitle: 'Add \$1000 to balance',
            color: Colors.green,
            onPressed: () => _addDevMoney(context, gameService, 1000),
          ),

          const SizedBox(height: 12),

          // 11. Add More Money (Dev Tool)
          _buildDevControl(
            icon: Icons.monetization_on_outlined,
            title: 'Add Big Money',
            subtitle: 'Add \$10000 to balance',
            color: Colors.amber,
            onPressed: () => _addDevMoney(context, gameService, 10000),
          ),

          const SizedBox(height: 12),

          // 12. Complete All Productions (Dev Tool)
          _buildDevControl(
            icon: Icons.fast_forward,
            title: 'Complete Productions',
            subtitle: 'Instantly complete all active productions',
            color: Colors.blue,
            onPressed: () => _completeAllProductions(context, gameService),
          ),

          const SizedBox(height: 12),

          // 13. Complete All Shipments (Dev Tool)
          _buildDevControl(
            icon: Icons.local_shipping,
            title: 'Complete Shipments',
            subtitle: 'Instantly complete all active shipments',
            color: Colors.orange,
            onPressed: () => _completeAllShipments(context, gameService),
          ),

          const SizedBox(height: 12),

          // 14. Unlock All Products (Dev Tool)
          _buildDevControl(
            icon: Icons.lock_open,
            title: 'Unlock All Products',
            subtitle: 'Unlock all products for testing',
            color: Colors.teal,
            onPressed: () => _unlockAllProducts(context, gameService),
          ),

          const SizedBox(height: 12),

          // 15. Force Unlock Check (Dev Tool)
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
            title: 'Verify Database Schema',
            subtitle: 'Check and fix missing columns/tables',
            color: Colors.cyan,
            onPressed: () => _verifyDatabaseSchema(context, gameService),
          ),

          const SizedBox(height: 12),

          // Database Reset Tool (Dangerous)
          _buildDevControl(
            icon: Icons.warning,
            title: 'Reset Database',
            subtitle: 'WARNING: Deletes all data and recreates DB',
            color: Colors.red,
            onPressed: () => _resetDatabase(context, gameService),
          ),

          const SizedBox(height: 16),

          // Warning notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red[300],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dev tools are for testing only. Auto-relocks on app exit.',
                    style: TextStyle(color: Colors.red[300], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section 6: Battery & Auto-Save Optimization Info
  Widget _buildBatteryOptimizationSection() {
    return Container(
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
          border: Border.all(color: color.withValues(alpha: 0.3)),
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

  // ==================================================
  // DEVELOPER CONTROLS ACTIONS (Transferred from ControlScreen)
  // ==================================================

  /// Dev tool: Cycle factory tier
  void _cycleDevFactoryTier(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    final current = gameService.state.factoryTier;
    final next = current >= 4 ? 1 : current + 1;
    gameService.setFactoryTierForDev(next);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🏭 Set Factory Tier to $next: ${GameData.getFactoryTier(next).name} (Dev)',
        ),
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Dev tool: Cycle logistics fleet tier (Phase 2)
  void _cycleDevFleetTier(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    final current = gameService.state.fleetTier;
    final next = current >= 4 ? 1 : current + 1;
    gameService.setFleetTierForDev(next);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🚚 Set Fleet Tier to $next: ${GameData.getFleetTier(next).name} (Dev)',
        ),
        backgroundColor: Colors.cyan,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Dev tool: Boost corporate reputation (Phase 2)
  void _boostDevReputation(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    for (final client in GameData.corporateClients) {
      gameService.devAddReputation(client.id, 100);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🤝 Added +100 reputation to all corporate clients (Dev)'),
        backgroundColor: Colors.indigo,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Dev tool: Refresh contracts (Phase 2)
  void _refreshDevContracts(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    gameService.devRefreshContracts();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Generated 3 new corporate B2B contracts (Dev)'),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Dev tool: Add research points (Phase 4)
  void _addDevRP(
    BuildContext context,
    ProductionGameService gameService,
    int amount,
  ) {
    gameService.devAddResearchPoints(amount);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🧪 Added $amount Research Points (Dev)'),
        backgroundColor: Colors.purpleAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Dev tool: Reset maintenance wear (Phase 4)
  void _resetDevMaintenanceWear(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    gameService.devSetMaintenanceWear(1.0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔧 Factory maintenance wear restored to 0% (Dev)'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Dev tool: Simulate critical wear (Phase 4)
  void _simulateCriticalWear(
    BuildContext context,
    ProductionGameService gameService,
  ) {
    gameService.devSetMaintenanceWear(0.0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Factory wear set to 100% (Critical Shutdown simulated)'),
        backgroundColor: Colors.deepOrange,
        duration: Duration(seconds: 2),
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

  /// Dev tool: Add Golden Shares (Phase 5)
  void _addDevGoldenShares(
    BuildContext context,
    ProductionGameService gameService,
    int amount,
  ) {
    gameService.devAddGoldenShares(amount);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🌟 Added $amount Golden Shares (Dev)'),
        backgroundColor: const Color(0xFFFFB300),
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

  /// Dev tool: Verify and fix database schema
  void _verifyDatabaseSchema(
    BuildContext context,
    ProductionGameService gameService,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔍 Verifying database schema...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      await gameService.verifyAndFixDatabaseSchema();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Database schema verified and fixed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Schema fix failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Dev tool: Reset database (DANGEROUS - deletes all data)
  void _resetDatabase(
    BuildContext context,
    ProductionGameService gameService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.red.shade900,
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.yellow),
                SizedBox(width: 8),
                Text('DANGER: Reset Database?'),
              ],
            ),
            content: const Text(
              '⚠️ THIS WILL DELETE ALL YOUR DATA!\n\n'
              'All progress, machines, money, and items will be permanently lost.\n\n'
              'This creates a fresh database from scratch.\n\n'
              'Only use this if the database is corrupted beyond repair.',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('DELETE EVERYTHING'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await gameService.resetDatabase();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔄 Database reset complete! Restart the app.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Reset failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }
}
