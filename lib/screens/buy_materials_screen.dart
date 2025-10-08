import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/production_game_service.dart';
import '../widgets/screen_header.dart';
import '../widgets/money_display.dart';
import '../widgets/buy_material_card.dart';

class BuyMaterialsScreen extends StatelessWidget {
  const BuyMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionGameService>(
      builder: (context, gameService, child) {
        return Container(
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
                ScreenHeader(
                  icon: Icons.shopping_cart,
                  title: 'Buy Materials',
                  iconColor: Colors.green[400]!,
                ),
                // Money display
                MoneyDisplay(gameService: gameService),

                // Materials list with single-column layout for better readability
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: gameService.allMaterials.length,
                    itemBuilder: (context, index) {
                      final material = gameService.allMaterials[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BuyMaterialCard(
                          material: material,
                          gameService: gameService,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
