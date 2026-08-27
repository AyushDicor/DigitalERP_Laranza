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
/// action, the item list, a bill-summary card holding both discount inputs,
/// and a sticky bottom bar carrying the grand total and the Place Order
/// button.
class YourOrderView extends StatelessWidget {
  const YourOrderView({super.key});

  static final NumberFormat _inr = NumberFormat('#,##,##0.00', 'en_IN');

  static String _money(num? value) => '₹${_inr.format(value ?? 0)}';

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
      children: List.generate(cart.length, (i) => _itemRow(cart[i])),
    );
  }

  Widget _itemRow(GetCartListData item) {
    final qty = item.quantity ?? 0;
    final qtyText = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
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
                Text(
                  '$qtyText ${item.unit ?? ''}  ×  ${_money(item.itemrate)}',
                  style:
                      const TextStyle(fontSize: 11.5, color: newTextSecondary),
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
          _amountLine('Amount', _money(ctrl.cartSubtotal)),
          const SizedBox(height: 12),
          _percentLine(
            label: 'Discount %',
            controller: ctrl.discountController,
            focusNode: ctrl.discountFocus,
            onChanged: ctrl.discountCalculate,
          ),
          const SizedBox(height: 12),
          _amountLine('Subtotal', _money(ctrl.subTotal)),
          const SizedBox(height: 12),
          _percentLine(
            label: 'Cash Discount %',
            controller: ctrl.cashDiscountController,
            focusNode: ctrl.cashDiscountFocus,
            onChanged: ctrl.cashDiscountCalculate,
          ),
          if (ctrl.cartShipping > 0) ...[
            const SizedBox(height: 12),
            _amountLine('Shipping', _money(ctrl.cartShipping)),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: newBorderColor),
          ),
          _amountLine(
            'Grand Total',
            _money(ctrl.grandTotal),
            emphasised: true,
          ),
        ],
      ),
    );
  }

  Widget _amountLine(String name, String amount, {bool emphasised = false}) {
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
            color: emphasised ? newBlueColor : newTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _percentLine({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: newTextSecondary,
          ),
        ),
        SizedBox(
          width: 78,
          height: 36,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              hintStyle: const TextStyle(color: newTextHint, fontSize: 14),
              suffixText: '%',
              suffixStyle:
                  const TextStyle(color: newTextSecondary, fontSize: 12),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                const Text(
                  'Grand Total',
                  style: TextStyle(fontSize: 11, color: newTextSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  _money(ctrl.grandTotal),
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
