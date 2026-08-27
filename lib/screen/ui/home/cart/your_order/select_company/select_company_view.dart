import 'package:digitalerp/response/get_executive_dropdown_response.dart';
import 'package:digitalerp/response/party_dropdown_list_response.dart';
import 'package:digitalerp/screen/ui/home/cart/your_order/select_company/select_company_controller.dart';
import 'package:digitalerp/utils/app_constant_new.dart';
import 'package:digitalerp/utils/my_app_bar_new.dart';
import 'package:digitalerp/utils/picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Customer picker used at checkout.
///
/// Rebuilt to match the order-entry screens: a plain white scaffold, one
/// search field, and a flat list of rows. Replaces the old gradient
/// stacked-avatar cards, which rendered a party id as an image URL and so
/// always showed a broken placeholder.
class SelectCompanyView extends StatelessWidget {
  const SelectCompanyView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SelectCompanyController>(
      init: SelectCompanyController(),
      builder: (ctrl) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              MyAppBar(
                title: 'Select Customer',
                onBackTap: () => ctrl.backTap(),
              ),
              if (ctrl.isManager) _executivePicker(ctrl),
              _searchBar(ctrl),
              const SizedBox(height: 6),
              _resultCount(ctrl),
              Expanded(child: _list(ctrl)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => ctrl.tapOnAdd(),
          backgroundColor: newBlueColor,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          label: const Text(
            'Add Customer',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _executivePicker(SelectCompanyController ctrl) {
    final executives =
        ctrl.yourOrderController.orderController.executiveList;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: GestureDetector(
        onTap: executives.isEmpty
            ? null
            : () async {
                final picked = await showPickerSheet<ExecutiveDropdownData>(
                  title: 'Select Executive',
                  items: executives,
                  labelOf: (e) => e.executiveName?.toString() ?? '',
                  isSelected: (e) =>
                      e.executiveId == ctrl.selectedDropdownValue?.executiveId,
                  searchHint: 'Search executive',
                  emptyText: 'No executives found',
                );
                if (picked != null) ctrl.setDropdownValue(picked);
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: newSurfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: newBorderColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.badge_outlined,
                  size: 18, color: newTextSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ctrl.selectedDropdownValue?.executiveName?.toString() ??
                      'Select executive',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: ctrl.selectedDropdownValue == null
                        ? FontWeight.w500
                        : FontWeight.w700,
                    color: ctrl.selectedDropdownValue == null
                        ? newTextHint
                        : newTextPrimary,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: newTextSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar(SelectCompanyController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextField(
        controller: ctrl.searchController,
        focusNode: ctrl.searchFocus,
        onChanged: ctrl.searchCompany,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14, color: newTextPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search customer',
          hintStyle: const TextStyle(color: newTextHint, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search, color: newTextSecondary, size: 20),
          suffixIcon: ctrl.searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: newTextSecondary),
                  onPressed: () {
                    ctrl.searchController.clear();
                    ctrl.searchCompany('');
                  },
                ),
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

  Widget _resultCount(SelectCompanyController ctrl) {
    if (ctrl.isListLoading || ctrl.filteredList.isEmpty) {
      return const SizedBox(height: 6);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${ctrl.filteredList.length} customer(s)',
          style: const TextStyle(fontSize: 11, color: newTextSecondary),
        ),
      ),
    );
  }

  Widget _list(SelectCompanyController ctrl) {
    if (ctrl.isListLoading) {
      return const Center(
          child: CircularProgressIndicator(color: newBlueColor));
    }
    if (ctrl.filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search_outlined,
                size: 44, color: newTextHint),
            const SizedBox(height: 10),
            Text(
              ctrl.companyList.isEmpty
                  ? 'No customers available'
                  : 'No customer matches your search',
              style: const TextStyle(color: newTextSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      itemCount: ctrl.filteredList.length,
      itemBuilder: (_, i) => _customerRow(ctrl, i),
    );
  }

  Widget _customerRow(SelectCompanyController ctrl, int index) {
    final item = ctrl.filteredList[index];
    final selected =
        item.partyid == ctrl.yourOrderController.selectCompany?.partyid;
    final validating = ctrl.validatingPartyId == item.partyid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: validating ? null : () => ctrl.tapOnCard(index),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                selected ? newBlueColor.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? newBlueColor.withValues(alpha: 0.5)
                  : newBorderColor,
            ),
          ),
          child: Row(
            children: [
              _avatar(item),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.partyname ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? newBlueColor : newTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (validating)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: newBlueColor),
                )
              else if (selected)
                const Icon(Icons.check_circle_rounded,
                    size: 20, color: newBlueColor)
              else
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: newTextHint),
            ],
          ),
        ),
      ),
    );
  }

  /// Initials avatar. The party list carries no image, so the old code passed
  /// the party id where an image URL was expected and always fell back to a
  /// placeholder.
  Widget _avatar(PartyDropdownData item) {
    final name = (item.partyname ?? '').trim();
    final initials = name.isEmpty
        ? '?'
        : name
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
}
