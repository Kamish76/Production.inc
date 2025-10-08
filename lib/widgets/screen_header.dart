import 'package:flutter/material.dart';

/// Reusable screen header widget used across multiple screens
/// Provides consistent styling for screen titles with icons and optional actions
class ScreenHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final List<Widget>? actions;

  const ScreenHeader({
    Key? key,
    required this.icon,
    required this.title,
    required this.iconColor,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Add any additional action widgets
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}