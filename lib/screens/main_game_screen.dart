import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/production_game_service.dart';
import 'buy_materials_screen.dart';
import 'build_products_screen.dart';
import 'sell_products_screen.dart';
import 'shipping_screen.dart';
import 'settings_screen.dart';

class MainGameScreen extends StatefulWidget {
  final int initialIndex;

  const MainGameScreen({super.key, this.initialIndex = 0});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const BuyMaterialsScreen(),
    const BuildProductsScreen(),
    const SellProductsScreen(),
    const ShippingScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionGameService>(
      builder: (context, gameService, child) {
        // Show loading screen while game state is being loaded
        if (!gameService.isLoaded) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F3460), Color(0xFF533483)],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Loading Game...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Restoring your progress',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Game is loaded, show normal interface
        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: _screens),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: [
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _currentIndex == 0
                              ? Colors.green[600]?.withValues(alpha: 0.3)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      color:
                          _currentIndex == 0
                              ? Colors.green[400]
                              : Colors.grey[400],
                    ),
                  ),
                  label: 'Buy',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _currentIndex == 1
                              ? Colors.blue[600]?.withValues(alpha: 0.3)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.build,
                      color:
                          _currentIndex == 1
                              ? Colors.blue[400]
                              : Colors.grey[400],
                    ),
                  ),
                  label: 'Build',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _currentIndex == 2
                              ? Colors.purple[600]?.withValues(alpha: 0.3)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.attach_money,
                      color:
                          _currentIndex == 2
                              ? Colors.purple[400]
                              : Colors.grey[400],
                    ),
                  ),
                  label: 'Sell',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _currentIndex == 3
                              ? Colors.orange[600]?.withValues(alpha: 0.3)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      color:
                          _currentIndex == 3
                              ? Colors.orange[400]
                              : Colors.grey[400],
                    ),
                  ),
                  label: 'Shipping',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _currentIndex == 4
                              ? Colors.grey[600]?.withValues(alpha: 0.3)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.settings,
                      color:
                          _currentIndex == 4
                              ? Colors.grey[400]
                              : Colors.grey[400],
                    ),
                  ),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
