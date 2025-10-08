// TierExpansionPanel widget for product tiers
import 'package:flutter/material.dart';

class TierExpansionPanel extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final IconData? icon;
  final String? badge;
  final String? subtitle;
  final Color? primaryColor;
  final Color? backgroundColor;

  const TierExpansionPanel({
    Key? key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.icon,
    this.badge,
    this.subtitle,
    this.primaryColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<TierExpansionPanel> createState() => _TierExpansionPanelState();
}

class _TierExpansionPanelState extends State<TierExpansionPanel> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _handleExpansion(bool expanded) {
    setState(() {
      _expanded = expanded;
    });
    if (widget.onExpansionChanged != null) {
      widget.onExpansionChanged!(expanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? Colors.blue[400]!;
    final backgroundColor = widget.backgroundColor ?? Colors.blue[900]!.withValues(alpha: 0.3);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom tier header
        GestureDetector(
          onTap: () => _handleExpansion(!_expanded),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    '${widget.title}${widget.subtitle != null ? ' ${widget.subtitle}' : ''}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                // Badge (product count)
                if (widget.badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.badge!,
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Expand/collapse icon
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Collapsible content
        if (_expanded) widget.child,
      ],
    );
  }
}
