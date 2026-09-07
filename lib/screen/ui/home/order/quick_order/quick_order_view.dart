import 'package:digitalerp/response/subcategory_brand_response.dart';
import 'package:digitalerp/screen/ui/home/order/quick_order/quick_order_controller.dart';
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
              _selectors(ctrl),
              if (ctrl.categoryList.isNotEmpty) _categoryChips(ctrl),
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

  // Category filter chips

  Widget _categoryChips(QuickOrderController ctrl) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip('All', ctrl.selectedCategoryId == 0,
              () => ctrl.onPickCategory(0)),
          ...ctrl.categoryList.map(
            (c) => _chip(
              c.categoryname ?? '',
              ctrl.selectedCategoryId == c.categoryid,
              () => ctrl.onPickCategory(c.categoryid ?? 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? newBlueColor : newSurfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: selected ? newBlueColor : newBorderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : newTextSecondary,
            ),
          ),
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
          hintText: 'Search item name or code',
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

  /// Net Rate and Discount % for this line.
  ///
  /// Net Rate replaces the item-master rate, then Discount % comes off the Net
  /// Rate — the two are independent, so a line can be repriced, discounted, or
  /// both.
  Widget _pricingRow(QuickOrderController ctrl, ProductDataList item) {
    return Row(
      children: [
        Expanded(
          child: _pricingField(
            label: 'Net Rate',

            /// Always hints '0', never the MRP — the box is for a rate the
            /// user chooses to override with, and echoing the MRP made an
            /// untouched line look as though it had been priced.
            /// Left empty, the line still prices at MRP.
            hint: '0',
            controller: ctrl.rateCtrl(item),
            onChanged: (v) => ctrl.onNetRateTyped(item, v),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _pricingField(
            label: 'Discount %',
            suffix: '%',
            hint: '0',
            controller: ctrl.discCtrl(item),
            onChanged: (v) => ctrl.onDiscountTyped(item, v),
          ),
        ),
      ],
    );
  }

  Widget _pricingField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? suffix,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: newTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: newTextPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(color: newTextHint, fontSize: 13),
              suffixText: suffix,
              suffixStyle:
                  const TextStyle(color: newTextSecondary, fontSize: 12),
              filled: true,
              fillColor: Colors.white,
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
