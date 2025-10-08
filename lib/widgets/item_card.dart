import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;
import 'quantity_selector_button.dart';

/// Consolidated card widget for materials and products across buy/sell/build modes
/// 
/// This widget replaces BuyMaterialCard, SellProductCard, and BuildProductCard
/// with a single, mode-based implementation that reduces code duplication.
class ItemCard extends StatelessWidget {
  final dynamic item; // Can be game.Material or game.Product
  final ProductionGameService gameService;
  final ItemCardMode mode;
  final VoidCallback? onProductDetails;

  const ItemCard({
    Key? key,
    required this.item,
    required this.gameService,
    required this.mode,
    this.onProductDetails,
  }) : super(key: key);

  bool get _isMaterial => item is game.Material;
  bool get _isProduct => item is game.Product;
  
  game.Material get _material => item as game.Material;
  game.Product get _product => item as game.Product;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.all(4),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _handleCardTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildStatusIndicator(),
              const SizedBox(height: 10),
              _buildDescription(),
              const SizedBox(height: 12),
              if (mode != ItemCardMode.build || _canProduce) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          _isMaterial ? _material.emoji : _product.emoji,
          style: const TextStyle(fontSize: 36),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isMaterial ? _material.name : _product.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _getSubtitleText(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getStatusIcon(),
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _getStatusText(),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      _isMaterial ? _material.description : _product.description,
      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButtons() {
    switch (mode) {
      case ItemCardMode.buy:
        return _buildBuyButtons();
      case ItemCardMode.sell:
        return _buildSellButtons();
      case ItemCardMode.build:
        return _buildBuildButton();
    }
  }

  Widget _buildBuyButtons() {
    final currentPreference = gameService.getBuyQuantityPreference(_material.id);
    return Row(
      children: [
        Expanded(
          child: QuantitySelectorButton(
            quantity: 1,
            cost: _material.buyPrice * 1,
            isSelected: currentPreference == 1,
            canAfford: gameService.state.canAfford(_material.buyPrice * 1),
            onPressed: () => _handleBuyQuantitySelection(1),
            label: 'Buy 1',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: QuantitySelectorButton(
            quantity: 5,
            cost: _material.buyPrice * 5,
            isSelected: currentPreference == 5,
            canAfford: gameService.state.canAfford(_material.buyPrice * 5),
            onPressed: () => _handleBuyQuantitySelection(5),
            label: 'Buy 5',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: QuantitySelectorButton(
            quantity: 10,
            cost: _material.buyPrice * 10,
            isSelected: currentPreference == 10,
            canAfford: gameService.state.canAfford(_material.buyPrice * 10),
            onPressed: () => _handleBuyQuantitySelection(10),
            label: 'Buy 10',
          ),
        ),
      ],
    );
  }

  Widget _buildSellButtons() {
    final available = gameService.state.getProductCount(_product.id);
    final currentPreference = gameService.getSellQuantityPreference(_product.id);
    
    return Row(
      children: [
        Expanded(
          child: _buildQuantitySelectorButton(1, currentPreference, available),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuantitySelectorButton(5, currentPreference, available),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuantitySelectorButton(10, currentPreference, available),
        ),
      ],
    );
  }

  Widget _buildQuantitySelectorButton(int quantity, int currentPreference, int available) {
    final revenue = _product.sellPrice * quantity;
    final isSelected = currentPreference == quantity;
    final canSell = available >= quantity;

    return GestureDetector(
      onTap: () => _handleSellQuantitySelection(quantity),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? (canSell ? Colors.green[700] : Colors.orange[700])
              : (canSell ? Colors.blue[800] : Colors.grey[700]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sell $quantity',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '\$${revenue.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _canProduce ? () => _handleBuildAction() : null,
        icon: const Icon(Icons.build, size: 18),
        label: Text(
          _isInProduction ? 'Building...' : 'Build Product',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _canProduce ? Colors.green[700] : Colors.grey[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // Helper methods
  Color _getBorderColor() {
    switch (mode) {
      case ItemCardMode.buy:
        final cost = _material.buyPrice * gameService.getBuyQuantityPreference(_material.id);
        return gameService.state.canAfford(cost) ? Colors.green : Colors.red;
      case ItemCardMode.sell:
        final stockLevel = _getStockLevel();
        return _getStockLevelColor(stockLevel);
      case ItemCardMode.build:
        return _canProduce ? Colors.green : Colors.red;
    }
  }

  String _getSubtitleText() {
    switch (mode) {
      case ItemCardMode.buy:
        return '\$${_material.buyPrice.toStringAsFixed(2)} each';
      case ItemCardMode.sell:
        return '\$${_product.sellPrice.toStringAsFixed(2)} each';
      case ItemCardMode.build:
        return '${(_product.productionTimeSeconds / 60).toStringAsFixed(1)}m';
    }
  }

  Color _getStatusColor() {
    switch (mode) {
      case ItemCardMode.buy:
        return Colors.blue[700]!;
      case ItemCardMode.sell:
        return _getStockLevelColor(_getStockLevel());
      case ItemCardMode.build:
        return _canProduce ? Colors.green[700]! : Colors.red[700]!;
    }
  }

  IconData _getStatusIcon() {
    switch (mode) {
      case ItemCardMode.buy:
        return Icons.inventory;
      case ItemCardMode.sell:
        return _getStockLevelIcon(_getStockLevel());
      case ItemCardMode.build:
        return _canProduce ? Icons.check_circle : Icons.cancel;
    }
  }

  String _getStatusText() {
    switch (mode) {
      case ItemCardMode.buy:
        final owned = gameService.state.getMaterialCount(_material.id);
        return 'Owned: $owned';
      case ItemCardMode.sell:
        final available = gameService.state.getProductCount(_product.id);
        final stockLevel = _getStockLevel();
        return 'Stock: $available (${stockLevel.toUpperCase()})';
      case ItemCardMode.build:
        return _canProduce ? 'Ready to Build' : 'Need Materials';
    }
  }

  // Stock level helpers for sell mode
  String _getStockLevel() {
    final available = gameService.state.getProductCount(_product.id);
    if (available >= 20) return 'high';
    if (available >= 5) return 'medium';
    return 'low';
  }

  Color _getStockLevelColor(String stockLevel) {
    switch (stockLevel) {
      case 'high': return Colors.green[700]!;
      case 'medium': return Colors.orange[700]!;
      case 'low': return Colors.red[700]!;
      default: return Colors.grey[700]!;
    }
  }

  IconData _getStockLevelIcon(String stockLevel) {
    switch (stockLevel) {
      case 'high': return Icons.trending_up;
      case 'medium': return Icons.trending_flat;
      case 'low': return Icons.trending_down;
      default: return Icons.inventory;
    }
  }

  // Production helpers for build mode
  bool get _canProduce => _isProduct && gameService.state.hasMaterialsFor(_product.requiredMaterials);
  bool get _isInProduction => _isProduct && gameService.state.activeProductions.any((task) => task.productId == _product.id);

  // Action handlers
  void _handleCardTap() {
    switch (mode) {
      case ItemCardMode.buy:
        final currentPreference = gameService.getBuyQuantityPreference(_material.id);
        final cost = _material.buyPrice * currentPreference;
        if (gameService.state.canAfford(cost)) {
          HapticFeedback.mediumImpact();
          gameService.buyMaterial(_material.id, currentPreference);
        } else {
          HapticFeedback.lightImpact();
        }
        break;
      case ItemCardMode.sell:
        final quantity = gameService.getSellQuantityPreference(_product.id);
        final available = gameService.state.getProductCount(_product.id);
        if (available >= quantity) {
          HapticFeedback.mediumImpact();
          gameService.sellProduct(_product.id, quantity);
        } else {
          HapticFeedback.lightImpact();
        }
        break;
      case ItemCardMode.build:
        if (_canProduce && !_isInProduction) {
          _handleBuildAction();
        } else if (onProductDetails != null) {
          onProductDetails!();
        }
        break;
    }
  }

  void _handleBuyQuantitySelection(int quantity) {
    final cost = _material.buyPrice * quantity;
    final canAfford = gameService.state.canAfford(cost);

    if (canAfford) {
      HapticFeedback.mediumImpact();
      gameService.buyMaterial(_material.id, quantity);
      gameService.setBuyQuantityPreference(_material.id, quantity);
    } else {
      HapticFeedback.lightImpact();
      gameService.setBuyQuantityPreference(_material.id, quantity);
    }
  }

  void _handleSellQuantitySelection(int quantity) {
    final available = gameService.state.getProductCount(_product.id);
    
    if (available >= quantity) {
      HapticFeedback.mediumImpact();
      gameService.sellProduct(_product.id, quantity);
    } else {
      HapticFeedback.lightImpact();
    }
    gameService.setSellQuantityPreference(_product.id, quantity);
  }

  void _handleBuildAction() {
    if (_canProduce && !_isInProduction) {
      HapticFeedback.mediumImpact();
      gameService.startProduction(_product.id, 1);
    }
  }
}

/// Enum defining the different modes for ItemCard
enum ItemCardMode {
  buy,    // For buying materials
  sell,   // For selling products  
  build,  // For building/producing products
}