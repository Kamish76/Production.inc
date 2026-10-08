import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/game_constants.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;
import '../models/game_data.dart' as data;
import 'game_icon.dart';
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
    super.key,
    required this.item,
    required this.gameService,
    required this.mode,
    this.onProductDetails,
  });

  bool get _isMaterial => item is game.Material;
  bool get _isProduct => item is game.Product;
  
  game.Material get _material => item as game.Material;
  game.Product get _product => item as game.Product;

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = _isInProduction;
    final Color baseCardColor = Colors.grey[850]!;
    final Color cardColor =
        isHighlighted
            ? Color.alphaBlend(
                AppColors.productionActive.withValues(alpha: 0.22),
                baseCardColor,
              )
            : baseCardColor;
    final Color borderColor =
        isHighlighted
            ? AppColors.productionActive
            : _getBorderColor();
    final double borderOpacity = isHighlighted ? 0.85 : 0.3;
    final double borderWidth = isHighlighted ? 2.0 : 1.0;
    final double elevation = isHighlighted ? 12 : 8;
    final Color shadowColor =
    isHighlighted
      ? AppColors.productionActive.withValues(alpha: 0.45)
      : Colors.black.withValues(alpha: 0.3);

    return RepaintBoundary(
      child: Card(
        color: cardColor,
        margin: const EdgeInsets.all(2),
        elevation: elevation,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: borderColor.withValues(alpha: borderOpacity),
            width: borderWidth,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _handleCardTap(context),
          onLongPress: () => _showDetailsSheet(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                // Show a compact per-unit materials summary for build items (always visible when unlocked)
                if (mode == ItemCardMode.build && _isProduct && gameService.isProductUnlocked(_product.id)) ...[
                  _buildScaledMaterialsSummary(),
                  const SizedBox(height: 6),
                ] else ...[
                  const SizedBox(height: 2),
                ],
                if (mode != ItemCardMode.build || _canProduce) _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: GameIcon(
                  itemId: _isMaterial ? _material.id : _product.id,
                  fallbackEmoji: _isMaterial ? _material.emoji : _product.emoji,
                  size: 32,
                ),
              ),
              // Buildable indicator: small check/X near the icon (still visible)
              if (mode == ItemCardMode.build && _isProduct)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Icon(
                    _canProduce ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: _canProduce ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
              // Availability badge at the top-right corner
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[900]?.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isMaterial
                          ? '${gameService.state.getMaterialCount(_material.id)}'
                          : '${gameService.state.getProductCount(_product.id)}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isMaterial ? _material.name : _product.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                _getSubtitleText(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Description moved to long-press details sheet.

  Widget _buildActionButtons(BuildContext context) {
    switch (mode) {
      case ItemCardMode.buy:
        return _buildBuyButtons();
      case ItemCardMode.sell:
        return _buildSellButtons(context);
      case ItemCardMode.build:
        return _buildBuildQuantityButtons();
    }
  }

  // Per-unit summary removed; scaled summary is shown instead.

  Widget _buildScaledMaterialsSummary() {
    if (!_isProduct || _product.requiredMaterials.isEmpty) return const SizedBox.shrink();

    final selectedQty = gameService.getBuildQuantityPreference(_product.id);
    final scaled = <String, int>{};
    _product.requiredMaterials.forEach((k, v) => scaled[k] = v * selectedQty);

    final entries = scaled.entries.map((e) {
      final have = gameService.state.getMaterialCount(e.key) +
          gameService.state.getProductCount(e.key);
      final lacking = have < e.value;
      return {
        'id': e.key,
        'required': e.value,
        'have': have,
        'lacking': lacking,
      };
    }).toList();

    // Sort lacking first
    entries.sort((a, b) {
      final la = a['lacking'] as bool;
      final lb = b['lacking'] as bool;
      if (la != lb) return la ? -1 : 1;
      return (a['id'] as String).compareTo(b['id'] as String);
    });

    // Calculate height: each item is ~23px (4px padding + 3px bottom margin + ~16px content)
    // Show max 4 items, but if there are fewer, adjust height accordingly
    final itemHeight = 23.0;
    final maxVisibleItems = 4;
    final actualItems = entries.length;
    final visibleItems = actualItems < maxVisibleItems ? actualItems : maxVisibleItems;
    final containerHeight = itemHeight * visibleItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Materials:',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: containerHeight,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final id = entry['id'] as String;
              final required = entry['required'] as int;
              final have = entry['have'] as int;
              final lacking = entry['lacking'] as bool;

              String name = id;
              String emoji = '';
              final m = data.GameData.getMaterial(id);
              if (m != null) {
                name = m.name;
                emoji = m.emoji;
              } else {
                final p = data.GameData.getProduct(id);
                if (p != null) {
                  name = p.name;
                  emoji = p.emoji;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: lacking ? Colors.red[900] : Colors.green[900],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (emoji.isNotEmpty)
                        GameIcon(
                          itemId: id,
                          fallbackEmoji: emoji,
                          size: 14,
                        ),
                      if (emoji.isNotEmpty) const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$name: $have / $required',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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

  Widget _buildSellButtons(BuildContext context) {
    final available = gameService.state.getProductCount(_product.id);
    final stagedQty = gameService.getStagedQuantity(_product.id);
    final fleet = gameService.currentFleetTier;
    final maxTierQty = fleet.maxUnitsPerType;
    final currentPreference = gameService.getSellQuantityPreference(_product.id);
    final canStageMore = stagedQty < available &&
        stagedQty < maxTierQty &&
        gameService.manifestTotalUnits < fleet.maxPayloadUnits &&
        (stagedQty > 0 || gameService.manifestVarietyCount < fleet.maxProductVarieties);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildManifestShortcutButton(
                context: context,
                label: '1',
                quantity: 1,
                isMax: false,
                isSelected: currentPreference == 1,
                available: available,
                stagedQty: stagedQty,
                fleet: fleet,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildManifestShortcutButton(
                context: context,
                label: '5',
                quantity: 5,
                isMax: false,
                isSelected: currentPreference == 5,
                available: available,
                stagedQty: stagedQty,
                fleet: fleet,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildManifestShortcutButton(
                context: context,
                label: 'Max',
                quantity: maxTierQty,
                isMax: true,
                isSelected: currentPreference >= fleet.maxUnitsPerType,
                available: available,
                stagedQty: stagedQty,
                fleet: fleet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildManifestControls(context, stagedQty, canStageMore, available),
      ],
    );
  }

  Widget _buildManifestControls(
    BuildContext context,
    int stagedQty,
    bool canStageMore,
    int available,
  ) {
    if (stagedQty <= 0) {
      return InkWell(
        onTap: canStageMore && available > 0
            ? () => _handleAddToManifestFromPreference(context)
            : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: double.infinity,
          height: 26,
          decoration: BoxDecoration(
            color: canStageMore && available > 0
                ? Colors.purple.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: canStageMore && available > 0
                  ? Colors.purple.withValues(alpha: 0.4)
                  : Colors.white12,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_shopping_cart,
                size: 13,
                color: canStageMore && available > 0
                    ? Colors.purple[300]
                    : Colors.white30,
              ),
              const SizedBox(width: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '+ Manifest',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: canStageMore && available > 0
                        ? Colors.purple[200]
                        : Colors.white30,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Staged > 0: highlighted badge pill with stepper and quick action
    return Container(
      width: double.infinity,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.purple[300]!.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => _handleManifestStepperDecrement(context, stagedQty),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.remove, size: 12, color: Colors.white),
            ),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '🛒 $stagedQty Staged',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[100],
                  ),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: canStageMore
                ? () => _handleManifestStepperIncrement(context, stagedQty, available)
                : null,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(
                Icons.add,
                size: 12,
                color: canStageMore ? Colors.white : Colors.white24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManifestShortcutButton({
    required BuildContext context,
    required String label,
    required int quantity,
    required bool isMax,
    required bool isSelected,
    required int available,
    required int stagedQty,
    required game.LogisticsFleetTier fleet,
  }) {
    final double revenue = isMax
        ? _product.sellPrice * fleet.maxUnitsPerType
        : _product.sellPrice * quantity;

    final Color backgroundColor;
    final Color borderColor;
    final double borderWidth;
    final Color labelColor;
    final Color subtitleColor;

    if (isSelected) {
      // Vibrant illuminated purple with prominent active border
      backgroundColor = const Color(0xFF5A2A82);
      borderColor = Colors.white.withValues(alpha: 0.85);
      borderWidth = 1.8;
      labelColor = Colors.white;
      subtitleColor = Colors.purple[100]!;
    } else {
      backgroundColor = const Color(0xFF282545);
      borderColor = Colors.purple[400]!.withValues(alpha: 0.6);
      borderWidth = 1.2;
      labelColor = Colors.purple[100]!;
      subtitleColor = Colors.purple[200]!.withValues(alpha: 0.8);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleSellQuantityPreferenceSelection(quantity, isMax: isMax),
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          height: 36,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 1),
              Text(
                '+\$${revenue.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: subtitleColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Note: build action now uses quantity buttons (see _buildBuildQuantityButtons)

  Widget _buildBuildQuantityButtons() {
    // Mirror sell UI but for building: offer Build 1/5/10 options that use
    // the build quantity preference and start production for the selected amount.
    if (!_isProduct) return const SizedBox.shrink();

    // Check if auto-build is active for this tier
    final autoBuildEnabled = gameService.state.autoBuildEnabled[_product.levelId.name] ?? false;
    final machinesOwned = gameService.state.autoBuildMachinesOwned[_product.levelId.name] ?? 0;
    if (autoBuildEnabled && machinesOwned > 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.precision_manufacturing, color: Colors.blue, size: 16),
            SizedBox(width: 8),
            Text(
              'Automated',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final currentPreference = gameService.getBuildQuantityPreference(_product.id);
    final availableMaterials = gameService.state.hasMaterialsFor(_product.requiredMaterials);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Materials are shown in the long-press details sheet; keep buttons compact here.
        Row(
      children: [
        Expanded(
          child: QuantitySelectorButton(
            quantity: 1,
            cost: 0, // building consumes materials, not money shown here
            isSelected: currentPreference == 1,
            canAfford: availableMaterials,
            onPressed: () => _handleBuildQuantitySelection(1),
            label: 'Build 1',
          ),
        ),
        const SizedBox(width: 8),
        // Removed Build 5 option per request
        Expanded(
          child: QuantitySelectorButton(
            quantity: 10,
            cost: 0,
            isSelected: currentPreference == 10,
            canAfford: availableMaterials,
            onPressed: () => _handleBuildQuantitySelection(10),
            label: 'Build 10',
          ),
        ),
      ],
        ),
      ],
    );
  }

  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isMaterial ? _material.name : _product.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isMaterial ? _material.description : _product.description,
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (mode == ItemCardMode.build) ...[
                    const Text('Materials', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildBuildMaterialsSection(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBuildMaterialsSection() {
    if (!_isProduct) return const SizedBox.shrink();

    // Only show materials section when the product is unlocked
    if (!gameService.isProductUnlocked(_product.id)) return const SizedBox.shrink();

    final selectedQty = gameService.getBuildQuantityPreference(_product.id);
    // Scale required materials by selected quantity
    final scaled = <String, int>{};
    _product.requiredMaterials.forEach((k, v) => scaled[k] = v * selectedQty);

    // Build a list of material entries with available counts
    final entries = scaled.entries.map((e) {
      final have = gameService.state.getMaterialCount(e.key) +
          gameService.state.getProductCount(e.key);
      final lacking = have < e.value;
      return {
        'id': e.key,
        'required': e.value,
        'have': have,
        'lacking': lacking,
      };
    }).toList();

    // Sort: lacking materials first, then by name
    entries.sort((a, b) {
      final la = a['lacking'] as bool;
      final lb = b['lacking'] as bool;
      if (la != lb) return la ? -1 : 1;
      final ida = a['id'] as String;
      final idb = b['id'] as String;
      return ida.compareTo(idb);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show per-unit requirements header
        if (_product.requiredMaterials.isNotEmpty) ...[
          Text(
            'Per unit:',
            style: TextStyle(color: Colors.grey[300], fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _product.requiredMaterials.entries.map((e) {
              final id = e.key;
              final qty = e.value;
              String name = id;
              String emoji = '';
              final m = data.GameData.getMaterial(id);
              if (m != null) {
                name = m.name;
                emoji = m.emoji;
              } else {
                final p = data.GameData.getProduct(id);
                if (p != null) {
                  name = p.name;
                  emoji = p.emoji;
                }
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[800]?.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (emoji.isNotEmpty)
                      GameIcon(
                        itemId: id,
                        fallbackEmoji: emoji,
                        size: 14,
                      ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$name ($qty)',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Required for $selectedQty:',
            style: TextStyle(color: Colors.grey[300], fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
        ],

  ...entries.map((entry) {
        final id = entry['id'] as String;
        final required = entry['required'] as int;
        final have = entry['have'] as int;
        final lacking = entry['lacking'] as bool;

        // Try to resolve a display name and emoji (fallback to id)
        String displayName = id;
        String emoji = '';
        final m = data.GameData.getMaterial(id);
        if (m != null) {
          displayName = m.name;
          emoji = m.emoji;
        } else {
          final p = data.GameData.getProduct(id);
          if (p != null) {
            displayName = p.name;
            emoji = p.emoji;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              if (emoji.isNotEmpty)
                GameIcon(
                  itemId: id,
                  fallbackEmoji: emoji,
                  size: 16,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$displayName: $have / $required',
                  style: TextStyle(
                    color: lacking ? Colors.red[300] : Colors.green[300],
                    fontSize: 12,
                    fontWeight: lacking ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      ],
    );
  }

  // Helper methods
  Color _getBorderColor() {
    switch (mode) {
      case ItemCardMode.buy:
        final cost = _material.buyPrice * gameService.getBuyQuantityPreference(_material.id);
        return gameService.state.canAfford(cost) ? Colors.green : Colors.red;
      case ItemCardMode.sell:
        final staged = gameService.getStagedQuantity(_product.id);
        if (staged > 0) {
          return Colors.purpleAccent;
        }
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

  // Production helpers for build mode
  bool get _canProduce => _isProduct && gameService.state.hasMaterialsFor(_product.requiredMaterials);
  bool get _isInProduction =>
      mode == ItemCardMode.build &&
      _isProduct &&
      gameService.hasAnyProduction(_product.id);
  // Note: production queuing now handled by service; removed _isInProduction guard.

  // Action handlers
  void _handleCardTap(BuildContext context) {
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
        HapticFeedback.lightImpact();
        if (onProductDetails != null) {
          onProductDetails!();
        } else {
          _showDetailsSheet(context);
        }
        break;
      case ItemCardMode.build:
        if (_canProduce) {
          // Allow queuing even if there's already production in progress;
          // startProduction will handle queuing logic.
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

  void _handleSellQuantityPreferenceSelection(int quantity, {bool isMax = false}) {
    HapticFeedback.lightImpact();
    final fleet = gameService.currentFleetTier;
    final prefQty = isMax ? fleet.maxUnitsPerType : quantity;
    gameService.setSellQuantityPreference(_product.id, prefQty);
  }

  void _handleAddToManifestFromPreference(BuildContext context) {
    final available = gameService.state.getProductCount(_product.id);
    if (available <= 0) {
      HapticFeedback.lightImpact();
      return;
    }

    final fleet = gameService.currentFleetTier;
    final currentPreference = gameService.getSellQuantityPreference(_product.id);
    final isMax = currentPreference >= fleet.maxUnitsPerType;
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (isMax) {
      final prevStaged = gameService.getStagedQuantity(_product.id);
      gameService.setManifestMaxForProduct(_product.id);
      final newStaged = gameService.getStagedQuantity(_product.id);
      final success = newStaged > prevStaged;

      if (success) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
        if (newStaged >= fleet.maxUnitsPerType) {
          messenger?.hideCurrentSnackBar();
          messenger?.showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Reached carrier per-type limit (${fleet.maxUnitsPerType} units for ${fleet.name}).',
              ),
              backgroundColor: Colors.orange[800],
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (gameService.manifestTotalUnits >= fleet.maxPayloadUnits) {
          messenger?.hideCurrentSnackBar();
          messenger?.showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Reached carrier payload capacity (${fleet.maxPayloadUnits} units for ${fleet.name}).',
              ),
              backgroundColor: Colors.orange[800],
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (gameService.manifestVarietyCount >= fleet.maxProductVarieties && prevStaged == 0) {
          messenger?.hideCurrentSnackBar();
          messenger?.showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Reached carrier variety limit (${fleet.maxProductVarieties} types for ${fleet.name}).',
              ),
              backgroundColor: Colors.orange[800],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      final qtyToAdd = math.min(currentPreference, available);
      final success = gameService.addToManifest(_product.id, qtyToAdd);
      if (success) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
        final currentStaged = gameService.getStagedQuantity(_product.id);
        if (currentStaged + qtyToAdd > fleet.maxUnitsPerType) {
          messenger?.hideCurrentSnackBar();
          messenger?.showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Exceeds carrier per-type limit (${fleet.maxUnitsPerType} units for ${fleet.name}).',
              ),
              backgroundColor: Colors.orange[800],
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (gameService.manifestTotalUnits + qtyToAdd > fleet.maxPayloadUnits) {
          messenger?.hideCurrentSnackBar();
          messenger?.showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Exceeds carrier payload capacity (${fleet.maxPayloadUnits} units for ${fleet.name}).',
              ),
              backgroundColor: Colors.orange[800],
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (gameService.manifestVarietyCount >= fleet.maxProductVarieties && currentStaged == 0) {
          messenger?.hideCurrentSnackBar();
          messenger?.showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Exceeds carrier variety limit (${fleet.maxProductVarieties} types for ${fleet.name}).',
              ),
              backgroundColor: Colors.orange[800],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _handleManifestStepperIncrement(BuildContext context, int stagedQty, int available) {
    final fleet = gameService.currentFleetTier;
    final currentPreference = gameService.getSellQuantityPreference(_product.id);
    final isMax = currentPreference >= fleet.maxUnitsPerType;

    if (isMax) {
      final prevStaged = stagedQty;
      gameService.setManifestMaxForProduct(_product.id);
      final newStaged = gameService.getStagedQuantity(_product.id);
      if (newStaged > prevStaged) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.lightImpact();
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Already at maximum capacity (${fleet.maxUnitsPerType} units for ${fleet.name}).',
            ),
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final stepQty = currentPreference;
    final remainingInventory = available - stagedQty;
    final remainingTypeCap = fleet.maxUnitsPerType - stagedQty;
    final remainingPayloadCap = fleet.maxPayloadUnits - gameService.manifestTotalUnits;
    final maxAddable = [remainingInventory, remainingTypeCap, remainingPayloadCap].reduce(math.min);

    if (maxAddable <= 0) {
      HapticFeedback.lightImpact();
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      if (remainingTypeCap <= 0) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Reached carrier per-type limit (${fleet.maxUnitsPerType} units for ${fleet.name}).',
            ),
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (remainingPayloadCap <= 0) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Reached carrier payload capacity (${fleet.maxPayloadUnits} units for ${fleet.name}).',
            ),
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final toAdd = math.min(stepQty, maxAddable);
    final targetQty = stagedQty + toAdd;
    final success = gameService.updateManifestQuantity(_product.id, targetQty);
    if (success) {
      HapticFeedback.lightImpact();
      if (toAdd < stepQty) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(
          SnackBar(
            content: Text('⚠️ Added $toAdd units (carrier/inventory limit reached).'),
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _handleManifestStepperDecrement(BuildContext context, int stagedQty) {
    HapticFeedback.lightImpact();
    final fleet = gameService.currentFleetTier;
    final currentPreference = gameService.getSellQuantityPreference(_product.id);
    final isMax = currentPreference >= fleet.maxUnitsPerType;

    if (isMax) {
      gameService.removeFromManifest(_product.id);
      return;
    }

    final stepQty = currentPreference;
    if (stagedQty - stepQty <= 0) {
      gameService.removeFromManifest(_product.id);
    } else {
      gameService.updateManifestQuantity(_product.id, stagedQty - stepQty);
    }
  }

  void _handleBuildQuantitySelection(int quantity) {
    // Build a scaled requirements map for the requested quantity and check materials
    final scaledRequired = <String, int>{};
    _product.requiredMaterials.forEach((key, value) {
      scaledRequired[key] = value * quantity;
    });

    final canBuild = gameService.state.hasMaterialsFor(scaledRequired);

    if (canBuild) {
      HapticFeedback.mediumImpact();
      gameService.startProduction(_product.id, quantity);
    } else {
      HapticFeedback.lightImpact();
    }

    // Remember preference regardless so the UI reflects the latest selection
    gameService.setBuildQuantityPreference(_product.id, quantity);
  }

  void _handleBuildAction() {
    if (_canProduce) {
      HapticFeedback.mediumImpact();
      final qty = gameService.getBuildQuantityPreference(_product.id);
      gameService.startProduction(_product.id, qty);
    }
  }
}

/// Enum defining the different modes for ItemCard
enum ItemCardMode {
  buy,    // For buying materials
  sell,   // For selling products  
  build,  // For building/producing products
}