/// Models for the Sales Hub Selling Automation live queue and preview system.
library;

/// The type of action that selling automation will perform on its next tick.
enum AutoSellActionType {
  /// Automation will fulfill an eligible corporate B2B contract.
  b2bContract,

  /// Automation will assemble and dispatch a storefront batch shipment.
  batchDispatch,

  /// Automation is waiting for whitelisted products to be produced/in stock.
  waitingStock,

  /// Automation is waiting for an active logistics courier to return (fleet busy).
  waitingFleet,

  /// Automation is turned off or no dispatchers are owned.
  idleDisabled,
}

/// Represents the evaluated next dispatch action of the Selling Automation engine.
class AutoSellNextAction {
  final AutoSellActionType actionType;
  final String title;
  final String subtitle;
  final Map<String, int> stagedItems;
  final double estimatedRevenue;
  final double estimatedTransitSeconds;
  final bool isReady;
  final String? clientOrBatchName;

  const AutoSellNextAction({
    required this.actionType,
    required this.title,
    required this.subtitle,
    required this.stagedItems,
    required this.estimatedRevenue,
    required this.estimatedTransitSeconds,
    required this.isReady,
    this.clientOrBatchName,
  });
}
