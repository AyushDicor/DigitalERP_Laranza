import 'dart:convert';

import 'package:digitalerp/app_routes/app_routes.dart';
import 'package:digitalerp/response/customer_detail_response.dart';
import 'package:digitalerp/response/get_cart_list_response.dart';
import 'package:digitalerp/response/get_executive_dropdown_response.dart';
import 'package:digitalerp/response/party_dropdown_list_response.dart';
import 'package:digitalerp/response/visit_plan_detail_data_response.dart';
import 'package:digitalerp/screen/base/base_controller.dart';
import 'package:digitalerp/screen/ui/home/cart/cart_controller.dart';
import 'package:digitalerp/screen/ui/home/home_controller.dart';
import 'package:digitalerp/screen/ui/home/order/order_controller.dart';
import 'package:digitalerp/services/api_service/request_keys.dart';
import 'package:digitalerp/utils/app_constant.dart';
import 'package:digitalerp/utils/order_line_pricing.dart';
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

  /// How each cart line was priced on the order-entry screen, keyed by item
  /// id. Local mirror — the cart API returns only the final rate.
  Map<int, OrderLinePricing> linePricing = {};

  OrderLinePricing? pricingFor(int? productId, double? serverRate) =>
      OrderLinePricingStore.resolve(linePricing, productId, serverRate);

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

    /// The company picked on the Quick Order screen is applied here, BEFORE
    /// the party list loads. It used to be applied inside
    /// [getPartyDropdownList], which meant a slow or failed party call left
    /// checkout asking for a company the user had already chosen.
    await _applyQuickOrderParty();

    /// Order type drives the labels and what the save call posts; it also
    /// pulls the per-item tax rates, which every order now needs.
    await _restoreOrderType();
    _loadLinePricing();

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

  Future<void> _loadLinePricing() async {
    linePricing = await OrderLinePricingStore.load();
    update();
  }

  /// List price for a line: the branch rate the user saw on the order screen,
  /// recorded when the line was added.
  ///
  /// Deliberately does NOT use `productdetail/getproductdetail`. That endpoint
  /// takes no branch and returns a different company-level column whose
  /// meaning is unconfirmed — for item 256776 it reports 473 while the branch
  /// sells at 614, so it is not an MRP and must not be presented as one.
  ///
  /// Falls back to the charged rate when no list price is known, so an unknown
  /// item contributes no phantom discount.
  double bestMrpFor(GetCartListData item) {
    final exact = pricingFor(item.productid, item.itemrate);
    if (exact != null && exact.mrp > 0) return exact.mrp;
    return (item.itemrate ?? 0).toDouble();
  }

  /// Net Rate for a line, or the charged rate when nothing was recorded — so
  /// an unknown line shows no phantom discount.
  double bestNetRateFor(GetCartListData item) {
    final exact = pricingFor(item.productid, item.itemrate);
    if (exact != null) return exact.netRate;
    return (item.itemrate ?? 0).toDouble();
  }

  /// The line's GST rate, or 0 while the order is being quoted tax-free.
  ///
  /// `cartdetailnew` reports 0 for every line added as an Estimate, so when an
  /// Estimate is switched to "GST Applicable" the rate has to come from
  /// somewhere else: [_gstByItemId], filled by [loadGstPercents] from
  /// `itemdetail`. The cart's own rate still wins when it has one.
  double gstPercentFor(GetCartListData item) {
    if (!gstApplicable) return 0;
    final fromCart = (item.gstpercent ?? 0).toDouble();
    if (fromCart > 0) return fromCart;
    return _gstByItemId[item.productid] ?? 0;
  }

  OrderTotals get totals => OrderTotals.from<GetCartListData>(
        lines: cartController.cartList,
        mrpOfLine: bestMrpFor,
        netRateOf: bestNetRateFor,
        chargedRateOf: (e) => (e.itemrate ?? 0).toDouble(),
        quantityOf: (e) => (e.quantity ?? 0).toDouble(),
        gstPercentOf: gstPercentFor,
      );

  /// Goods, tax and packaging in one place. The goods half comes straight from
  /// [totals], so this can never disagree with the Cart screen.
  OrderBill get bill => OrderBill(
        totals: totals,
        packaging: PackagingCharge(packagingCharge),
        chargesGst: gstApplicable,
        cashDiscountPercent: cashDiscountPercent,
      );

  /// What the goods come to BEFORE any discount — the figure
  /// [orderDiscountAmount] is taken off.
  ///
  /// Measured from whichever rate the document discounts against, matching
  /// how each line was sent to the cart: an Estimate is priced down from the
  /// MRP, a PI from the typed Net Rate.
  double get orderGrossAmount {
    final t = totals;
    return orderType.showsDiscountFields ? t.netTotal : t.mrpTotal;
  }

  /// Total rupees taken off the order — on an Estimate the MRP-to-Taxable-Amt
  /// gap across every line, on a PI the typed line discounts. Never negative:
  /// a line priced ABOVE its MRP is not a discount of minus something.
  double get orderDiscountAmount {
    final off = orderGrossAmount - totals.chargedTotal;
    return off > 0.01 ? off : 0;
  }

  double get orderDiscountPercent {
    final gross = orderGrossAmount;
    if (gross <= 0) return 0;
    return orderDiscountAmount / gross * 100;
  }

  // Order Type / tax / packaging

  /// Set on the Quick Order screen and carried here on the device; every cart
  /// line was also stamped with it via `addtocartwithnetrate.ordertype`, and
  /// it is posted on `placeorderlarnza`. Estimate is the default and behaves
  /// exactly as this screen did before PI existed: no tax, no packaging.
  OrderType orderType = OrderType.estimate;

  /// Whether tax is charged on this order. Always true.
  ///
  /// There was a "Gst as per applicable" / "Gst Calculation" selector here
  /// until 2026-10-06, when the backend ruled that every order is taxed —
  /// Estimate and PI alike — so the choice was removed and this pinned on.
  /// It stays a named flag rather than being inlined because it is the single
  /// point the bill, the labels, the packaging tax and `ordergsttype` all read
  /// from; if the rule changes again, only this has to move.
  final bool gstApplicable = true;

  /// Rates fetched from `itemdetail` for lines the cart reports as untaxed —
  /// every line of an Estimate. Keyed by item id.
  final Map<int, double> _gstByItemId = {};

  /// True while those rates are in flight, so the summary can say the tax is
  /// still being worked out instead of showing a wrong zero.
  bool isLoadingGst = false;

  /// Fills [_gstByItemId] for every cart line the server reports with no tax
  /// rate. One `itemdetail` call per item, in parallel; failures leave the
  /// line at 0, which [untaxedLineCount] then surfaces on the summary rather
  /// than quietly undercharging.
  Future<void> loadGstPercents() async {
    final ids = <int>{};
    for (final line in cartController.cartList) {
      final id = line.productid;
      if (id == null) continue;
      if ((line.gstpercent ?? 0) > 0) continue;
      if (_gstByItemId.containsKey(id)) continue;
      ids.add(id);
    }
    if (ids.isEmpty) return;

    isLoadingGst = true;
    update();
    try {
      final compId = homeController.currentUserData?.compId ?? 0;
      final results = await Future.wait(ids.map((id) async {
        try {
          final res = await api.getItemDetail(compid: compId, itemid: id);
          return MapEntry(id, res.data?.gstpercent ?? 0);
        } catch (_) {
          return MapEntry(id, 0.0);
        }
      }));
      for (final entry in results) {
        if (entry.value > 0) _gstByItemId[entry.key] = entry.value.toDouble();
      }

      /// Write the rates back into the local mirror too, so the Cart screen
      /// and a later visit to this screen start with them already known.
      await OrderLinePricingStore.mergeGstPercents(_gstByItemId);
    } finally {
      isLoadingGst = false;
      update();
    }
  }

  /// Cash discount for the whole order, typed above Packaging. Comes off the
  /// goods BEFORE tax — see [OrderBill.cashDiscountAmount] — and is posted as
  /// `cdpercent`/`cdamount`. Optional: left empty it is simply 0.
  double cashDiscountPercent = 0;

  final cdController = TextEditingController();

  /// Blank or unparseable reads as no discount; the value is held to 0..100 so
  /// a slip of the keyboard cannot invert the bill.
  void onCashDiscountTyped(String raw) {
    cashDiscountPercent =
        (double.tryParse(raw.trim()) ?? 0).clamp(0, 100).toDouble();
    update();
  }

  /// Base packaging charge typed by the user, PI only. Its 18% tax and the
  /// packaging total are derived by [PackagingCharge] and never editable.
  double packagingCharge = 0;

  final packagingController = TextEditingController();

  /// Blank reads as no packaging, and negatives are refused — packaging is
  /// optional, so an empty box must not block checkout.
  void onPackagingTyped(String raw) {
    final parsed = double.tryParse(raw.trim()) ?? 0;
    packagingCharge = parsed < 0 ? 0 : parsed;
    update();
  }

  /// Paise-safe string for the form body: `6315.95`, never `6315.9500001`.
  static String _money(double v) =>
      ((v * 100).roundToDouble() / 100).toStringAsFixed(2);

  Future<void> _restoreOrderType() async {
    final stored = await SharedPre.getStringValue(SharedPre.orderType);
    orderType = OrderType.fromName(stored.isEmpty ? null : stored);
    update();

    /// Every order is taxed now, so the per-item rates are always needed —
    /// including on an Estimate, whose cart lines the server stamps with
    /// `gstpercent 0`.
    await loadGstPercents();
  }

  /// Lines still with no tax rate while tax is being charged — an item with
  /// no GST set up, or one whose `itemdetail` lookup failed — so the summary
  /// can say the tax shown is incomplete instead of quietly undercharging.
  int get untaxedLineCount {
    if (!gstApplicable) return 0;
    return cartController.cartList
        .where((e) => gstPercentFor(e) <= 0)
        .length;
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

      /// Order-level money, in the three figures that have to agree:
      /// `totalamount − discountamount = taxableamount`.
      ///
      /// These used to carry the running totals instead of the discount —
      /// `discountamount` held the whole subtotal and `cdamount` the grand
      /// total, so an order with no discount at all posted
      /// `discountpercent 0` next to `discountamount 900`. The two typed
      /// discount boxes those values came from were dropped in the redesign;
      /// the discount now comes from how the lines were priced.
      ///
      /// The base is the same one each line measures its own discount
      /// against: the MRP on an Estimate (MRP → Taxable Amt), the typed Net
      /// Rate on a PI. So this total is exactly the sum of the per-line
      /// `discountamount`s already sent to the cart.
      final b = bill;
      body[RequestKeys.totalAmount] = _money(orderGrossAmount);
      body[RequestKeys.discountPercent] = _money(orderDiscountPercent);
      body[RequestKeys.discountAmount] = _money(orderDiscountAmount);

      /// Cash discount, typed on this screen. Taken off the goods before tax,
      /// so `taxableamount` below is already net of it.
      body[RequestKeys.cashDiscountPercent] = _money(b.cashDiscountPercent);
      body[RequestKeys.cashDiscountAmount] = _money(b.cashDiscountAmount);

      /// `placeorderlarnza` additions (probed 2026-09-21: the order's amount
      /// is taken from `finaltotal`, so `grandtotal` carries the same figure).
      /// Packaging and its 18% go on both document types, as does product
      /// GST — every order is taxed.
      ///
      /// The save proc's field names differ from the cart's (backend team,
      /// 2026-09-23): the packaging amount IS `shippingamount` — there is no
      /// `packagingcharge` parameter, which is why the ₹1,000 on order 33855
      /// never reached the printout's Freight line — its tax is
      /// `packinggstpercent`/`packinggstamt`, and the type is
      /// `orderentrytype`. Cart lines keep `ordertype`; only this call
      /// renames it. The cart's own `shippingamount` is not sent any more:
      /// it is always 0 for Laranza and would blank out the packaging.
      final total = b.finalTotal;
      body[RequestKeys.grandTotal] = _money(total);
      body[RequestKeys.orderEntryType] = orderType.apiValue;

      /// Always `Gstcalculation` — both document types are taxed. Still sent
      /// as its own field because the backend keeps it separate from
      /// `orderentrytype`.
      body[RequestKeys.orderGstType] = OrderGstMode.of(gstApplicable).apiValue;
      body[RequestKeys.taxableAmount] = _money(b.taxableAmount);
      body[RequestKeys.productGstAmount] = _money(b.productGst);
      body[RequestKeys.shippingAmount] = _money(b.packagingBase);
      body[RequestKeys.packingGstPercent] = PackagingCharge.gstPercent.toString();
      body[RequestKeys.packingGstAmount] = _money(b.packagingGst);
      body[RequestKeys.finalTotal] = _money(total);

      var res = await api.orderPlace(body);
      if (res.status == 200) {
        SharedPre.clear(SharedPre.quickOrderParty);
        OrderLinePricingStore.clear();
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
        partyList = res.data??[];
        partyList.addAll(res.data!);

        /// Only consulted when nothing has been chosen yet. [getCustomerData]
        /// is async and used to run first, resuming after the Quick Order
        /// party had been applied and overwriting it with a stale visit-plan
        /// customer (or an empty one).
        if (selectCompany?.partyid == null) {
          getCustomerData();
          await _applyQuickOrderParty();
        }
        update();
      }
    } catch (e) {
      // ShowMessage.showSnackBar('Server Res', '$e');
    } finally {}
  }

  @override
  void onClose() {
    // TODO: implement onClose
    cdController.dispose();
    packagingController.dispose();
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

        /// Never overrides a company already chosen on the Quick Order
        /// screen — this one comes from a visit plan opened at some earlier
        /// point and is only a fallback.
        if (selectCompany?.partyid == null) {
          selectCompany = selectParty;
          update();
        }
      }
    }
  }

}
