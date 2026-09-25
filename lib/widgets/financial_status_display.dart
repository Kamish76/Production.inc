import 'package:flutter/material.dart';
import '../services/production_game_service.dart';

enum FinancialDisplayMode {
  moneyOnly,
  portfolio,
}

/// Universal financial status display widget combining MoneyDisplay and PortfolioDisplay
class FinancialStatusDisplay extends StatelessWidget {
  final ProductionGameService gameService;
  final FinancialDisplayMode mode;
  final Color? backgroundColor;
  final String? label;

  const FinancialStatusDisplay({
    super.key,
    required this.gameService,
    this.mode = FinancialDisplayMode.moneyOnly,
    this.backgroundColor,
    this.label,
  });

  double _calculatePortfolioValue() {
    double totalValue = 0;
    for (final entry in gameService.state.products.entries) {
      final productId = entry.key;
      final quantity = entry.value;
      final product = gameService.getProduct(productId);
      if (product != null && quantity > 0) {
        totalValue += product.sellPrice * quantity;
      }
    }
    return totalValue;
  }

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case FinancialDisplayMode.moneyOnly:
        return _buildMoneyOnlyDisplay(context);
      case FinancialDisplayMode.portfolio:
        return _buildPortfolioDisplay(context);
    }
  }

  Widget _buildMoneyOnlyDisplay(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.green[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${label ?? 'Money'}: \$${gameService.state.money.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPortfolioDisplay(BuildContext context) {
    final totalProducts = gameService.state.products.values.fold(0, (sum, count) => sum + count);
    final portfolioValue = _calculatePortfolioValue();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.purple[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Money: \$${gameService.state.money.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    'Total Products',
                    style: TextStyle(
                      fontSize: 12,
                      color: backgroundColor?.withValues(alpha: 0.6) ?? Colors.purple[200],
                    ),
                  ),
                  Text(
                    '$totalProducts',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                height: 30,
                width: 1,
                color: backgroundColor?.withValues(alpha: 0.8) ?? Colors.purple[400],
              ),
              Column(
                children: [
                  Text(
                    'Portfolio Value',
                    style: TextStyle(
                      fontSize: 12,
                      color: backgroundColor?.withValues(alpha: 0.6) ?? Colors.purple[200],
                    ),
                  ),
                  Text(
                    '\$${portfolioValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                height: 30,
                width: 1,
                color: backgroundColor?.withValues(alpha: 0.8) ?? Colors.purple[400],
              ),
              Column(
                children: [
                  Text(
                    'Fleets Active',
                    style: TextStyle(
                      fontSize: 12,
                      color: backgroundColor?.withValues(alpha: 0.6) ?? Colors.purple[200],
                    ),
                  ),
                  Text(
                    '${gameService.state.activeShippingOrders.length}/${gameService.state.maxSimultaneousShipments}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
}