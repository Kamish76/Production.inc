import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../models/game_data.dart';
import '../services/production_game_service.dart';

/// Header widget displaying corporate client standing, reputation progress, and active perks
class ClientReputationBar extends StatelessWidget {
  final ProductionGameService gameService;

  const ClientReputationBar({super.key, required this.gameService});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.handshake_outlined, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Corporate Standing (B2B)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Reputation Perks',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: GameData.corporateClients.map((client) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildClientChip(client),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClientChip(CorporateClient client) {
    final rep = gameService.state.getReputation(client.id);
    final level = gameService.state.getReputationLevel(client.id);
    final title = gameService.state.getReputationTitle(client.id);
    final clientColor = Color(client.primaryColorHex);

    // Calculate progress to next level
    int prevThreshold = 0;
    int nextThreshold = 100;
    if (level == 1) {
      prevThreshold = 100;
      nextThreshold = 300;
    } else if (level == 2) {
      prevThreshold = 300;
      nextThreshold = 700;
    } else if (level == 3) {
      prevThreshold = 700;
      nextThreshold = 1500;
    } else if (level >= 4) {
      prevThreshold = 1500;
      nextThreshold = 1500;
    }

    final double levelProgress = level >= 4
        ? 1.0
        : ((rep - prevThreshold) / (nextThreshold - prevThreshold)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF131726),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: clientColor.withValues(alpha: level > 0 ? 0.6 : 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(client.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  client.name,
                  style: TextStyle(
                    color: clientColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lvl $level: $title',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: levelProgress,
              minHeight: 4,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(clientColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$rep Rep',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (level > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '-${level * 5}%',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
