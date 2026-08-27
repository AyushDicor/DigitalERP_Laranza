import 'dart:convert';

import 'package:digitalerp/app_routes/app_routes.dart';
import 'package:digitalerp/response/customer_detail_response.dart';
import 'package:digitalerp/response/get_executive_dropdown_response.dart';
import 'package:digitalerp/response/party_dropdown_list_response.dart';
import 'package:digitalerp/response/visit_plan_detail_data_response.dart';
import 'package:digitalerp/screen/base/base_controller.dart';
import 'package:digitalerp/screen/ui/home/cart/cart_controller.dart';
import 'package:digitalerp/screen/ui/home/home_controller.dart';
import 'package:digitalerp/screen/ui/home/order/order_controller.dart';
import 'package:digitalerp/services/api_service/request_keys.dart';
import 'package:digitalerp/utils/app_constant.dart';
import 'package:digitalerp/utils/shared_pre.dart';
import 'package:digitalerp/utils/show_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class YourOrderController extends AppBaseController {
  final CartController cartController = Get.find<CartController>();
  final HomeController homeController = Get.find<HomeController>();
  final OrderController orderController = Get.find<OrderController>();

  final TextEditingController searchController = TextEditingController();

  final FocusNode searchFocus = FocusNode();

  ExecutiveDropdownData? selectedDropdownValue;
  final discountController = TextEditingController(text: 0.toString());
  final discountFocus = FocusNode();

  final cashDiscountController = TextEditingController(text: 0.toString());
  final cashDiscountFocus = FocusNode();

  PartyDropdownData? selectCompany;
  List <PartyDropdownData> partyList=[];
  bool? isCustomer;
  String? companyName;
  String? partyId;

  double subTotal = 0.0;
  double grandTotal = 0.0;

  /// Seeded to '0' so they match what the two text fields actually display —
  /// previously these stayed empty until edited and an untouched order posted
  /// an empty string as its discount percent.
  String discountedValue = '0';
  String cashDiscountedValue = '0';
  String? customer;
  var customer2;
  CustomerListData? customerdecodedList;

  @override
  void onInit() async {
    // TODO: implement onInit
    getPartyDropdownList();
    isCustomer = homeController.currentUserData?.usertype.toString() == 'Customer';
    companyName = homeController.currentUserData?.name.toString();

    /// Seed the totals from the cart so the summary and the Place Order button
    /// show real figures before the user touches either discount field.
    recalculate();

    super.onInit();
  }



  void setDropdownValue(ExecutiveDropdownData value) {
    selectedDropdownValue = value;
    update();
  }

  /// Cart-level amount, repeated on every cart row by the API. Guarded because
  /// the cart can legitimately be empty (every row deleted) and `.first` on an
  /// empty list throws.
  double get cartSubtotal {
    if (cartController.cartList.isEmpty) return 0;
    return (cartController.cartList.first.subtotal ?? 0).toDouble();
  }

  double get cartShipping {
    if (cartController.cartList.isEmpty) return 0;
    return (cartController.cartList.first.shippingamount ?? 0).toDouble();
  }

  void discountCalculate(String value) {
    discountedValue = value;
    recalculate();
  }

  void cashDiscountCalculate(String value) {
    cashDiscountedValue = value;
    recalculate();
  }

  /// Recomputes both totals from the two percent fields.
  ///
  /// The previous version parsed the raw text with `int.parse` after an
  /// `if (value.isEmpty)` branch that was missing a `return`, so clearing
  /// either field threw a FormatException straight out of `onChanged`.
  /// Anything unparseable is now simply treated as 0%.
  void recalculate() {
    final base = cartSubtotal;
    final discountPercent =
        (double.tryParse(discountedValue) ?? 0).clamp(0, 100).toDouble();
    final cashPercent =
        (double.tryParse(cashDiscountedValue) ?? 0).clamp(0, 100).toDouble();

    subTotal = base - (base * discountPercent / 100);
    grandTotal = subTotal - (subTotal * cashPercent / 100);
    update();
  }

  void tapOnSearch() {
    Get.toNamed(AppRoutes.selectCompany)?.then((value) => update());
  }

  /// Mirrors the customer back into storage so a change made here and the one
  /// made on the Quick Order screen cannot disagree.
  void persistSelectedParty() {
    if (selectCompany?.partyid == null) return;
    SharedPre.setValue(
        SharedPre.quickOrderParty, json.encode(selectCompany!.toJson()));
  }

  /// Places the order.
  ///
  /// Was two near-identical branches (Customer vs everyone else) fronted by
  /// guards that refused to submit whenever either discount box was blank.
  /// Blank now simply means 0%, so the only real precondition is a customer
  /// and a non-empty cart.
  Future<void> tapOnPlaceOrder() async {
    if (isBusy) return;

    if (cartController.cartList.isEmpty) {
      ShowMessage.showSnackBar('', 'Your cart is empty');
      return;
    }
    if (!(isCustomer ?? false) && selectCompany?.partyid == null) {
      ShowMessage.showSnackBar('Server Res', AppString.pleaseSelectCompanyTxt);
      return;
    }

    setBusy(true);
    try {
      Map<String, String> body = {};
      body[RequestKeys.userId] =
          homeController.currentUserData!.userid.toString();
      body[RequestKeys.compId] =
          homeController.currentUserData!.compId.toString();
      body[RequestKeys.yearId] =
          homeController.currentUserData!.yearId.toString();
      body[RequestKeys.branchId] =
          homeController.currentUserData!.branchId.toString();
      body[RequestKeys.executiveId] =
          selectedDropdownValue?.executiveId.toString() ??
              homeController.currentUserData?.accountCode.toString() ??
              "";
      body[RequestKeys.partyId] = selectCompany?.partyid.toString() ?? '0';
      body[RequestKeys.totalAmount] = cartSubtotal.toString();
      body[RequestKeys.shippingAmount] = cartShipping.toString();
      body[RequestKeys.discountPercent] = discountedValue;
      body[RequestKeys.discountAmount] = subTotal.toString();
      body[RequestKeys.cashDiscountPercent] = cashDiscountedValue;
      body[RequestKeys.cashDiscountAmount] = grandTotal.toString();
      body[RequestKeys.grandTotal] = grandTotal.toString();

      var res = await api.orderPlace(body);
      if (res.status == 200) {
        SharedPre.clear(SharedPre.quickOrderParty);
        homeController.itemInCart.value = 0;
        Get.offAllNamed(AppRoutes.orderPlaced);
      } else {
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      setBusy(false);
    }
  }

  Future<void> getPartyDropdownList() async {
    try {
      Map<String, String> body = {};
      body[RequestKeys.compId] = homeController.currentUserData?.compId.toString() ?? '39';
      body[RequestKeys.userId] = homeController.currentUserData?.userid.toString() ?? '473693';
      body[RequestKeys.branchId] = homeController.currentUserData?.branchId.toString() ?? '122';
      var res = await api.getPartyDropdownList(body);
      if (res.status == 200) {
        getCustomerData();
        partyList = res.data??[];
        partyList.addAll(res.data!);
        await _applyQuickOrderParty();
        update();
      }
    } catch (e) {
      // ShowMessage.showSnackBar('Server Res', '$e');
    } finally {}
  }

  @override
  void onClose() {
    // TODO: implement onClose
    SharedPre.clear(SharedPre.selectedCustomer);
    SharedPre.clear(SharedPre.selectedCustomer2);
    super.onClose();
  }

  /// Pre-fills the company the user already chose (and had geo-validated) on
  /// the Quick Order screen, so checkout does not ask for it a second time.
  /// A Customer-type user is always locked to their own account, so their
  /// selection is left untouched.
  Future<void> _applyQuickOrderParty() async {
    if (homeController.currentUserData?.usertype.toString() == 'Customer') {
      return;
    }
    final raw = await SharedPre.getStringValue(SharedPre.quickOrderParty);
    if (raw.isEmpty) return;
    try {
      final party = PartyDropdownData.fromJson(json.decode(raw));
      if (party.partyid != null) selectCompany = party;
    } catch (_) {
      /// A malformed cached value must never block checkout — the user can
      /// still pick a company by hand.
      SharedPre.clear(SharedPre.quickOrderParty);
    }
  }

  void getCustomerData() async {
    print("===>");
    customer = await SharedPre.getStringValue(SharedPre.selectedCustomer);
    print("===>1");
    print("account Code=>${homeController.currentUserData!.accountCode}");
    print("party Id=>${customer}");

    if (homeController.currentUserData?.usertype=="Customer" ?? false) {
      selectCompany = partyList.firstWhere(
            (element) => element.partyid == homeController.currentUserData!.accountCode,
        orElse: () => PartyDropdownData(),
      );
      update();
      print("selectCompany===> ${selectCompany?.partyid}");
      print("===>2");
      customerdecodedList = CustomerListData.fromJson(json.decode(customer!));


      print("selectCompany===> ${selectCompany?.partyid}");

      // Set the selected company
      // selectCompany = selectParty;
      update();
    } else {
      // If the first customer data is not available, fetch another customer data
      customer2 = await SharedPre.getObjs(SharedPre.selectedCustomer2);

      if (customer2 != null) {
        // Decode the JSON data into a VisitPlanDetailsDataList object
        var dataList = VisitPlanDetailsDataList.fromJson(customer2);

        // Manually create the PartyDropdownData from the retrieved VisitPlanDetailsDataList
        var selectParty = PartyDropdownData(
          partyid: dataList.partyid,
          partyname: dataList.customername,
        );

        selectCompany = selectParty;
        update();
      }
    }
  }

}
