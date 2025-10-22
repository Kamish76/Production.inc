import 'package:flutter/material.dart';

/// Consolidated message display widget for empty states and welcome messages
/// 
/// This widget replaces EmptyInventoryMessage and WelcomeMessageCard
/// with a single, mode-based implementation that reduces code duplication.
class MessageDisplay extends StatelessWidget {
  final MessageDisplayMode mode;
  
  // Common properties
  final IconData icon;
  final String title;
  final String subtitle;
  
  // Customizable properties
  final Color? iconColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final double? iconSize;
  final String? extraText;

  const MessageDisplay.empty({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.titleColor,
    this.subtitleColor,
    this.iconSize,
  }) : mode = MessageDisplayMode.empty,
       extraText = null;

  const MessageDisplay.welcome({
    super.key,
  }) : mode = MessageDisplayMode.welcome,
       icon = Icons.lightbulb_outline,
       title = 'Welcome to Production.Inc!',
       subtitle = 'Visit the Buy Materials screen to purchase materials and discover what you can build!',
       extraText = 'Start with cardboard to unlock your first product: Box 📦',
       iconColor = null,
       titleColor = null,
       subtitleColor = null,
       iconSize = 48;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case MessageDisplayMode.empty:
        return _buildEmptyMessage();
      case MessageDisplayMode.welcome:
        return _buildWelcomeCard();
    }
  }

  Widget _buildEmptyMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize ?? 80,
            color: iconColor ?? Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: titleColor ?? Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: subtitleColor ?? Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
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
            icon,
            color: Colors.blue[400],
            size: iconSize ?? 48,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.blue[300],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.blue[200],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (extraText != null) ...[
            const SizedBox(height: 8),
            Text(
              extraText!,
              style: TextStyle(
                color: Colors.blue[100],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Enum defining the different modes for MessageDisplay
enum MessageDisplayMode {
  empty,    // For empty state messages (expandable, centered)
  welcome,  // For welcome card messages (fixed size, styled card)
}