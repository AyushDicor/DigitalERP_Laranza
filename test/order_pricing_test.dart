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
  print('   Estimate: mrpEdit=${OrderType.estimate.allowsMrpEdit} gst=${OrderType.estimate.chargesGst}');
  print('   PI:       mrpEdit=${OrderType.pi.allowsMrpEdit} gst=${OrderType.pi.chargesGst}');
  print('   fromName("pi")=${OrderType.fromName("pi").label}  fromName(null)=${OrderType.fromName(null).label}');
});}
