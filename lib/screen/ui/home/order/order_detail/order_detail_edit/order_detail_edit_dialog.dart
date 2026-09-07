import 'package:digitalerp/screen/ui/home/order/order_detail/order_detail_controller.dart';
import 'package:digitalerp/utils/app_constant_new.dart';
import 'package:digitalerp/utils/picker_sheet.dart';
import 'package:digitalerp/utils/show_message.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Order status editor.
///
/// Rebuilt to match the rest of the order flow: a compact white card instead
/// of a full-screen gradient wash, neutral labels instead of red-on-white, and
/// the shared picker sheet instead of `dropdown_button2`.
class OrderDetailEditDialog extends StatelessWidget {
  OrderDetailEditDialog({super.key});

  final OrderDetailController orderDetailController =
      Get.find<OrderDetailController>();

  static final NumberFormat _inr = NumberFormat('#,##,##0.00', 'en_IN');

  static String _money(dynamic value) {
    final parsed = value is num ? value : double.tryParse('$value');
    return '₹${_inr.format(parsed ?? 0)}';
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderDetailController>(
      assignId: true,
      builder: (ctrl) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: _card(context, ctrl),
      ),
    );
  }

  Widget _card(BuildContext context, OrderDetailController ctrl) {
    final party = ctrl.partyBalanceDetailData;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Edit Status',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: newTextPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  height: 32,
                  width: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: newSurfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: newTextSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _field('Customer', party?.clientname ?? '—', emphasise: true),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _field('Credit Limit', _money(party?.creditlimit)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    _field('Previous Balance', _money(party?.previousbalance)),
              ),
            ],
          ),

          /// The remark row is dropped entirely when empty rather than
          /// printing "N/A" under a heading.
          if ((party?.remark ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _field('Remark', party!.remark!),
          ],

          const SizedBox(height: 18),
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: newTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _statusPicker(ctrl),
          const SizedBox(height: 20),
          _doneButton(ctrl),
        ],
      ),
    );
  }

  Widget _field(String label, String value, {bool emphasise = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: newTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasise ? 15 : 14,
            fontWeight: emphasise ? FontWeight.w800 : FontWeight.w700,
            color: newTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _statusPicker(OrderDetailController ctrl) {
    final selected = ctrl.selectedStatusValue ?? '';
    final hasSelection = selected.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        final picked = await showPickerSheet<String>(
          title: 'Select Status',
          items: ctrl.statusList,
          labelOf: (s) => s,
          isSelected: (s) => s == ctrl.selectedStatusValue,
          searchHint: 'Search status',
          emptyText: 'No statuses',
        );
        if (picked != null) ctrl.setSelectedStatusValue(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: newSurfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasSelection
                ? _statusColor(selected).withValues(alpha: 0.5)
                : newBorderColor,
          ),
        ),
        child: Row(
          children: [
            if (hasSelection) ...[
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  color: _statusColor(selected),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                hasSelection ? selected : 'Select status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      hasSelection ? FontWeight.w700 : FontWeight.w500,
                  color: hasSelection ? newTextPrimary : newTextHint,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: newTextSecondary),
          ],
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return newGreenColor;
      case 'rejected':
        return newRedColor;
      default:
        return newOrangeColor;
    }
  }

  Widget _doneButton(OrderDetailController ctrl) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          if (ctrl.selectedStatusValue?.isNotEmpty ?? false) {
            ctrl.updateOrderStatusApi(ctrl.selectedStatusValue ?? '');
            Get.back();
          } else {
            ShowMessage.showSnackBar(
                'Please check', 'Select a status first');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: newBlueColor,
          disabledBackgroundColor: newBorderColor,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'Update Status',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
