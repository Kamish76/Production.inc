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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              ),
              const SizedBox(height: 20),
              Text(
                'Buy • Build • Sell • Automate!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[300],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 50),
              
              // Three main game windows as specified in concept
              _buildMenuButton(
                context,
                'Buy Materials',
                Icons.shopping_cart,
                () => context.go('/buy'),
                Colors.green[600]!,
              ),
              const SizedBox(height: 20),
              
              _buildMenuButton(
                context,
                'Build Products',
                Icons.build,
                () => context.go('/build'),
                Colors.blue[600]!,
              ),
              const SizedBox(height: 20),
              
              _buildMenuButton(
                context,
                'Sell Products',
                Icons.attach_money,
                () => context.go('/sell'),
                Colors.purple[600]!,
              ),
              const SizedBox(height: 40),
              
              // Additional menu options
              _buildMenuButton(
                context,
                'Settings',
                Icons.settings,
                () => context.go('/settings'),
                Colors.grey[600]!,
              ),
            ],
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
      width: 250,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
      ),
    );
  }
}
