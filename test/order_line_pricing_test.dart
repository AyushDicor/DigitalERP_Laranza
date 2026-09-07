import 'package:digitalerp/utils/order_line_pricing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _totalsTests();
  _mrpPrecedenceTests();
  _netRateVsDiscountTests();
  test('zero-MRP line repriced via Net Rate is not treated as plain', () {
    const p = OrderLinePricing(mrp: 0, netRate: 200, discountPercent: 0);
    expect(p.isPlain, isFalse);
    expect(p.finalRate, 200);
  });

  test('resolve returns the breakdown when it matches the server rate', () {
    const p = OrderLinePricing(mrp: 0, netRate: 200, discountPercent: 0);
    final resolved = OrderLinePricingStore.resolve({256787: p}, 256787, 200.0);
    expect(resolved, isNotNull);
  });

  test('resolve rejects a stale entry', () {
    const p = OrderLinePricing(mrp: 614, netRate: 600, discountPercent: 10);
    expect(OrderLinePricingStore.resolve({1: p}, 1, 614.0), isNull);
    expect(OrderLinePricingStore.resolve({1: p}, 1, 540.0), isNotNull);
  });

  test('untouched line is plain and shows nothing', () {
    const p = OrderLinePricing(mrp: 614, netRate: 614, discountPercent: 0);
    expect(p.isPlain, isTrue);
    expect(OrderLinePricingStore.resolve({1: p}, 1, 614.0), isNull);
  });

  test('discounted rate keeps paise', () {
    const p = OrderLinePricing(mrp: 614, netRate: 614, discountPercent: 10);
    expect(p.finalRate.toStringAsFixed(2), '552.60');
  });

  test('json round-trip preserves values', () {
    const p = OrderLinePricing(mrp: 0, netRate: 200, discountPercent: 7.5);
    final back = OrderLinePricing.fromJson(p.toJson());
    expect(back.mrp, 0);
    expect(back.netRate, 200);
    expect(back.discountPercent, 7.5);
  });
}

/// List-price basis: the branch selling rate recorded when the line was added.
double _listPrice({double? recordedMrp, required double charged}) {
  if (recordedMrp != null && recordedMrp > 0) return recordedMrp;
  return charged;
}

void _mrpPrecedenceTests() {
  test('branch rate is the discount basis', () {
    expect(_listPrice(recordedMrp: 614, charged: 500), 614);
  });

  test('a zero branch rate falls back to the charged rate', () {
    expect(_listPrice(recordedMrp: 0, charged: 200), 200);
  });
}

/// A Net Rate override is a repricing, not a discount. Reporting the whole
/// MRP gap as a discount percentage states a number the user never entered.
void _netRateVsDiscountTests() {
  test('net rate alone is NOT reported as a discount', () {
    /// Reported case: MRP 625, Net Rate 400 typed, no discount %, qty 2.
    /// Previously shown as "Discount (36%) − ₹450".
    const t = OrderTotals(mrpTotal: 1250, netTotal: 800, chargedTotal: 800);
    expect(t.isBelowMrp, isTrue, reason: 'Total MRP row still shows');
    expect(t.hasDiscount, isFalse, reason: 'no discount was entered');
    expect(t.discountAmount, 0);
    expect(t.discountPercent, 0);
  });

  test('discount alone is measured off MRP when no override', () {
    /// MRP 1000, no net rate change, 10% discount -> charged 900.
    const t = OrderTotals(mrpTotal: 1000, netTotal: 1000, chargedTotal: 900);
    expect(t.hasRateOverride, isFalse);
    expect(t.hasDiscount, isTrue);
    expect(t.discountAmount, 100);
    expect(t.discountPercent, 10);
  });

  test('both: discount is measured off the net amount, not MRP', () {
    /// MRP 1250, net 800, then 10% off -> charged 720.
    /// The discount is 10% of 800, not 42% of 1250.
    const t = OrderTotals(mrpTotal: 1250, netTotal: 800, chargedTotal: 720);
    expect(t.hasRateOverride, isTrue);
    expect(t.hasDiscount, isTrue);
    expect(t.discountAmount, 80);
    expect(t.discountPercent, 10);
  });

  test('everything at MRP shows no extra rows', () {
    const t = OrderTotals(mrpTotal: 1250, netTotal: 1250, chargedTotal: 1250);
    expect(t.isBelowMrp, isFalse);
    expect(t.hasDiscount, isFalse);
    expect(t.hasRateOverride, isFalse);
  });

  test('a line priced above MRP never reads as a negative discount', () {
    const t = OrderTotals(mrpTotal: 100, netTotal: 150, chargedTotal: 150);
    expect(t.discountAmount, 0);
    expect(t.isBelowMrp, isFalse);
  });
}

/// Totals aggregated across cart lines, using the real per-line inputs.
void _totalsTests() {
  /// [mrp, netRate, chargedRate, qty]
  OrderTotals build(List<List<double>> lines) => OrderTotals.from<List<double>>(
        lines: lines,
        mrpOfLine: (l) => l[0],
        netRateOf: (l) => l[1],
        chargedRateOf: (l) => l[2],
        quantityOf: (l) => l[3],
      );

  test('aggregates MRP, net and charged across lines', () {
    final t = build([
      [625, 400, 400, 2], // repriced, no discount
      [100, 100, 90, 1], // 10% discount, no repricing
    ]);
    expect(t.mrpTotal, 1350);
    expect(t.netTotal, 900);
    expect(t.chargedTotal, 890);
    expect(t.discountAmount, 10);
  });

  test('an unknown line (net == charged) adds no phantom discount', () {
    final t = build([
      [500, 500, 500, 2],
    ]);
    expect(t.hasDiscount, isFalse);
    expect(t.isBelowMrp, isFalse);
  });
}
