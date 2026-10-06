import 'dart:convert';

import 'package:digitalerp/utils/shared_pre.dart';

/// Which document the order is being raised as.
///
/// Chosen at the top of the order-entry screen and carried through to
/// checkout. It decides two things: whether the MRP may be retyped per line,
/// and whether tax is added at the bottom of the bill.
///
/// NOTE: `placeorder/orderentry` has no order-type column today, so this is
/// held on the device alongside the server cart (like the selected party) and
/// is NOT posted. [apiValue] is ready for the field the backend team adds.
enum OrderType {
  estimate,
  pi;

  String get label => this == OrderType.pi ? 'PI' : 'Estimate';

  /// The literal the backend is expected to take once the column exists.
  String get apiValue => this == OrderType.pi ? 'PI' : 'Estimate';

  /// Tax does NOT depend on the document type. Both an Estimate and a PI are
  /// taxed — the backend calculates GST on every order (2026-10-06), so the
  /// Place Order screen no longer offers a choice and the bill takes its own
  /// [OrderBill.chargesGst] flag, which the app always sets.
  ///
  /// On a PI the product's price is the item-master rate and may not be
  /// retyped; only the Net Rate below it can move.
  bool get allowsMrpEdit => this == OrderType.estimate;

  /// A PI's discount is typed per line (type + % or ₹). An Estimate has no
  /// discount boxes: the user types an MRP and a Taxable Amount and the gap
  /// between them IS the discount, derived at save time and posted without
  /// ever being shown.
  bool get showsDiscountFields => this == OrderType.pi;

  /// What the editable per-unit rate is called on the line. On an Estimate it
  /// is the figure tax would be worked out on, so it is labelled as such.
  String get rateFieldLabel =>
      this == OrderType.pi ? 'Net Rate' : 'Taxable Amt';

  static OrderType fromName(String? name) =>
      name == OrderType.pi.name ? OrderType.pi : OrderType.estimate;
}

/// Whether the order is taxed, as `placeorderlarnza` spells it.
///
/// The backend added `ordergsttype` on 2026-09-30 to carry the Place Order
/// screen's GST selector. It is independent of [OrderType]: an Estimate is
/// raised either way, a PI is always [calculated].
enum OrderGstMode {
  calculated,
  notCalculated;

  /// The exact literals the save proc expects — capitalised just like this,
  /// not `GSTCalculation`.
  String get apiValue =>
      this == OrderGstMode.calculated ? 'Gstcalculation' : 'Gstnotcalculation';

  static OrderGstMode of(bool gstApplicable) =>
      gstApplicable ? OrderGstMode.calculated : OrderGstMode.notCalculated;
}

/// How a line's discount was expressed. Only ever one of the two — switching
/// the type clears the other value so both can never reach the cart.
enum OrderDiscountType {
  percent,
  amount;

  String get label =>
      this == OrderDiscountType.amount ? 'Discount Amount' : 'Discount %';

  String get shortLabel =>
      this == OrderDiscountType.amount ? 'Discount Amt' : 'Discount %';

  static OrderDiscountType fromName(String? name) =>
      name == OrderDiscountType.amount.name
          ? OrderDiscountType.amount
          : OrderDiscountType.percent;
}

/// How a single order line was priced: the MRP it started from, the Net Rate
/// the user chose to charge, the line discount, and the item's GST rate.
///
/// The cart API stores only the final `itemrate` — there is no MRP, net-rate,
/// discount or tax column on `addtocartwithnetrate` / `getcarddetail` — so
/// this is a local mirror, keyed by item id, that lets the Cart and Place
/// Order screens show how each amount was arrived at.
///
/// Once the backend adds those fields, this whole file can go and the values
/// can be read straight off the cart response instead.
class OrderLinePricing {
  final double mrp;
  final double netRate;

  /// Percentage off [netRate]. Meaningful only when [discountType] is
  /// [OrderDiscountType.percent].
  final double discountPercent;

