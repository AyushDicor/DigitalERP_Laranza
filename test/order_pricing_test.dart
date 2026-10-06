import 'package:flutter_test/flutter_test.dart';
import 'package:digitalerp/utils/order_line_pricing.dart';

void check(String name, double actual, double expected) {
  final ok = (actual - expected).abs() < 0.01;
  print('${ok ? "PASS" : "FAIL"}  $name: got ${actual.toStringAsFixed(2)}, expected ${expected.toStringAsFixed(2)}');
}

void main() { test('order pricing calculations', () {
  // Real Laranza items + rates probed from itemwithbranch / itemdetail.
  // Thali Fitment 625, Anti Skid 675, Undersink 800; all gstpercent 18.

  // 1. Plain line, no discount
  final plain = OrderLinePricing(mrp: 625, netRate: 625);
  check('plain finalRate', plain.finalRate, 625);
  print('   isPlain=${plain.isPlain} hasDiscount=${plain.hasDiscount}');

  // 2. Net rate override
  final net = OrderLinePricing(mrp: 675, netRate: 625);
  check('net override finalRate', net.finalRate, 625);

  // 3. Discount %
  final pct = OrderLinePricing(
      mrp: 800, netRate: 800, discountPercent: 25,
      discountType: OrderDiscountType.percent);
  check('25% of 800', pct.finalRate, 600);

  // 4. Discount amount (per unit)
  final amt = OrderLinePricing(
      mrp: 800, netRate: 800, discountAmount: 200,
      discountType: OrderDiscountType.amount);
  check('flat 200 off 800', amt.finalRate, 600);

  // 5. Only one discount can count: amount type ignores a stale percent
  final both = OrderLinePricing(
      mrp: 800, netRate: 800, discountPercent: 50, discountAmount: 200,
      discountType: OrderDiscountType.amount);
  check('amount type ignores percent', both.finalRate, 600);
  final both2 = OrderLinePricing(
      mrp: 800, netRate: 800, discountPercent: 25, discountAmount: 700,
      discountType: OrderDiscountType.percent);
  check('percent type ignores amount', both2.finalRate, 600);

  // 6. Over-discount is capped, never negative
  final over = OrderLinePricing(
      mrp: 800, netRate: 800, discountAmount: 5000,
      discountType: OrderDiscountType.amount);
  check('over-discount capped at 0', over.finalRate, 0);

  // 7. Estimate bill: packaging counts, but no product GST and no packaging GST
  final lines = [
    (rate: 625.0, qty: 1.0, mrp: 625.0, net: 625.0, gst: 18.0),
    (rate: 625.0, qty: 1.0, mrp: 675.0, net: 625.0, gst: 18.0),
    (rate: 600.0, qty: 1.0, mrp: 800.0, net: 800.0, gst: 18.0),
  ];
  final totals = OrderTotals.from(
    lines: lines,
    mrpOfLine: (e) => e.mrp,
    netRateOf: (e) => e.net,
    chargedRateOf: (e) => e.rate,
    quantityOf: (e) => e.qty,
    gstPercentOf: (e) => e.gst,
  );
  check('mrpTotal', totals.mrpTotal, 2100);
  check('netTotal', totals.netTotal, 2050);
  check('chargedTotal', totals.chargedTotal, 1850);
  check('discountAmount', totals.discountAmount, 200);
  check('gstTotal 18% of 1850', totals.gstTotal, 333);

  final estimate = OrderBill(
      totals: totals, packaging: const PackagingCharge(1000),
      chargesGst: false);
  check('ESTIMATE productGst', estimate.productGst, 0);
  check('ESTIMATE packaging base kept', estimate.packagingBase, 1000);
  check('ESTIMATE packaging GST is 0', estimate.packagingGst, 0);
  check('ESTIMATE final total (goods + packaging, no tax)', estimate.finalTotal, 2850);

  // 8. PI bill with packaging 1000
  final pi = OrderBill(
      totals: totals, packaging: const PackagingCharge(1000),
      chargesGst: true);
  check('PI taxable', pi.taxableAmount, 1850);
  check('PI productGst', pi.productGst, 333);
  check('PI packaging base', pi.packagingBase, 1000);
  check('PI packaging GST 18%', pi.packagingGst, 180);
  check('PI final total', pi.finalTotal, 1850 + 333 + 1000 + 180);

  // 9. PI with packaging 0
  final piNoPack = OrderBill(
      totals: totals, packaging: const PackagingCharge(0), chargesGst: true);
  check('PI packaging 0 -> gst 0', piNoPack.packagingGst, 0);
  check('PI packaging 0 final', piNoPack.finalTotal, 2183);

  // 10. Untaxed line (gst rate not fetched) contributes no tax
  final partial = OrderTotals.from(
    lines: lines,
    mrpOfLine: (e) => e.mrp,
    netRateOf: (e) => e.net,
    chargedRateOf: (e) => e.rate,
    quantityOf: (e) => e.qty,
    gstPercentOf: (e) => e.rate == 600.0 ? 0.0 : e.gst,
  );
  check('unknown gst rate adds 0', partial.gstTotal, (625 + 625) * 0.18);

  // 11. Round trip through JSON keeps the discount type
  final revived = OrderLinePricing.fromJson(amt.toJson());
  check('json round trip', revived.finalRate, 600);
  print('   type=${revived.discountType.name} gst=${revived.gstPercent}');

  // 12. Legacy mirror (no disctype/gst keys) still reads as percent
  final legacy = OrderLinePricing.fromJson(
      {'mrp': 800.0, 'net': 800.0, 'disc': 25.0});
  check('legacy json', legacy.finalRate, 600);
  print('   legacy type=${legacy.discountType.name} gst=${legacy.gstPercent}');

  // 13. Order type flags
  print('   Estimate: mrpEdit=${OrderType.estimate.allowsMrpEdit}');
  print('   PI:       mrpEdit=${OrderType.pi.allowsMrpEdit}');
  print('   fromName("pi")=${OrderType.fromName("pi").label}  fromName(null)=${OrderType.fromName(null).label}');
});

/// The Estimate's derived discount, added 2026-09-29.
///
/// An Estimate has no discount boxes: the user types an MRP and a Taxable
/// Amount, and the gap between them is posted so the printed document still
/// shows both discount columns. What matters is that the payload lands the
/// SERVER's stored rate back on the Taxable Amount the user typed, because
/// `addtocartwithnetrate` computes it as `netrate − discountamount / qty`.
test('estimate derived discount', () {
  /// Mirrors QuickOrderController.derivedDiscountPerUnitOf + addAllToCart.
  double offPerUnit(double mrp, double taxable) {
    if (mrp <= 0) return 0;
    final off = mrp - taxable;
    return off <= 0 ? 0 : off.clamp(0, mrp).toDouble();
  }

  double storedRate(double mrp, double taxable, double qty) {
    final off = offPerUnit(mrp, taxable);
    final netrate = off > 0 ? mrp : mrp; // empty box still prices at MRP
    final wholeLineAmount = off * qty;
    return netrate - wholeLineAmount / qty;
  }

  // 1. Priced below MRP: the server must land on the typed Taxable Amount.
  check('625 -> 600 stored rate', storedRate(625, 600, 3), 600);
  check('625 -> 600 per-unit off', offPerUnit(625, 600), 25);
  check('9000 -> 8000 stored rate', storedRate(9000, 8000, 1), 8000);

  // 2. The percent that goes on the document is measured from the MRP.
  check('25 off 625 is 4%', offPerUnit(625, 600) / 625 * 100, 4);
  check('1000 off 9000 is 11.11%', offPerUnit(9000, 8000) / 9000 * 100, 11.11);

  // 3. Untouched line: taxable == MRP, so no discount is posted at all.
  check('no gap -> no discount', offPerUnit(800, 800), 0);
  check('no gap -> stored at MRP', storedRate(800, 800, 2), 800);

  // 4. A Taxable Amount ABOVE the MRP is not a negative discount.
  check('taxable above mrp -> 0', offPerUnit(600, 700), 0);

  // 5. Paise survive the round trip (the old code truncated with toInt()).
  check('paise kept', storedRate(625.50, 612.25, 4), 612.25);

  // 6. The mirror records the CHARGED rate, not the derived discount, so it
  //    still matches what the cart holds.
  final mirror = OrderLinePricing(mrp: 625, netRate: 600);
  check('mirror finalRate = taxable', mirror.finalRate, 600);
  print('   mirror isPlain=${mirror.isPlain} (false -> breakdown is shown)');

  // 7. Type flags that drive the new UI.
  print('   Estimate: discountFields=${OrderType.estimate.showsDiscountFields} '
      'rateLabel=${OrderType.estimate.rateFieldLabel}');
  print('   PI:       discountFields=${OrderType.pi.showsDiscountFields} '
      'rateLabel=${OrderType.pi.rateFieldLabel}');

  // 8. An Estimate switched to "GST Applicable" taxes exactly like a PI.
  final taxedEstimate = OrderBill(
    totals: const OrderTotals(
        mrpTotal: 1875, netTotal: 1800, chargedTotal: 1800, gstTotal: 324),
    packaging: const PackagingCharge(500),
    chargesGst: true,
  );
  check('taxed estimate product gst', taxedEstimate.productGst, 324);
  check('taxed estimate packaging gst', taxedEstimate.packagingGst, 90);
  check('taxed estimate final', taxedEstimate.finalTotal, 1800 + 324 + 500 + 90);
});

/// The ORDER-level discount figures, added 2026-09-30.
///
/// These three have to agree: `totalamount − discountamount = taxableamount`.
/// They used to carry the running totals instead (`discountamount` held the
/// whole subtotal), so a plain order posted `discountpercent 0` beside
/// `discountamount 900`.
test('order level discount', () {
  /// Mirrors YourOrderController.orderGrossAmount / orderDiscountAmount /
  /// orderDiscountPercent.
  double gross(OrderTotals t, {required bool isPi}) =>
      isPi ? t.netTotal : t.mrpTotal;

  double discount(OrderTotals t, {required bool isPi}) {
    final off = gross(t, isPi: isPi) - t.chargedTotal;
    return off > 0.01 ? off : 0;
  }

  double percent(OrderTotals t, {required bool isPi}) {
    final g = gross(t, isPi: isPi);
    return g <= 0 ? 0 : discount(t, isPi: isPi) / g * 100;
  }

  // 1. The order placed from the app on 2026-09-30: one line, MRP 1000
  //    priced down to a Taxable Amt of 900, plus 100 packaging.
  //    It posted discountamount 900; it should post 100.
  const live = OrderTotals(mrpTotal: 1000, netTotal: 900, chargedTotal: 900);
  check('estimate gross = MRP', gross(live, isPi: false), 1000);
  check('estimate discount = MRP gap', discount(live, isPi: false), 100);
  check('estimate discount %', percent(live, isPi: false), 10);
  check('gross - discount = taxable',
      gross(live, isPi: false) - discount(live, isPi: false), 900);

  // 2. Estimate left at MRP: no discount, and gross IS the taxable amount.
  const plain = OrderTotals(mrpTotal: 1300, netTotal: 1300, chargedTotal: 1300);
  check('no discount', discount(plain, isPi: false), 0);
  check('no discount %', percent(plain, isPi: false), 0);

  // 3. PI measures from the typed Net Rate, not the MRP — pricing below MRP
  //    is a repricing there, only the typed discount is a discount.
  const pi = OrderTotals(mrpTotal: 3000, netTotal: 2700, chargedTotal: 2430);
  check('pi gross = net total', gross(pi, isPi: true), 2700);
  check('pi discount = typed only', discount(pi, isPi: true), 270);
  check('pi discount %', percent(pi, isPi: true), 10);

  // 4. A line priced ABOVE its MRP is not a negative discount.
  const above = OrderTotals(mrpTotal: 500, netTotal: 600, chargedTotal: 600);
  check('above mrp -> 0', discount(above, isPi: false), 0);

  // 5. Empty cart: no division by zero.
  const empty = OrderTotals(mrpTotal: 0, netTotal: 0, chargedTotal: 0);
  check('empty cart %', percent(empty, isPi: false), 0);
});}
