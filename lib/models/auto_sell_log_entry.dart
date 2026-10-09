import 'dart:convert';
import 'auto_sell_preview.dart';
export 'auto_sell_preview.dart';

/// Represents a single historical record of an automated sales dispatch or contract fulfillment.
class AutoSellLogEntry {
  final String id;
  final DateTime timestamp;
  final AutoSellActionType actionType;
  final String title;
  final Map<String, int> items;
  final double totalRevenue;
  final String? clientOrBatchName;

  const AutoSellLogEntry({
    required this.id,
    required this.timestamp,
    required this.actionType,
    required this.title,
    required this.items,
    required this.totalRevenue,
    this.clientOrBatchName,
  });

  int get totalUnits => items.values.fold(0, (sum, qty) => sum + qty);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'action_type': actionType.name,
      'title': title,
      'items': jsonEncode(items),
      'total_revenue': totalRevenue,
      'client_or_batch_name': clientOrBatchName,
    };
  }

  factory AutoSellLogEntry.fromJson(Map<String, dynamic> json) {
    Map<String, int> parsedItems = {};
    final rawItems = json['items'];
    if (rawItems is String) {
      try {
        final decoded = jsonDecode(rawItems);
        if (decoded is Map) {
          parsedItems = decoded.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          );
        }
      } catch (_) {}
    } else if (rawItems is Map) {
      parsedItems = rawItems.map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      );
    }

    AutoSellActionType type = AutoSellActionType.batchDispatch;
    final typeName = json['action_type'] as String?;
    if (typeName != null) {
      for (final val in AutoSellActionType.values) {
        if (val.name == typeName) {
          type = val;
          break;
        }
      }
    }

    final rawTime = json['timestamp'];
    DateTime time;
    if (rawTime is int) {
      time = DateTime.fromMillisecondsSinceEpoch(rawTime);
    } else if (rawTime is String) {
      time = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else {
      time = DateTime.now();
    }

    return AutoSellLogEntry(
      id: json['id'] as String? ?? 'log_${DateTime.now().microsecondsSinceEpoch}',
      timestamp: time,
      actionType: type,
      title: json['title'] as String? ?? 'Automated Dispatch',
      items: parsedItems,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      clientOrBatchName: json['client_or_batch_name'] as String?,
    );
  }

  AutoSellLogEntry copyWith({
    String? id,
    DateTime? timestamp,
    AutoSellActionType? actionType,
    String? title,
    Map<String, int>? items,
    double? totalRevenue,
    String? clientOrBatchName,
  }) {
    return AutoSellLogEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      actionType: actionType ?? this.actionType,
      title: title ?? this.title,
      items: items ?? this.items,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      clientOrBatchName: clientOrBatchName ?? this.clientOrBatchName,
    );
  }
}
