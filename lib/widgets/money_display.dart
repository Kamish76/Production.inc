import 'package:flutter/material.dart';
import '../services/production_game_service.dart';

/// Displays the current money/currency status with consistent styling
class MoneyDisplay extends StatelessWidget {
  final ProductionGameService gameService;
  final Color? backgroundColor;
  final String? label;

  const MoneyDisplay({
    Key? key,
    required this.gameService,
    this.backgroundColor,
    this.label = 'Money',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.green[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: \$${gameService.state.money.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}