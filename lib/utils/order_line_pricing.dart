import 'dart:convert';

import 'package:digitalerp/utils/shared_pre.dart';

/// How a single order line was priced: the item-master MRP, the Net Rate the
/// user chose to charge, and the line discount.
///
/// The cart API stores only the final `itemrate` — there is no MRP, net-rate or
/// discount column on `addcartnew` / `getcarddetail` yet — so this is a local
/// mirror, keyed by item id, that lets the Place Order screen show how each
/// amount was arrived at.
///
/// Once the backend adds those fields, this whole file can go and the values
/// can be read straight off the cart response instead.
class OrderLinePricing {
  final double mrp;
  final double netRate;
  final double discountPercent;

  const OrderLinePricing({
    required this.mrp,
    required this.netRate,
    required this.discountPercent,
  });

  /// Net Rate less the line discount — must match the `itemrate` that was sent
  /// to the cart.
  double get finalRate {
    final pct = discountPercent.clamp(0, 100).toDouble();
    return netRate - (netRate * pct / 100);
  }

  /// True when the line was left at MRP with no discount, in which case there
  /// is no calculation worth spelling out.
  bool get isPlain =>
      discountPercent == 0 && (netRate - mrp).abs() < 0.001;

  Map<String, dynamic> toJson() => {
        'mrp': mrp,
        'net': netRate,
        'disc': discountPercent,
      };

  factory OrderLinePricing.fromJson(Map<String, dynamic> json) =>
      OrderLinePricing(
        mrp: (json['mrp'] as num?)?.toDouble() ?? 0,
        netRate: (json['net'] as num?)?.toDouble() ?? 0,
        discountPercent: (json['disc'] as num?)?.toDouble() ?? 0,
      );
}

/// Stores [OrderLinePricing] per item id alongside the server cart.
class OrderLinePricingStore {
  static Future<Map<int, OrderLinePricing>> load() async {
    final raw = await SharedPre.getStringValue(SharedPre.orderLinePricing);
    if (raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(
          int.tryParse(k) ?? -1,
          OrderLinePricing.fromJson(v as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      /// A malformed mirror must never block checkout — the screen simply
      /// falls back to showing the rate on its own.
      return {};
    }
  }

  /// Merges rather than replaces, because a cart can be built up over several
  /// visits to the order screen.
  static Future<void> merge(Map<int, OrderLinePricing> entries) async {
    if (entries.isEmpty) return;
    final current = await load();
    current.addAll(entries);
    await SharedPre.setValue(
      SharedPre.orderLinePricing,
      json.encode(
        current.map((k, v) => MapEntry(k.toString(), v.toJson())),
      ),
    );
  }

  static Future<void> clear() =>
      SharedPre.clear(SharedPre.orderLinePricing);

  /// Looks up the breakdown for a cart row, returning null unless it is worth
  /// showing *and* still agrees with the rate the server holds.
  ///
  /// A stale entry — item deleted and re-added at MRP, or priced on another
  /// device — must never be rendered as a calculation that does not add up.
  static OrderLinePricing? resolve(
    Map<int, OrderLinePricing> stored,
    int? productId,
    double? serverRate,
  ) {
    final pricing = stored[productId];
    if (pricing == null || pricing.isPlain) return null;
    if (((serverRate ?? 0) - pricing.finalRate).abs() > 0.05) return null;
    return pricing;
  }
}

/// Order-wide totals derived from the cart lines: what the goods list at, what
/// is actually being charged, and the difference.
///
/// Shared by the Cart and Place Order summaries so the two can never disagree.
class OrderTotals {
  /// Sum of MRP x quantity across every line.
  final double mrpTotal;

  /// Sum of Net Rate x quantity — after any rate override, before any line
  /// discount.
  final double netTotal;

  /// Sum of charged rate x quantity — what the order is actually worth.
  final double chargedTotal;

  const OrderTotals({
    required this.mrpTotal,
    required this.netTotal,
    required this.chargedTotal,
  });

  /// Money taken off by *discount percentages*, and nothing else.
  ///
  /// Deliberately measured from [netTotal], not [mrpTotal]: pricing a line at
  /// a Net Rate below MRP is a repricing, not a discount, and reporting the
  /// whole MRP gap as "Discount 36%" states a percentage the user never
  /// entered.
  double get discountAmount {
    final diff = netTotal - chargedTotal;
    return diff > 0.01 ? diff : 0;
  }

  double get discountPercent =>
      netTotal <= 0 ? 0 : (discountAmount / netTotal) * 100;

  bool get hasDiscount => discountAmount > 0.01;

  /// True when the goods were priced below their list value at all — by a Net
  /// Rate, a discount, or both. Gates the "Total MRP" row.
  bool get isBelowMrp => (mrpTotal - chargedTotal) > 0.01;

  /// Whether a Net Rate override happened, i.e. the intermediate "Net Amount"
  /// step is worth spelling out.
  bool get hasRateOverride => (mrpTotal - netTotal).abs() > 0.01;

  /// Builds totals for a set of cart lines.
  ///
  /// [mrpOfLine] should return the best MRP known for a line — the exact value
  /// recorded when the line was added (the branch selling rate). Returning the
  /// charged rate is the correct fallback: an unknown list price then adds no
  /// phantom discount.
  static OrderTotals from<T>({
    required Iterable<T> lines,
    required double Function(T) mrpOfLine,
    required double Function(T) netRateOf,
    required double Function(T) chargedRateOf,
    required double Function(T) quantityOf,
  }) {
    double mrp = 0;
    double net = 0;
    double charged = 0;
    for (final line in lines) {
      final qty = quantityOf(line);
      mrp += mrpOfLine(line) * qty;
      net += netRateOf(line) * qty;
      charged += chargedRateOf(line) * qty;
    }
    return OrderTotals(
        mrpTotal: mrp, netTotal: net, chargedTotal: charged);
  }
}
