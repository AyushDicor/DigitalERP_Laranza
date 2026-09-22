import 'package:digitalerp/utils/order_line_pricing.dart';
import 'package:digitalerp/response/get_cart_list_response.dart';
import 'package:digitalerp/screen/ui/home/cart/your_order/your_order_controller.dart';
import 'package:digitalerp/utils/app_constant_new.dart';
import 'package:digitalerp/utils/app_network_image.dart';
import 'package:digitalerp/utils/my_app_bar_new.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Checkout / place-order screen.
///
/// Rebuilt to match the order-entry screens: a customer card with a Change
/// action, the item list, a bill-summary card, and a sticky bottom bar
/// carrying the grand total and the Place Order button. Discounting happens
/// per line on the order-entry screen, not here.
class YourOrderView extends StatelessWidget {
  const YourOrderView({super.key});

  static final NumberFormat _inr = NumberFormat('#,##,##0.00', 'en_IN');

  static String _money(num? value) => '₹${_inr.format(value ?? 0)}';

  /// 10.0 -> "10", 7.5 -> "7.5"
  static String _trimPct(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toString();

  /// "MRP ₹1,650.00   Net ₹200.00   Disc 10%", or null when the line was
  /// simply charged at MRP and there is nothing to explain.
  ///
  /// MRP always comes from [YourOrderController.bestMrpFor] so it matches the
  /// figure the Bill Summary totals against — printing the add-time value here
  /// showed "MRP ₹0.00" for items with no branch rate.
  static String? _breakdown(YourOrderController ctrl, GetCartListData item) {
    final charged = (item.itemrate ?? 0).toDouble();
    final mrp = ctrl.bestMrpFor(item);
    final exact = ctrl.pricingFor(item.productid, item.itemrate);

    final chargedAtMrp = (mrp - charged).abs() < 0.01;
    final noDiscount = exact == null || !exact.hasDiscount;
    if (chargedAtMrp && noDiscount) return null;

    final parts = <String>[];
    if (mrp > 0) parts.add('MRP ${_money(mrp)}');

    if (exact != null) {
      if ((exact.netRate - mrp).abs() > 0.01) {
        parts.add('Net ${_money(exact.netRate)}');
      }

      /// Shown the way it was entered — a flat discount reads as rupees, not
      /// as the percentage it happens to work out to.
      if (exact.hasDiscount) {
        parts.add(exact.discountType == OrderDiscountType.amount
            ? 'Disc ${_money(exact.discountAmount)}'
            : 'Disc ${_trimPct(exact.discountPercent)}%');
      }
    } else if (!chargedAtMrp) {
      /// No local record. The split between a net-rate override and a
      /// discount % is unrecoverable once both are folded into itemrate, so
      /// this says "Rate" rather than inventing a percentage.
      parts.add('Rate ${_money(charged)}');
    }

    return parts.isEmpty ? null : parts.join('   ');
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<YourOrderController>(
      init: YourOrderController(),
      builder: (ctrl) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              MyAppBar(
                title: 'Place Order',
                onBackTap: () => ctrl.backTap(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _sectionLabel('Customer'),
                    const SizedBox(height: 8),
                    _customerCard(ctrl),

                    /// No executive picker here by design. The original screen
                    /// had one but its call site was commented out, so
                    /// `selectedDropdownValue` stayed null and every order was
                    /// filed against the logged-in user's own account code.
                    /// That attribution is deliberate — leave it alone.
                    const SizedBox(height: 18),
                    _sectionLabel(
                        'Items (${ctrl.cartController.cartList.length})'),
                    const SizedBox(height: 8),
                    _items(ctrl),

                    /// Packaging is an order-level charge on both document
                    /// types (only its tax is PI-only), so it sits between the
                    /// goods and the bill rather than among the product rows.
                    const SizedBox(height: 18),
                    _sectionLabel('Packaging'),
                    const SizedBox(height: 8),
                    _packagingCard(ctrl),
                    const SizedBox(height: 18),
                    _sectionLabel('Bill Summary'),
                    const SizedBox(height: 8),
                    _billSummary(ctrl),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _bottomBar(context, ctrl),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: newTextPrimary,
        ),
      );

  // Customer

  Widget _customerCard(YourOrderController ctrl) {
    /// A Customer-type user always orders for their own account, so there is
    /// nothing to pick and no Change action.
    final locked = ctrl.isCustomer ?? false;
    final name = locked
        ? (ctrl.companyName ?? '')
        : (ctrl.selectCompany?.partyname ?? '');
    final hasCustomer = name.trim().isNotEmpty;

    if (!hasCustomer) {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ctrl.tapOnSearch(),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: newOrangeLightColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: newOrangeColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_add_alt_1_outlined,
                  size: 20, color: newOrangeColor),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Select a customer to place this order',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: newOrangeColor),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: newSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: newBorderColor),
      ),
      child: Row(
        children: [
          _initialsAvatar(name),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: newTextPrimary,
              ),
            ),
          ),
          if (!locked) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => ctrl.tapOnSearch(),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Change',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: newBlueColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _initialsAvatar(String name) {
    final trimmed = name.trim();
    final initials = trimmed.isEmpty
        ? '?'
        : trimmed
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w.isEmpty ? '' : w[0])
            .join()
            .toUpperCase();
    return Container(
      height: 42,
      width: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: newBlueColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: newBlueColor,
        ),
      ),
    );
  }

  // Items

  Widget _items(YourOrderController ctrl) {
    final cart = ctrl.cartController.cartList;
    if (cart.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: newSurfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: newBorderColor),
        ),
        child: const Text('Your cart is empty',
            style: TextStyle(color: newTextSecondary, fontSize: 13)),
      );
    }
    return Column(
      children: List.generate(cart.length, (i) => _itemRow(ctrl, cart[i])),
    );
  }

  Widget _itemRow(YourOrderController ctrl, GetCartListData item) {
    final qty = item.quantity ?? 0;
    final qtyText = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
    final hasBreakdown = _breakdown(ctrl, item) != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: newBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AppNetworkImage(
              image: item.productimage,
              height: 52,
              width: 52,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.productname ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: newTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),

                /// Spells out how the charged rate was reached. Prefers the
                /// exact Net Rate / discount split recorded when the line was
                /// added; otherwise falls back to the server's MRP so a
                /// repriced line still shows its basis.
                if (hasBreakdown) ...[
                  Text(
                    _breakdown(ctrl, item)!,
                    style: const TextStyle(
                        fontSize: 11, color: newTextSecondary),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  '$qtyText ${item.unit ?? ''}  ×  ${_money(item.itemrate)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        hasBreakdown ? FontWeight.w600 : FontWeight.w400,
                    color:
                        hasBreakdown ? newGreenColor : newTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money(item.total),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: newTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Bill summary

  Widget _billSummary(YourOrderController ctrl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: newSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: newBorderColor),
      ),
      child: Column(
        children: [
          /// No order-level Discount %/Cash Discount % here. Discounting is
          /// done per line on the order-entry screen and is already baked into
          /// each item's rate, so a second percentage at this level would
          /// double-discount the order.
          ///
          /// The MRP and discount rows show only when the lines were actually
          /// priced below list.
          if (ctrl.totals.isBelowMrp) ...[
            _amountLine('Total MRP', _money(ctrl.totals.mrpTotal)),
            const SizedBox(height: 12),
          ],

          /// The intermediate Net Amount is only worth a row when a discount
          /// is applied on top of a rate override — otherwise it just repeats
          /// the Amount below.
          if (ctrl.totals.hasRateOverride && ctrl.totals.hasDiscount) ...[
            _amountLine('Net Amount', _money(ctrl.totals.netTotal)),
            const SizedBox(height: 12),
          ],
          if (ctrl.totals.hasDiscount) ...[
            _amountLine(
              'Discount (${_trimPct(_round2(ctrl.totals.discountPercent))}%)',
              '− ${_money(ctrl.totals.discountAmount)}',
              valueColor: newGreenColor,
            ),
            const SizedBox(height: 12),
          ],

          /// On a PI the goods line is what tax is worked out on, so it is
          /// labelled as such; an Estimate keeps the plain "Amount" it had.
          _amountLine(
            ctrl.orderType.chargesGst ? 'Taxable Amount' : 'Amount',
            _money(ctrl.cartSubtotal),
          ),
          if (ctrl.cartShipping > 0) ...[
            const SizedBox(height: 12),
            _amountLine('Shipping', _money(ctrl.cartShipping)),
          ],

          /// Product tax is PI only — an Estimate is quoted tax-free.
          if (ctrl.orderType.chargesGst) ...[
            const SizedBox(height: 12),
            _amountLine(
              'Product GST',
              ctrl.isLoadingGst ? '…' : _money(ctrl.bill.productGst),
            ),
            if (ctrl.untaxedLineCount > 0) ...[
              const SizedBox(height: 6),
              _note(
                'GST rate unavailable for ${ctrl.untaxedLineCount} item(s) — '
                'those lines are untaxed here.',
              ),
            ],
          ],

          /// Packaging is charged on both types; its 18% only on a PI.
          if (ctrl.bill.packagingBase > 0) ...[
            const SizedBox(height: 12),
            _amountLine('Packaging Charges', _money(ctrl.bill.packagingBase)),
            if (ctrl.orderType.chargesGst) ...[
              const SizedBox(height: 12),
              _amountLine(
                'Packaging GST @ ${_trimPct(PackagingCharge.gstPercent)}%',
                _money(ctrl.bill.packagingGst),
              ),
            ],
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: newBorderColor),
          ),
          _amountLine(
            ctrl.orderType.chargesGst ? 'Final Total' : 'Grand Total',
            _money(ctrl.bill.finalTotal),
            emphasised: true,
          ),
        ],
      ),
    );
  }

  /// Packaging is a PI-only, order-level charge, so it gets its own card above
  /// the bill rather than sitting among the product rows. Only the base amount
  /// is typed — its 18% tax and the packaging total are derived and read-only.
  Widget _packagingCard(YourOrderController ctrl) {
    final packaging = PackagingCharge(ctrl.packagingCharge);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: newSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: newBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 15, color: newTextSecondary),
              const SizedBox(width: 6),
              const Text(
                'Packaging Charges',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: newTextPrimary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 120,
                height: 38,
                child: TextField(
                  controller: ctrl.packagingController,
                  onChanged: ctrl.onPackagingTyped,
                  textAlign: TextAlign.end,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: newTextPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '0',
                    hintStyle:
                        const TextStyle(color: newTextHint, fontSize: 14),
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(
                        color: newTextSecondary, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: newBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: newBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: newBlueColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
          /// The derived rows only make sense when there is tax to add — on
          /// an Estimate the typed amount IS the packaging total.
          if (packaging.isCharged && ctrl.orderType.chargesGst) ...[
            const SizedBox(height: 12),
            _amountLine(
              'Packaging GST @ ${_trimPct(PackagingCharge.gstPercent)}%',
              _money(packaging.gstAmount),
            ),
            const SizedBox(height: 10),
            _amountLine(
              'Total Packaging',
              _money(packaging.total),
              emphasised: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _note(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 13, color: newTextHint),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 11, height: 1.3, color: newTextSecondary),
          ),
        ),
      ],
    );
  }

  Widget _amountLine(String name, String amount,
      {bool emphasised = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: emphasised ? 14 : 13,
            fontWeight: emphasised ? FontWeight.w800 : FontWeight.w500,
            color: emphasised ? newTextPrimary : newTextSecondary,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: emphasised ? 16 : 13,
            fontWeight: emphasised ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ??
                (emphasised ? newBlueColor : newTextPrimary),
          ),
        ),
      ],
    );
  }

  /// 87.878... -> 87.88
  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  // Bottom bar

  Widget _bottomBar(BuildContext context, YourOrderController ctrl) {
    final cartEmpty = ctrl.cartController.cartList.isEmpty;
    final needsCustomer =
        !(ctrl.isCustomer ?? false) && ctrl.selectCompany?.partyid == null;
    final canPlace = !cartEmpty && !needsCustomer && !ctrl.isBusy;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: newBorderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ctrl.orderType.chargesGst ? 'Final Total' : 'Grand Total',
                  style: const TextStyle(
                      fontSize: 11, color: newTextSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  /// Must match the Bill Summary's bottom line, tax and
                  /// packaging included.
                  _money(ctrl.bill.finalTotal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: newBlueColor,
                  ),
                ),
                if (needsCustomer && !cartEmpty)
                  const Text(
                    'Select a customer to continue',
                    style: TextStyle(fontSize: 10.5, color: newOrangeColor),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: canPlace ? () => ctrl.tapOnPlaceOrder() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: newBlueColor,
                disabledBackgroundColor: newBorderColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 26),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: ctrl.isBusy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
