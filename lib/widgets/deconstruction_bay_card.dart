import 'package:flutter/material.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';
import '../services/production_game_service.dart';

/// Card widget that allows players to deconstruct assembled products in their
/// inventory into Research Points (RP).
class DeconstructionBayCard extends StatefulWidget {
  final ProductionGameService gameService;

  const DeconstructionBayCard({
    super.key,
    required this.gameService,
  });

  @override
  State<DeconstructionBayCard> createState() => _DeconstructionBayCardState();
}

class _DeconstructionBayCardState extends State<DeconstructionBayCard> {
  // Selected quantity for each product: productId -> selected quantity
  final Map<String, int> _selectedQuantities = {};
  IndustryBranch? _selectedBranch;

  int _getQuantity(String productId, int maxOwned) {
    final qty = _selectedQuantities[productId] ?? 1;
    return qty.clamp(1, maxOwned > 0 ? maxOwned : 1);
  }

  void _setQuantity(String productId, int qty) {
    setState(() {
      _selectedQuantities[productId] = qty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.gameService.state;

    // Filter products that the player currently has in inventory (count > 0)
    final ownedProducts = GameData.products.where((p) {
      final count = state.getProductCount(p.id);
      if (count <= 0) return false;
      if (_selectedBranch != null && p.industryBranch != _selectedBranch) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Info Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1F2B48).withValues(alpha: 0.9),
                const Color(0xFF131C32).withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.cyan.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.science, color: Colors.cyanAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Recycle surplus manufactured goods into Research Points (RP) to fund the Tech Tree.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Branch Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(null, 'All Branches', '🌐'),
              const SizedBox(width: 8),
              _buildFilterChip(IndustryBranch.consumerTech, 'Consumer Tech', '📱'),
              const SizedBox(width: 8),
              _buildFilterChip(IndustryBranch.robotics, 'Robotics', '🤖'),
              const SizedBox(width: 8),
              _buildFilterChip(IndustryBranch.cleanEnergy, 'Clean Energy', '⚡'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 3. Inventory List or Empty State
        if (ownedProducts.isEmpty)
          _buildEmptyInventoryCard(context)
        else
          ...ownedProducts.map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDeconstructionRow(context, product),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(IndustryBranch? branch, String label, String emoji) {
    final isSelected = _selectedBranch == branch;
    return ChoiceChip(
      avatar: Text(emoji, style: const TextStyle(fontSize: 14)),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedBranch = selected ? branch : null;
        });
      },
      selectedColor: Colors.purple[700],
      backgroundColor: const Color(0xFF1F1D36),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected
            ? Colors.purpleAccent
            : Colors.white.withValues(alpha: 0.15),
      ),
    );
  }

  Widget _buildEmptyInventoryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        children: [
          Text('📦', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text(
            'No Manufactured Items In Storage',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Build products in the Build tab to stock inventory, then return here to deconstruct surplus units for Research Points.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDeconstructionRow(BuildContext context, Product product) {
    final state = widget.gameService.state;
    final ownedCount = state.getProductCount(product.id);
    final selectedQty = _getQuantity(product.id, ownedCount);
    final rpPerUnit = GameData.getResearchPointsForProduct(product.id);
    final totalRpYield = rpPerUnit * selectedQty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Product Info, Stock, RP per unit
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(product.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'In Stock: $ownedCount units',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.cyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+$rpPerUnit RP/unit',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
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

          const SizedBox(height: 10),

          // Quantity selector chips: 1, 5, 10, All
          Row(
            children: [
              const Text('Qty: ', style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(width: 4),
              _buildQtyButton(product.id, 1, ownedCount, selectedQty),
              const SizedBox(width: 6),
              if (ownedCount >= 5) ...[
                _buildQtyButton(product.id, 5, ownedCount, selectedQty),
                const SizedBox(width: 6),
              ],
              if (ownedCount >= 10) ...[
                _buildQtyButton(product.id, 10, ownedCount, selectedQty),
                const SizedBox(width: 6),
              ],
              _buildQtyButton(product.id, ownedCount, ownedCount, selectedQty, label: 'All ($ownedCount)'),
            ],
          ),

          const SizedBox(height: 10),

          // Deconstruct Action CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final success = widget.gameService.deconstructProduct(
                  product.id,
                  selectedQty,
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '🧪 Deconstructed $selectedQty x ${product.name}! Gained +$totalRpYield RP.',
                      ),
                      backgroundColor: Colors.purple[800],
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.recycling, size: 16),
              label: Text(
                'Deconstruct $selectedQty → Gain +$totalRpYield RP',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(
    String productId,
    int qty,
    int maxCount,
    int currentSelected, {
    String? label,
  }) {
    final isSelected = currentSelected == qty;
    return InkWell(
      onTap: () => _setQuantity(productId, qty),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.purple.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.purpleAccent : Colors.white12,
          ),
        ),
        child: Text(
          label ?? 'x$qty',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
