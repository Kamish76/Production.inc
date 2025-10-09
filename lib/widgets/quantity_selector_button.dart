import 'package:flutter/material.dart';

/// Reusable quantity selector button used across buy/sell/build screens
class QuantitySelectorButton extends StatelessWidget {
  final int quantity;
  final double cost;
  final bool isSelected;
  final bool canAfford;
  final VoidCallback onPressed;
  final String label;

  const QuantitySelectorButton({
    super.key,
    required this.quantity,
    required this.cost,
    required this.isSelected,
    required this.canAfford,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? (canAfford ? Colors.green[600] : Colors.orange[600])
              : (canAfford ? Colors.grey[700] : Colors.red[800]),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isSelected
                ? BorderSide(color: Colors.blue[300]!, width: 2)
                : BorderSide.none,
          ),
          elevation: isSelected ? 6 : 2,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (cost > 0) ...[
                Text(
                  '\$${cost.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}