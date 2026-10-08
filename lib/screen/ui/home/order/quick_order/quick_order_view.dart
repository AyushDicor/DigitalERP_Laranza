import 'package:digitalerp/response/subcategory_brand_response.dart';
import 'package:digitalerp/screen/ui/home/order/quick_order/quick_order_controller.dart';
import 'package:digitalerp/utils/order_line_pricing.dart';
import 'package:digitalerp/utils/picker_sheet.dart';
import 'package:digitalerp/utils/app_constant_new.dart';
import 'package:digitalerp/utils/app_network_image.dart';
import 'package:digitalerp/utils/my_app_bar_new.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Single-screen order entry.
///
/// Company and Brand sit in pickers at the top, categories are optional filter
/// chips, and every product row carries its own quantity stepper. One
/// "Add All to Cart" button pushes the whole basket, after which checkout runs
/// through the existing Cart -> Your Order screens unchanged.
class QuickOrderView extends StatelessWidget {
  const QuickOrderView({super.key});

  /// Explicit lakh-grouping pattern (1,00,000.00) rather than
  /// `NumberFormat.currency`, matching how the rest of the app formats money
  /// and not depending on en_IN locale data being loaded.
  static final NumberFormat _inr = NumberFormat('#,##,##0.00', 'en_IN');

