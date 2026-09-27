import 'package:flutter/material.dart';
import '../models/game_models.dart' as game;
import '../models/game_data.dart';
import 'game_icon.dart';

class OrderItemsList extends StatelessWidget {
  final List<game.ShippingItem> items;
  final double fontSize;
  final double emojiSize;
  final double verticalPadding;

  const OrderItemsList({
    super.key,
    required this.items,
    this.fontSize = 14,
    this.emojiSize = 20,
    this.verticalPadding = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        final product = GameData.getProduct(item.productId);
        if (product == null) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: Row(
            children: [
              GameIcon.forProduct(
                id: product.id,
                fallbackEmoji: product.emoji,
                size: emojiSize,
              ),
              const SizedBox(width: 8),
              Text(
                '${product.name} x${item.quantity}',
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}