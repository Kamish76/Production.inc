import 'package:flutter/material.dart';
import 'machine_setup_view.dart';

/// Modal bottom sheet for configuring Selling Automation rules,
/// live queue preview, and the product whitelist matrix.
/// Reuses [MachineSetupView] in bottom sheet mode.
class AutoSellSetupSheet extends StatelessWidget {
  const AutoSellSetupSheet({super.key});

  /// Displays the sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AutoSellSetupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const MachineSetupView(isBottomSheet: true);
  }
}