  /// Flat rupees off [netRate], **per unit** — the cart stores a per-unit rate
  /// and nothing else, so a whole-line amount could not survive a later
  /// quantity change. Meaningful only when [discountType] is
  /// [OrderDiscountType.amount].
  final double discountAmount;

  final OrderDiscountType discountType;

  /// The item's GST rate, from `itemdetail`. Percent only — the backend sends
  /// no tax amount and no CGST/SGST/IGST split, so the amount is worked out
  /// here. Zero means "not known yet", never "tax free".
  final double gstPercent;

  const OrderLinePricing({
    required this.mrp,
    required this.netRate,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.discountType = OrderDiscountType.percent,
    this.gstPercent = 0,
  });

  OrderLinePricing copyWith({double? gstPercent}) => OrderLinePricing(
        mrp: mrp,
        netRate: netRate,
        discountPercent: discountPercent,
        discountAmount: discountAmount,
        discountType: discountType,
        gstPercent: gstPercent ?? this.gstPercent,
      );

  /// Rupees taken off one unit by the discount, whichever way it was entered.
  /// Never more than the Net Rate — a line cannot go negative.
  double get discountPerUnit {
    if (netRate <= 0) return 0;
    final off = discountType == OrderDiscountType.amount
        ? discountAmount
        : netRate * discountPercent / 100;
    return off.clamp(0, netRate).toDouble();
  }

  /// Net Rate less the line discount — must match the `itemrate` the cart
  /// holds for this line.
  double get finalRate => netRate - discountPerUnit;

  bool get hasDiscount => discountPerUnit > 0.001;

  /// True when the line was left at MRP with no discount, in which case there
  /// is no calculation worth spelling out.
  bool get isPlain => !hasDiscount && (netRate - mrp).abs() < 0.001;

  Map<String, dynamic> toJson() => {
        'mrp': mrp,
        'net': netRate,
        'disc': discountPercent,
        'discamt': discountAmount,
        'disctype': discountType.name,
        'gst': gstPercent,
      };

  /// Tolerates mirrors written before the discount-type and GST fields
  /// existed: a stored entry with neither key reads back as a percent
  /// discount with an unknown tax rate, exactly as it behaved then.
  factory OrderLinePricing.fromJson(Map<String, dynamic> json) =>
      OrderLinePricing(
        mrp: (json['mrp'] as num?)?.toDouble() ?? 0,
        netRate: (json['net'] as num?)?.toDouble() ?? 0,
        discountPercent: (json['disc'] as num?)?.toDouble() ?? 0,
        discountAmount: (json['discamt'] as num?)?.toDouble() ?? 0,
        discountType: OrderDiscountType.fromName(json['disctype'] as String?),
        gstPercent: (json['gst'] as num?)?.toDouble() ?? 0,
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
    await _write(current);
  }

  static Future<void> _write(Map<int, OrderLinePricing> entries) =>
      SharedPre.setValue(
        SharedPre.orderLinePricing,
        json.encode(entries.map((k, v) => MapEntry(k.toString(), v.toJson()))),
      );

  /// Writes back GST rates fetched after the lines were staged, leaving every
  /// other field of each entry alone.
  static Future<void> mergeGstPercents(Map<int, double> gstByItemId) async {
    if (gstByItemId.isEmpty) return;
    final current = await load();
    var changed = false;
    gstByItemId.forEach((id, pct) {
      final existing = current[id];
      if (existing != null && existing.gstPercent != pct) {
        current[id] = existing.copyWith(gstPercent: pct);
        changed = true;
      }
    });
    if (changed) await _write(current);
  }

  static Future<void> clear() => SharedPre.clear(SharedPre.orderLinePricing);