  static String _money(num? value) => '₹${_inr.format(value ?? 0)}';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<QuickOrderController>(
      init: QuickOrderController(),
      builder: (ctrl) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              MyAppBar(
                title: 'New Order',
                onBackTap: () => ctrl.backTap(),
                showCartIcon: true,
                onCartTap: () => ctrl.tapOnCart(),
              ),
              _orderTypeSelector(ctrl),
              _selectors(ctrl),
              /// No category chips: the brand's whole catalogue is listed and
              /// the search box below filters it. The chips were a second,
              /// competing filter that pushed the products further down.
              _searchBar(ctrl),
              const SizedBox(height: 8),
              Expanded(child: _body(ctrl)),
            ],
          ),
        ),
        bottomNavigationBar: _bottomBar(context, ctrl),
      ),
    );
  }

  // Order Type

  /// Sits above the Company/Brand card because it decides what the rest of the
  /// screen lets the user edit: an Estimate opens the MRP box on every line, a
  /// PI keeps the master rate and adds tax at checkout.
  ///
  /// A two-option segmented control rather than a dropdown sheet — with only
  /// Estimate and PI to choose from, both are visible without a tap and the
  /// current one reads at a glance.
  Widget _orderTypeSelector(QuickOrderController ctrl) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: newSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: newBorderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined,
              size: 14, color: newTextSecondary),
          const SizedBox(width: 5),
          const Text(
            'Order Type',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: newTextSecondary,
            ),
          ),
          const Spacer(),
          for (final type in OrderType.values) ...[
            if (type != OrderType.values.first) const SizedBox(width: 8),
            _orderTypeChip(
              label: type.label,
              selected: ctrl.orderType == type,
              onTap: () => ctrl.onPickOrderType(type),
            ),
          ],
        ],
      ),
    );
  }

  Widget _orderTypeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? newBlueColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? newBlueColor : newBorderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : newTextSecondary,
          ),
        ),
      ),
    );
  }

  // Company + Brand pickers

  Widget _selectors(QuickOrderController ctrl) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: newSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: newBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _pickerField(
              label: 'Company',
              value: ctrl.selectedParty?.partyname,
              hint: 'Select company',
              icon: Icons.storefront_outlined,
              busy: ctrl.isPartyLoading || ctrl.isValidatingParty,

              /// A Customer-type user can only order for their own account,
              /// so the field is shown filled but not tappable.
              enabled: !ctrl.isCustomerUser,
              onTap: () async {
                final picked = await showPickerSheet(
                  title: 'Select Company',
                  items: ctrl.partyList,
                  labelOf: (p) => p.partyname ?? '',
                  isSelected: (p) => p.partyid == ctrl.selectedParty?.partyid,
                  searchHint: 'Search company',
                  emptyText: 'No companies found',
                );
                if (picked != null) ctrl.onPickParty(picked);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _pickerField(
              label: 'Brand',
              value: ctrl.selectedBrand?.brandname,
              hint: 'Select brand',
              icon: Icons.sell_outlined,
              busy: ctrl.isBrandLoading,
              enabled: true,
              onTap: () async {
                final picked = await showPickerSheet(
                  title: 'Select Brand',
                  items: ctrl.brandList,
                  labelOf: (b) => b.brandname ?? '',
                  isSelected: (b) => b.brandid == ctrl.selectedBrand?.brandid,
                  searchHint: 'Search brand',
                  emptyText: 'No brands found',
                );
                if (picked != null) ctrl.onPickBrand(picked);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerField({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required bool busy,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return GestureDetector(
      onTap: enabled && !busy ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? newBlueColor.withValues(alpha: 0.4) : newBorderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: newTextSecondary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: newTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: busy
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: newBlueColor),
                        )
                      : Text(
                          hasValue ? value : hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                hasValue ? FontWeight.w700 : FontWeight.w500,
                            color: hasValue ? newTextPrimary : newTextHint,
                          ),
                        ),
                ),
                if (enabled)
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: newTextSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Search

  Widget _searchBar(QuickOrderController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextField(
        controller: ctrl.searchController,
        onChanged: ctrl.searchProduct,
        style: const TextStyle(fontSize: 14, color: newTextPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search item name or code or serial number',
          hintStyle: const TextStyle(color: newTextHint, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search, color: newTextSecondary, size: 20),
          filled: true,
          fillColor: newSurfaceColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: newBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: newBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: newBlueColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  // Product list

  Widget _body(QuickOrderController ctrl) {
    if (ctrl.selectedBrand == null) {
      return _placeholder(
        Icons.sell_outlined,
        'Select a brand to load its products',
      );
    }
    if (ctrl.isListLoading) {
      return const Center(
          child: CircularProgressIndicator(color: newBlueColor));
    }
    if (ctrl.productList.isEmpty) {
      return _placeholder(Icons.inventory_2_outlined, 'No products found');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: ctrl.productList.length,
      itemBuilder: (_, i) => _productRow(ctrl, ctrl.productList[i]),
    );
  }

  Widget _placeholder(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: newTextHint),
          const SizedBox(height: 10),
          Text(text,
              style: const TextStyle(color: newTextSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  /// Each row repaints on its own id so typing a quantity does not rebuild —
  /// and therefore does not steal focus from — the rest of the list.
  Widget _productRow(QuickOrderController ctrl, ProductDataList item) {
    return GetBuilder<QuickOrderController>(
      id: QuickOrderController.rowId(item.itemid),
      builder: (c) => _productRowBody(c, item),
    );
  }

  Widget _productRowBody(QuickOrderController ctrl, ProductDataList item) {
    final qty = ctrl.qtyOf(item.itemid);
    final isPicked = qty > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isPicked ? newBlueColor.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPicked ? newBlueColor.withValues(alpha: 0.45) : newBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AppNetworkImage(
                  image: item.itemimage,
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
                      item.itemname ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: newTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Code: ${item.itemcode ?? '-'}   |   ${item.unit ?? ''}',
                      style: const TextStyle(
                          fontSize: 11, color: newTextSecondary),
                    ),
                    const SizedBox(height: 3),
                    _rateSummary(ctrl, item, qty, isPicked),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _qtyStepper(ctrl, item, qty),
            ],
          ),
          const SizedBox(height: 10),
          _pricingRow(ctrl, item),
        ],
      ),
    );
  }

  /// MRP is shown exactly as the server sent it and never changes — the
  /// effective rate is added beside it only when a Net Rate or discount has
  /// been entered.
  Widget _rateSummary(QuickOrderController ctrl, ProductDataList item,
      double qty, bool isPicked) {
    final mrp = ctrl.mrpOf(item);
    final finalRate = ctrl.finalRateOf(item);
    final changed = (finalRate - mrp).abs() > 0.001;

    return Row(
      children: [
        Text(
          'MRP ${_money(mrp)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: changed ? FontWeight.w500 : FontWeight.w700,
            color: changed ? newTextSecondary : newBlueColor,
          ),
        ),
        if (changed) ...[
          const SizedBox(width: 6),
          Text(
            '→ ${_money(finalRate)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: newBlueColor,
            ),
          ),
        ],
        if (isPicked) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '= ${_money(finalRate * qty)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: newGreenColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// The per-line pricing controls, which differ by document type.
  ///
  /// **Estimate** — MRP and Taxable Rate, nothing else. The gap between the two
  /// is the discount; it is derived when the line is added to the cart and
  /// posted, but deliberately never shown here.
  ///
  /// **PI** — the item-master rate is authoritative, so the MRP box is hidden
  /// rather than disabled (nothing to tap) and the line is priced EITHER with
  /// a Net Rate OR with a discount off the MRP. Filling one locks the other —
  /// see [QuickOrderController.netRateLocked] — because both at once would
  /// fight over the same rate.
  Widget _pricingRow(QuickOrderController ctrl, ProductDataList item) {
    final editableMrp = ctrl.orderType.allowsMrpEdit;
    final showsDiscount = ctrl.orderType.showsDiscountFields;
    final discountType = ctrl.discountTypeOf(item.itemid);
    final byAmount = discountType == OrderDiscountType.amount;

    /// Only meaningful where both controls exist; on an Estimate there are no
    /// discount boxes, so the rate box is never locked.
    final rateLocked = showsDiscount && ctrl.netRateLocked(item.itemid);
    final discLocked = ctrl.discountLocked(item.itemid);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (editableMrp) ...[
              Expanded(
                child: _pricingField(
                  label: 'MRP',

                  /// Hints the item-master rate, which is what an empty box
                  /// prices at.
                  hint: _money(ctrl.masterRateOf(item)),
                  controller: ctrl.mrpCtrl(item),
                  onChanged: (v) => ctrl.onMrpTyped(item, v),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _pricingField(
                label: ctrl.orderType.rateFieldLabel,

                /// Always hints '0', never the MRP — the box is for a rate the
                /// user chooses to override with, and echoing the MRP made an
                /// untouched line look as though it had been priced.
                /// Left empty, the line still prices at MRP.
                hint: '0',
                controller: ctrl.rateCtrl(item),
                onChanged: (v) => ctrl.onNetRateTyped(item, v),
                enabled: !rateLocked,
              ),
            ),
          ],
        ),
        if (showsDiscount) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _discountTypePicker(ctrl, item, discountType,
                    enabled: !discLocked),
              ),
              const SizedBox(width: 10),

              /// One field, swapped by type — the other value is cleared by
              /// the controller, so the two discounts can never both be live.
              Expanded(
                child: byAmount
                    ? _pricingField(
                        key: ValueKey('disc_amt_${item.itemid}'),
                        label: 'Discount Amount',
                        prefix: '₹ ',
                        hint: '0',
                        controller: ctrl.discAmtCtrl(item),
                        onChanged: (v) => ctrl.onDiscountAmountTyped(item, v),
                        enabled: !discLocked,
                      )
                    : _pricingField(
                        key: ValueKey('disc_pct_${item.itemid}'),
                        label: 'Discount %',
                        suffix: '%',
                        hint: '0',
                        controller: ctrl.discCtrl(item),
                        onChanged: (v) => ctrl.onDiscountTyped(item, v),
                        enabled: !discLocked,
                      ),
              ),
            ],
          ),

          /// Says why a box is greyed, so a locked field never reads as a
          /// broken one. Only one of the two can be true.
          if (rateLocked || discLocked) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 12, color: newTextHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    rateLocked
                        ? 'Clear the discount to type a Net Rate'
                        : 'Clear the Net Rate to use a discount',
                    style: const TextStyle(
                        fontSize: 10.5, color: newTextSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  /// Sits immediately left of the discount box so the two read as one control.
  Widget _discountTypePicker(QuickOrderController ctrl, ProductDataList item,
      OrderDiscountType selected, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Discount Type',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: enabled ? newTextSecondary : newTextHint,
          ),
        ),
        const SizedBox(height: 4),
        PopupMenuButton<OrderDiscountType>(
          initialValue: selected,
          tooltip: 'Discount type',
          position: PopupMenuPosition.under,
          enabled: enabled,
          onSelected: (type) => ctrl.onPickDiscountType(item, type),
          itemBuilder: (_) => [
            for (final type in OrderDiscountType.values)
              PopupMenuItem(
                value: type,
                height: 40,
                child: Text(
                  type.label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
          ],
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : newSurfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: newBorderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected.shortLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: enabled ? newTextPrimary : newTextHint,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: newTextSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// [enabled] false greys the box and stops input — used when the other half
  /// of the Net Rate / Discount pair has been filled in.
  Widget _pricingField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? suffix,
    String? prefix,
    String? hint,
    Key? key,
    bool enabled = true,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: enabled ? newTextSecondary : newTextHint,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: enabled ? newTextPrimary : newTextHint,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(color: newTextHint, fontSize: 13),
              prefixText: prefix,
              prefixStyle:
                  const TextStyle(color: newTextSecondary, fontSize: 12),
              suffixText: suffix,
              suffixStyle:
                  const TextStyle(color: newTextSecondary, fontSize: 12),
              filled: true,

              /// Greyed while locked, so it reads as unavailable rather than
              /// merely empty.
              fillColor: enabled ? Colors.white : newSurfaceColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                borderSide: const BorderSide(color: newBlueColor, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: newBorderColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _qtyStepper(
      QuickOrderController ctrl, ProductDataList item, double qty) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: newBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(Icons.remove_rounded, () => ctrl.decreaseQty(item),
              enabled: qty > 0),
          SizedBox(
            width: 44,
            child: TextField(
              /// Long-lived controller owned by the GetX controller, keyed by
              /// item id — see [QuickOrderController.qtyCtrl].
              key: ValueKey('qty_${item.itemid}'),
              controller: ctrl.qtyCtrl(item),
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
              ],
              onChanged: (v) => ctrl.onQtyTyped(item, v),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: newTextPrimary,
              ),
              decoration: const InputDecoration(
                isDense: true,
                hintText: '0',
                hintStyle: TextStyle(color: newTextHint, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          _stepBtn(Icons.add_rounded, () => ctrl.increaseQty(item),
              enabled: true),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, {required bool enabled}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 30,
        height: 38,
        alignment: Alignment.center,
        child: Icon(icon,
            size: 17, color: enabled ? newBlueColor : newTextHint),
      ),
    );
  }

  // Bottom action bar

  Widget _bottomBar(BuildContext context, QuickOrderController ctrl) {
    return GetBuilder<QuickOrderController>(
      id: QuickOrderController.bottomBarId,
      builder: (c) => _bottomBarBody(context, c),
    );
  }

  Widget _bottomBarBody(BuildContext context, QuickOrderController ctrl) {
    final count = ctrl.pickedCount;
    final hasPicks = count > 0;
    final needsCompany = ctrl.selectedParty?.partyid == null;
    final canAdd = hasPicks && !needsCompany && !ctrl.isAddingToCart;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: newBorderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: hasPicks ? () => _showPickedSheet(ctrl) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        hasPicks ? '$count item(s)' : 'No items yet',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: newTextPrimary,
                        ),
                      ),
                      if (hasPicks) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_up_rounded,
                            size: 18, color: newBlueColor),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    !hasPicks
                        ? 'Enter quantities below'
                        : needsCompany
                            ? 'Select a company to continue'
                            : _money(ctrl.pickedTotal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: hasPicks && !needsCompany ? 15 : 11,
                      fontWeight: hasPicks && !needsCompany
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: needsCompany && hasPicks
                          ? newOrangeColor
                          : hasPicks
                              ? newBlueColor
                              : newTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: canAdd ? ctrl.addAllToCart : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: newBlueColor,
                disabledBackgroundColor: newBorderColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: ctrl.isAddingToCart
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 15,
                          width: 15,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Adding ${ctrl.addedSoFar}/$count',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Add All to Cart',
                      style: TextStyle(
                        fontSize: 14,
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

  /// Review sheet for everything staged so far. Because quantities survive
  /// brand and category switches, this is where a user confirms what is about
  /// to be pushed — including rows that are no longer visible in the list.
  void _showPickedSheet(QuickOrderController ctrl) {
    Get.bottomSheet(
      GetBuilder<QuickOrderController>(
        builder: (c) => Container(
          constraints: BoxConstraints(
              maxHeight: Get.height * 0.7),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: newBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Selected items (${c.pickedCount})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: newTextPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: c.picked.isEmpty
                          ? null
                          : () {
                              c.clearPicked();
                              Get.back();
                            },
                      child: const Text('Clear all',
                          style: TextStyle(color: newRedColor, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: c.picked.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text('Nothing selected',
                            style: TextStyle(
                                color: newTextSecondary, fontSize: 14)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: c.picked.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 16, thickness: 1, color: newBorderColor),
                        itemBuilder: (_, i) {
                          final entry = c.picked.values.elementAt(i);
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      entry.item.itemname ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: newTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${entry.brandName} · '
                                      '${entry.qty % 1 == 0 ? entry.qty.toInt() : entry.qty} '
                                      '${entry.item.unit ?? ''} · '
                                      '${_money(entry.lineTotal)}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: newTextSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    c.removePicked(entry.item.itemid ?? -1),
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 20, color: newRedColor),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
