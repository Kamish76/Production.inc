import 'package:flutter/material.dart';
import '../services/production_game_service.dart';
import '../models/game_models.dart' as game;

/// Consolidated dialog widget for confirmations and product details
/// 
/// This widget replaces ConfirmationDialog and ProductDetailsDialog
/// with a single, mode-based implementation that reduces code duplication.
class GameDialog extends StatelessWidget {
  final GameDialogMode mode;
  
  // Common properties
  final String title;
  final IconData? icon;
  final Color? iconColor;
  
  // Confirmation dialog properties
  final String? content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  
  // Product details dialog properties
  final game.Product? product;
  final ProductionGameService? gameService;

  const GameDialog.confirmation({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.iconColor,
    required this.confirmText,
    required this.onConfirm,
    this.cancelText = 'Cancel',
    this.onCancel,
  }) : mode = GameDialogMode.confirmation,
       product = null,
       gameService = null;

  const GameDialog.productDetails({
    super.key,
    required this.product,
    required this.gameService,
  }) : mode = GameDialogMode.productDetails,
       title = '',
       content = null,
       icon = null,
       iconColor = null,
       confirmText = null,
       cancelText = null,
       onConfirm = null,
       onCancel = null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: _buildTitle(),
      content: _buildContent(),
      actions: _buildActions(context),
    );
  }

  Widget _buildTitle() {
    switch (mode) {
      case GameDialogMode.confirmation:
        return Row(
          children: [
            Icon(icon!, color: iconColor!),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        );
      case GameDialogMode.productDetails:
        return Row(
          children: [
            Text(product!.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                product!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildContent() {
    switch (mode) {
      case GameDialogMode.confirmation:
        return Text(
          content!,
          style: const TextStyle(color: Colors.white70),
        );
      case GameDialogMode.productDetails:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product!.description,
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Production stats
              _buildStatRow(
                'Production Time',
                '${(product!.productionTimeSeconds / 60).toStringAsFixed(1)} minutes',
              ),
              _buildStatRow(
                'Sell Price',
                '\$${product!.sellPrice.toStringAsFixed(2)}',
              ),
              _buildStatRow('Tier', gameService!.getTierName(product!.levelId)),

              const SizedBox(height: 16),

              // Required materials
              if (product!.requiredMaterials.isNotEmpty) ...[
                const Text(
                  'Required Materials:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...product!.requiredMaterials.entries.map((entry) {
                  final materialId = entry.key;
                  final required = entry.value;
                  final owned =
                      gameService!.state.getMaterialCount(materialId) +
                          gameService!.state.getProductCount(materialId);
                  final hasEnough = owned >= required;

                  final materialName =
                      gameService!.getMaterial(materialId)?.name ??
                          gameService!.getProduct(materialId)?.name ??
                          materialId;

                  final emoji = gameService!.getMaterial(materialId)?.emoji ??
                      gameService!.getProduct(materialId)?.emoji ??
                      '📦';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            materialName,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: hasEnough
                                ? Colors.green[600]
                                : Colors.red[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$owned/$required',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    switch (mode) {
      case GameDialogMode.confirmation:
        return [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onCancel != null) onCancel!();
            },
            child: Text(
              cancelText!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText!),
          ),
        ];
      case GameDialogMode.productDetails:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: Colors.blue[400])),
          ),
        ];
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Enum defining the different modes for GameDialog
enum GameDialogMode {
  confirmation,    // For confirmation dialogs with yes/no actions
  productDetails,  // For product details display
}