  /// The breakdown for a cart row, or null unless it is worth showing *and*
  /// still agrees with the rate the server holds.
  ///
  /// A stale entry — item deleted and re-added at MRP, or priced on another
  /// device — must never be rendered as a calculation that does not add up.
  static OrderLinePricing? resolve(
    Map<int, OrderLinePricing> stored,
    int? productId,
    double? serverRate,
  ) {
    final pricing = raw(stored, productId, serverRate);
    if (pricing == null || pricing.isPlain) return null;
    return pricing;
  }

  /// Like [resolve] but keeps plain lines, which still carry a GST rate worth
  /// taxing. Same staleness guard.
  static OrderLinePricing? raw(
    Map<int, OrderLinePricing> stored,
    int? productId,
    double? serverRate,
  ) {
    final pricing = stored[productId];
    if (pricing == null) return null;
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

  /// Sum of charged rate x quantity — what the goods are actually worth.
  final double chargedTotal;

  /// Sum of charged amount x the line's GST rate. Zero on an Estimate and on
  /// any line whose rate is not known yet.
  final double gstTotal;

  const OrderTotals({
    required this.mrpTotal,
    required this.netTotal,
    required this.chargedTotal,
    this.gstTotal = 0,
  });

  /// Money taken off by *discounts*, and nothing else.
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

  bool get hasGst => gstTotal > 0.01;

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
  ///
  /// [gstPercentOf] returns the line's tax rate; pass a function that always
  /// answers 0 (the default) for a tax-free document such as an Estimate.
  static OrderTotals from<T>({
    required Iterable<T> lines,
    required double Function(T) mrpOfLine,
    required double Function(T) netRateOf,
    required double Function(T) chargedRateOf,
    required double Function(T) quantityOf,
    double Function(T)? gstPercentOf,
  }) {
    double mrp = 0;
    double net = 0;
    double charged = 0;
    double gst = 0;
    for (final line in lines) {
      final qty = quantityOf(line);
      final lineCharged = chargedRateOf(line) * qty;
      mrp += mrpOfLine(line) * qty;
      net += netRateOf(line) * qty;
      charged += lineCharged;
      if (gstPercentOf != null) {
        gst += lineCharged * gstPercentOf(line) / 100;
      }
    }
    return OrderTotals(
      mrpTotal: mrp,
      netTotal: net,
      chargedTotal: charged,
      gstTotal: gst,
    );
  }
}

/// The packaging line: an amount the user types on either document type, plus
/// a fixed 18% tax on a PI only, never editable.
///
/// NOTE: `placeorder/orderentry` has no packaging column today, so this is
/// displayed and rolled into the total shown to the user but is NOT posted.
class PackagingCharge {
  /// Fixed by the business, independent of any product's GST rate.
  static const double gstPercent = 18.0;

  final double base;

  const PackagingCharge(this.base);

  double get gstAmount => base <= 0 ? 0 : base * gstPercent / 100;

  double get total => base + gstAmount;

  bool get isCharged => base > 0.001;
}

/// The whole bill for the Place Order screen: goods, tax, packaging.
///
/// Built from [OrderTotals] so the goods half can never disagree with the Cart
/// screen, with the PI-only additions layered on top.
class OrderBill {
  final OrderTotals totals;
  final PackagingCharge packaging;
  final double shipping;

  /// False for an Estimate, which is quoted tax-free.
  final bool chargesGst;

  const OrderBill({
    required this.totals,
    required this.packaging,
    required this.chargesGst,
    this.shipping = 0,
  });

  /// What the goods come to after every discount — the figure tax is worked
  /// out on.
  double get taxableAmount => totals.chargedTotal;

  double get productGst => chargesGst ? totals.gstTotal : 0;

  /// Packaging is charged on both document types; only its tax is PI-only.
  double get packagingBase => packaging.base;

  double get packagingGst => chargesGst ? packaging.gstAmount : 0;

  /// Order of operations: discounts are already inside [taxableAmount], tax
  /// goes on top of that, then packaging with its own separate tax.
  double get finalTotal =>
      taxableAmount + productGst + packagingBase + packagingGst + shipping;
}
