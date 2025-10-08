import 'package:flutter/material.dart';

/// Welcome message card shown to completely new players
class WelcomeMessageCard extends StatelessWidget {
  const WelcomeMessageCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[900]!.withValues(alpha: 0.3),
            Colors.blue[800]!.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue[400]!.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Colors.blue[400],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome to Production.Inc!',
            style: TextStyle(
              color: Colors.blue[300],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Visit the Buy Materials screen to purchase materials and discover what you can build!',
            style: TextStyle(
              color: Colors.blue[200],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start with cardboard to unlock your first product: Box 📦',
            style: TextStyle(
              color: Colors.blue[100],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
