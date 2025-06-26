import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // Top spacer
                const Spacer(flex: 2),
                
                // Game Title
                const Text(
                  'Production.INC',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.blue,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Buy • Build • Sell • Automate!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[300],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Middle spacer
                const Spacer(flex: 2),
                
                // Menu buttons
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      // Main game entry point
                      _buildMenuButton(
                        context,
                        'Start Game',
                        Icons.play_arrow,
                        () => context.go('/game'),
                        Colors.orange[600]!,
                      ),
                      const SizedBox(height: 20),
                      
                      // Additional menu options
                      _buildMenuButton(
                        context,
                        'Instructions',
                        Icons.help_outline,
                        () {
                          _showInstructionsDialog(context);
                        },
                        Colors.blue[600]!,
                      ),
                      const SizedBox(height: 20),
                      
                      _buildMenuButton(
                        context,
                        'About',
                        Icons.info_outline,
                        () {
                          _showAboutDialog(context);
                        },
                        Colors.grey[600]!,
                      ),
                    ],
                  ),
                ),
                
                // Bottom spacer
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
          shadowColor: color.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  void _showInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'How to Play',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: Text(
              '🏭 Production.INC - Your Business Empire Awaits!\n\n'
              '💰 BUY: Purchase raw materials to start production\n'
              '⚙️ BUILD: Create products from your materials\n'
              '💵 SELL: Market your products for profit\n'
              '🔄 AUTOMATE: Grow your business empire!\n\n'
              'Start with buying materials, then build products, and finally sell them for profit. '
              'Use your earnings to expand and automate your production lines!',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Got it!',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'About Production.INC',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Production.INC v1.0\n\n'
            'A business simulation game where you build and manage your production empire.\n\n'
            'Developed with Flutter\n\n'
            '© 2025 Production.INC Game Studio',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }
}
