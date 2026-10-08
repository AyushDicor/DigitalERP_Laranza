import 'dart:convert';

import 'package:digitalerp/app_routes/app_routes.dart';
import 'package:digitalerp/response/brand_list_data_response.dart';
import 'package:digitalerp/response/cart_count_response.dart';
import 'package:digitalerp/response/party_dropdown_list_response.dart';
import 'package:digitalerp/response/subcategory_brand_response.dart';
import 'package:digitalerp/screen/base/base_controller.dart';
import 'package:digitalerp/screen/ui/home/home_controller.dart';
import 'package:digitalerp/services/api_service/request_keys.dart';
import 'package:digitalerp/utils/app_constant_new.dart';
import 'package:digitalerp/utils/order_line_pricing.dart';
import 'package:digitalerp/utils/shared_pre.dart';
import 'package:digitalerp/utils/show_message.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

/// One item the user has typed a quantity against but has not yet pushed to
/// the server cart. Kept keyed by `itemid` in [QuickOrderController.picked] so
/// a quantity survives switching category chips or brands — the whole point of
/// the redesign is to build one basket in a single pass and push it in one go.
class PickedItem {
  final ProductDataList item;
  final String brandName;
  double qty;

  /// List price for the line. The item-master rate on a PI, where it is fixed;
  /// on an Estimate the user may retype it, so it is held per line rather than
  /// read back off [item].
  double mrp;

  /// Rate actually charged before the line discount. Defaults to [mrp] but is
  /// editable per line, because a salesperson may need to quote a different
  /// price than the master carries.
  double netRate;

  /// Line discount, applied on top of [netRate] — as a percentage or as flat
  /// rupees per unit, never both. [discountType] says which one counts.
  double discountPercent;
  double discountAmount;
  OrderDiscountType discountType;

  PickedItem({
    required this.item,
    required this.brandName,
    required this.qty,
    required this.mrp,
    required this.netRate,
    required this.discountPercent,
    required this.discountAmount,
    required this.discountType,
  });

  /// Rupees off one unit, whichever way the discount was entered. Capped at
  /// the Net Rate so a line can never go negative.
  double get discountPerUnit {
    if (netRate <= 0) return 0;
    final off = discountType == OrderDiscountType.amount
        ? discountAmount
        : netRate * discountPercent / 100;
    return off.clamp(0, netRate).toDouble();
  }

  /// What the customer pays per unit, and what is sent to the cart as
  /// `itemrate` — the cart stores no discount column, so the discount has to
  /// be folded into the rate.
  double get finalRate => netRate - discountPerUnit;

  double get lineTotal => finalRate * qty;
}

/// Single-screen order entry: Company + Brand pickers on top, category chips,
/// then the full product list with an inline quantity stepper on every row and
/// one "Add All to Cart" action at the bottom.
///
/// Replaces the old Brand -> Category -> Product-list -> per-item-Add drill
/// down. No backend change was needed: `itemlistwithbranch` accepts
/// `categoryid=0` and returns every item for the brand, which is what lets the
/// category screen collapse into optional filter chips.
class QuickOrderController extends AppBaseController {
  final HomeController homeController = Get.find<HomeController>();

  // Company (party)
  List<PartyDropdownData> partyList = [];
  PartyDropdownData? selectedParty;
  bool isPartyLoading = false;
  bool isValidatingParty = false;
  Position? currentPosition;

  // Brand
  List<BrandItem> brandList = [];
  BrandItem? selectedBrand;
  bool isBrandLoading = false;

  /// The category filter chips were removed — the brand's whole catalogue is
  /// listed and the search box filters it. 0 means "every category", which is
  /// what the item-list API takes, so the product request is unchanged.
  static const int selectedCategoryId = 0;

  // Products
  /// Everything returned for the current brand + category, before search.
  List<ProductDataList> _allProducts = [];

  /// What the list actually renders (post search filter).
  List<ProductDataList> productList = [];
  final searchController = TextEditingController();

  // Basket staged locally until "Add All to Cart"
  final Map<int, PickedItem> picked = {};

  /// One long-lived text controller per item id. These must outlive list
  /// rebuilds — recreating a controller inside `build` resets the cursor on
  /// every keystroke, which makes multi-digit entry impossible.
  final Map<int, TextEditingController> _qtyCtrls = {};
  final Map<int, TextEditingController> _mrpCtrls = {};
  final Map<int, TextEditingController> _rateCtrls = {};
  final Map<int, TextEditingController> _discCtrls = {};
  final Map<int, TextEditingController> _discAmtCtrls = {};

  /// Per-line pricing overrides, keyed by item id. Held separately from
  /// [picked] so a rate typed before any quantity is not lost, and so both
  /// survive switching category chips or brands.
  final Map<int, double> _mrps = {};
  final Map<int, double> _netRates = {};
  final Map<int, double> _discounts = {};
  final Map<int, double> _discountAmounts = {};
  final Map<int, OrderDiscountType> _discountTypes = {};

  // Order Type

  /// Estimate or PI. Drives whether the MRP may be retyped and whether tax is
  /// added at checkout; see [OrderType]. Defaults to Estimate, which is the
  /// behaviour the screen had before the type existed.
  OrderType orderType = OrderType.estimate;

  static const String orderTypeId = 'quick_order_order_type';

  /// Switching the document type re-prices nothing that was typed — a Net
  /// Rate or discount entered for a line stays. Only a retyped MRP is dropped
  /// on the way to PI, where the master rate is authoritative.
  void onPickOrderType(OrderType type) {
    if (type == orderType) return;
    orderType = type;

    /// An Estimate shows no discount boxes, so anything typed into them on a
    /// PI is dropped on the way over rather than left to price a line the
    /// user can no longer see.
    if (!type.showsDiscountFields) {
      _discounts.clear();
      _discountAmounts.clear();
      for (final c in _discCtrls.values) {
        c.text = '';
      }
      for (final c in _discAmtCtrls.values) {
        c.text = '';
      }
      for (final entry in picked.values) {
        entry.discountPercent = 0;
        entry.discountAmount = 0;
      }
    }

    if (!type.allowsMrpEdit && _mrps.isNotEmpty) {
      final ids = _mrps.keys.toList();
      _mrps.clear();
      for (final id in ids) {
        _mrpCtrls[id]?.text = '';
        final entry = picked[id];
        if (entry != null) {
          entry.mrp = masterRateOf(entry.item);

          /// A line with no typed Net Rate is priced at its MRP, so it has to
          /// follow the MRP back to the master rate too.
          entry.netRate = netRateOf(entry.item);
        }
      }
    }

    SharedPre.setValue(SharedPre.orderType, type.name);
    update();
  }

  /// The line's list price: the item-master rate, or the one typed over it on
  /// an Estimate. An empty MRP box means "use the master rate".
  double mrpOf(ProductDataList item) =>
      _mrps[item.itemid] ?? masterRateOf(item);

  /// The item-master price, exactly as the server sent it. Never altered by
  /// anything typed on this screen.
  double masterRateOf(ProductDataList item) => (item.rate ?? 0).toDouble();

  bool hasMrpOverride(int? itemId) => _mrps.containsKey(itemId);

  /// The rate the line is priced at: the typed Net Rate when one has been
  /// entered, otherwise the MRP. Leaving the field empty means "use the MRP",
  /// which is why an empty box clears the override rather than setting 0.
  double netRateOf(ProductDataList item) =>
      _netRates[item.itemid] ?? mrpOf(item);

  bool hasNetRateOverride(int? itemId) => _netRates.containsKey(itemId);

  /// A line is priced EITHER by typing a Net Rate OR by taking a discount off
  /// the MRP — never both, because the two would fight over the same rate and
  /// the bill could not say which the customer was given.
  ///
  /// Whichever box is filled first locks the other; clearing it unlocks again,
  /// so nothing is a dead end. Both are false on an untouched line, leaving
  /// the user free to start with either.
  bool netRateLocked(int? itemId) => hasDiscountEntry(itemId);

  bool discountLocked(int? itemId) => hasNetRateOverride(itemId);

  /// True when this line carries a discount, whichever way it was expressed.
  /// Reads the stored values rather than the text so "0" and a cleared box
  /// both count as no discount and release the lock.
  bool hasDiscountEntry(int? itemId) =>
      discountOf(itemId) > 0 || discountAmountOf(itemId) > 0;

  double discountOf(int? itemId) => _discounts[itemId] ?? 0;

  double discountAmountOf(int? itemId) => _discountAmounts[itemId] ?? 0;

  OrderDiscountType discountTypeOf(int? itemId) =>
      _discountTypes[itemId] ?? OrderDiscountType.percent;

  /// Rupees off one unit, whichever way the line's discount was entered.
  ///
  /// Always 0 on an Estimate: that type has no discount boxes at all — its
  /// discount is the MRP-to-Taxable-Amount gap, worked out at save time by
  /// [derivedDiscountPerUnitOf] — so a value typed on a PI before switching
  /// type can never quietly re-price an Estimate line.
  double discountPerUnitOf(ProductDataList item) {
    if (!orderType.showsDiscountFields) return 0;
    final net = netRateOf(item);
    if (net <= 0) return 0;
    final id = item.itemid;
    final off = discountTypeOf(id) == OrderDiscountType.amount
        ? discountAmountOf(id)
        : net * discountOf(id) / 100;
    return off.clamp(0, net).toDouble();
  }

  /// The Estimate's implicit discount: what one unit is being sold below its
  /// MRP. The user types an MRP and a Taxable Amount; the gap between them is
  /// posted as `discountamount`/`discountpercent` so the printed document
  /// still shows both columns, but it is never presented as a discount box on
  /// this screen.
  ///
  /// Zero on a PI, where the discount is typed rather than derived.
  double derivedDiscountPerUnitOf(ProductDataList item) {
    if (orderType.showsDiscountFields) return 0;
    final mrp = mrpOf(item);
    if (mrp <= 0) return 0;
    final off = mrp - netRateOf(item);
    return off <= 0 ? 0 : off.clamp(0, mrp).toDouble();
  }

  /// Net rate less the line discount — the figure that reaches the cart.
  double finalRateOf(ProductDataList item) =>
      netRateOf(item) - discountPerUnitOf(item);

  /// Starts empty, with the master rate as the hint — an MRP box left alone
  /// means "use the item-master rate", the same convention the Net Rate box
  /// follows. Estimate only; on a PI the field is not shown.
  TextEditingController mrpCtrl(ProductDataList item) {
    final id = item.itemid ?? -1;
    return _mrpCtrls.putIfAbsent(id, () {
      final override = _mrps[id];
      return TextEditingController(
          text: override == null ? '' : fmtMoney(override));
    });
  }

  /// Starts empty, with the MRP shown as the hint. Pre-filling it with the MRP
  /// made an untouched line look edited, and clearing it then read as a rate
  /// of 0 instead of "fall back to MRP".
  TextEditingController rateCtrl(ProductDataList item) {
    final id = item.itemid ?? -1;
    return _rateCtrls.putIfAbsent(id, () {
      final override = _netRates[id];
      return TextEditingController(
          text: override == null ? '' : fmtMoney(override));
    });
  }

  TextEditingController discCtrl(ProductDataList item) {
    final id = item.itemid ?? -1;
    return _discCtrls.putIfAbsent(id, () {
      final d = discountOf(id);
      return TextEditingController(text: d == 0 ? '' : fmtQty(d));
    });
  }

  TextEditingController discAmtCtrl(ProductDataList item) {
    final id = item.itemid ?? -1;
    return _discAmtCtrls.putIfAbsent(id, () {
      final d = discountAmountOf(id);
      return TextEditingController(text: d == 0 ? '' : fmtMoney(d));
    });
  }

  /// Trims a trailing `.0` but keeps real paise.
  static String fmtMoney(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);

  /// GetBuilder ids so typing only repaints the row being typed in and the
  /// bottom bar, instead of the whole product list.
  static const String bottomBarId = 'quick_order_bottom_bar';

  static String rowId(int? itemId) => 'quick_order_row_$itemId';

  TextEditingController qtyCtrl(ProductDataList item) {
    final id = item.itemid ?? -1;
    return _qtyCtrls.putIfAbsent(id, () {
      final q = qtyOf(id);
      return TextEditingController(text: q <= 0 ? '' : fmtQty(q));
    });
  }

  /// Trims the pointless `.0` off whole numbers.
  static String fmtQty(double qty) =>
      qty % 1 == 0 ? qty.toInt().toString() : qty.toString();

  /// Keeps paise but drops binary-float noise (552.5999999 -> 552.6) before
  /// the value goes over the wire as a JSON number.
  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  /// Guards the bulk push. The add-to-cart endpoint is *additive* server-side
  /// (calling it twice for an item adds to its quantity rather than setting
  /// it), so a double tap would silently double the order.
  bool isAddingToCart = false;
  int addedSoFar = 0;

  int get pickedCount => picked.length;

  double get pickedTotal =>
      picked.values.fold(0.0, (sum, e) => sum + e.lineTotal);

  double qtyOf(int? itemId) => picked[itemId]?.qty ?? 0;

  bool get isCustomerUser =>
      homeController.currentUserData?.usertype.toString() == 'Customer';

  @override
  void onInit() {
    _restoreOrderType();
    getPartyList();
    getBrandList();
    getCartCount();
    _resolveCurrentPosition();
    super.onInit();
  }

  /// The document type survives leaving the screen, so a user who goes to the
  /// cart and comes back to add more lines does not silently drop from PI to
  /// Estimate mid-basket.
  Future<void> _restoreOrderType() async {
    final stored = await SharedPre.getStringValue(SharedPre.orderType);
    if (stored.isEmpty) return;
    orderType = OrderType.fromName(stored);
    update();
  }

  @override
  void onClose() {
    searchController.dispose();
    for (final c in [
      ..._qtyCtrls.values,
      ..._mrpCtrls.values,
      ..._rateCtrls.values,
      ..._discCtrls.values,
      ..._discAmtCtrls.values,
    ]) {
      c.dispose();
    }
    _qtyCtrls.clear();
    _mrpCtrls.clear();
    _rateCtrls.clear();
    _discCtrls.clear();
    _discAmtCtrls.clear();
    super.onClose();
  }

  // Company

  Future<void> getPartyList() async {
    isPartyLoading = true;
    update();
    try {
      Map<String, String> body = {};
      body[RequestKeys.compId] =
          homeController.currentUserData?.compId.toString() ?? '';
      body[RequestKeys.userId] =
          homeController.currentUserData?.userid.toString() ?? '';
      body[RequestKeys.branchId] =
          homeController.currentUserData?.branchId.toString() ?? '';
      var res = await api.getPartyDropdownList(body);
      if (res.status == 200) {
        partyList = res.data ?? [];

        /// A Customer-type user can only ever order for themselves, so lock
        /// the company to their own account instead of offering the picker.
        if (isCustomerUser) {
          selectedParty = partyList.firstWhere(
            (e) => e.partyid == homeController.currentUserData?.accountCode,
            orElse: () => PartyDropdownData(),
          );
          if (selectedParty?.partyid != null) _persistSelectedParty();
        }
      } else {
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      isPartyLoading = false;
      update();
    }
  }

  /// Picks up the device position once on entry so selecting a company does
  /// not have to wait on a GPS fix. Failures are swallowed here and retried at
  /// selection time, where the user can be told what to fix.
  ///
  /// Skipped entirely while the geo-fence is off, so the screen does not ask
  /// for a location permission it has no use for.
  Future<void> _resolveCurrentPosition() async {
    if (!kEnforcePartyGeofence) return;
    currentPosition = await _tryPosition();
  }

  Future<Position?> _tryPosition() async {
    try {
      return await getUserCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  /// Handles a company pick end to end: warns when the server cart already
  /// holds items added against a *different* company, then runs the same
  /// geo-fence validation the old Select Company screen enforced.
  Future<void> onPickParty(PartyDropdownData party) async {
    if (party.partyid == selectedParty?.partyid) return;

    final cartCount = homeController.itemInCart.value;
    if (cartCount > 0 && selectedParty?.partyid != null) {
      final proceed = await _confirmCompanySwitch(cartCount);
      if (proceed != true) return;
    }

    await _validateAndSetParty(party);
  }

  Future<bool?> _confirmCompanySwitch(int cartCount) {
    return Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Change company?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: newTextPrimary,
          ),
        ),
        content: Text(
          'Your cart still has $cartCount item(s) added for '
          '"${selectedParty?.partyname ?? ''}". The order is placed against '
          'whichever company is selected at checkout.',
          style: const TextStyle(fontSize: 13, color: newTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child:
                const Text('Cancel', style: TextStyle(color: newTextSecondary)),
          ),
          TextButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Continue', style: TextStyle(color: newBlueColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _validateAndSetParty(PartyDropdownData party) async {
    /// Geo-fence disabled — see [kEnforcePartyGeofence]. With no party
    /// coordinates in the ERP the check rejected every customer, so selection
    /// is immediate and needs no location permission.
    if (!kEnforcePartyGeofence) {
      selectedParty = party;
      _persistSelectedParty();
      update();
      return;
    }

    currentPosition ??= await _tryPosition();
    if (currentPosition == null) {
      ShowMessage.showSnackBar(
        'Location required',
        'Turn on location and allow permission to select a company.',
      );
      return;
    }

    isValidatingParty = true;
    update();
    try {
      Map<String, String> body = {};
      body[RequestKeys.compId] =
          homeController.currentUserData?.compId.toString() ?? '';
      body[RequestKeys.userId] =
          homeController.currentUserData?.userid.toString() ?? '';
      body[RequestKeys.partyId] = party.partyid.toString();
      body[RequestKeys.latitude] = currentPosition!.latitude.toString();
      body[RequestKeys.longitude] = currentPosition!.longitude.toString();

      var res = await api.matchPartyLatLng(body);
      if (res.status == 200 && (res.success ?? true)) {
        selectedParty = party;
        _persistSelectedParty();
      } else {
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      isValidatingParty = false;
      update();
    }
  }

  /// Hands the company off to checkout. The server cart is not party-scoped —
  /// the party is only attached at `orderPlace` — so Your Order reads this
  /// back and pre-fills its Select Company field.
  void _persistSelectedParty() {
    if (selectedParty?.partyid == null) return;
    SharedPre.setValue(
        SharedPre.quickOrderParty, json.encode(selectedParty!.toJson()));
  }

  // Brand + categories

  Future<void> getBrandList() async {
    isBrandLoading = true;
    update();
    try {
      Map<String, String> body = {};
      body[RequestKeys.compId] =
          homeController.currentUserData?.compId.toString() ?? '';
      body[RequestKeys.userId] =
          homeController.currentUserData?.userid.toString() ?? '';
      body[RequestKeys.branchId] =
          homeController.currentUserData?.branchId.toString() ?? '0';
      var res = await api.getBrandData(body);
      if (res.status == 200) {
        brandList = res.data ?? [];

        /// Most companies carry a single brand — skip the pointless tap.
        if (brandList.length == 1) {
          selectedBrand = brandList.first;
          getProductList();
        }
      } else {
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      isBrandLoading = false;
      update();
    }
  }

  void onPickBrand(BrandItem brand) {
    if (brand.brandid == selectedBrand?.brandid) return;
    selectedBrand = brand;
    _allProducts = [];
    productList = [];
    searchController.clear();
    update();
    getProductList();
  }


  Future<void> getProductList() async {
    if (selectedBrand?.brandid == null) return;
    setListLoading(true);
    try {
      Map<String, String> body = {};
      body[RequestKeys.compId] =
          homeController.currentUserData?.compId.toString() ?? '';

      /// `0` means "every category under this brand" — verified against the
      /// live endpoint, and what lets this screen skip the category step.
      body[RequestKeys.categoryId] = selectedCategoryId.toString();
      body[RequestKeys.subCategoryId] = '0';
      body[RequestKeys.brandId] = selectedBrand!.brandid.toString();
      body[RequestKeys.rateFrom] = '0';
      body[RequestKeys.rateTo] = '0';
      body[RequestKeys.itemName] = '';
      body[RequestKeys.branchId] =
          homeController.currentUserData?.branchId.toString() ?? '0';

      var res = await api.getProductData(body);
      if (res.status == 200) {
        _allProducts = res.data ?? [];
        _applySearch(searchController.text);
      } else {
        _allProducts = [];
        productList = [];
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      setListLoading(false);
    }
  }

  /// Filters in memory — the whole brand is already loaded, so there is no
  /// reason to round-trip the server on every keystroke.
  void searchProduct(String value) {
    _applySearch(value);
    update();
  }

  void _applySearch(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) {
      productList = List<ProductDataList>.from(_allProducts);
      return;
    }
    /// Name, code and description. There is no serial-number field on
    /// `itemlistwithbranch` — the response carries only itemid, itemname,
    /// itemcode, itemdescription, unit and rate — so a serial typed here can
    /// only match if it was recorded in the description. Add it to this list
    /// the day the backend returns one.
    productList = _allProducts.where((e) {
      final name = (e.itemname ?? '').toLowerCase();
      final code = (e.itemcode ?? '').toLowerCase();
      final desc = (e.itemdescription ?? '').toLowerCase();
      return name.contains(query) ||
          code.contains(query) ||
          desc.contains(query);
    }).toList();
  }

  // Quantity staging

  /// [syncField] must stay false when the change *came from* the text field —
  /// writing back into the controller mid-edit would move the caret.
  void setQty(ProductDataList item, double qty, {bool syncField = true}) {
    final id = item.itemid;
    if (id == null) return;

    /// The company is mandatory before anything can be staged. Checking only
    /// at Add-All let a user price a whole basket and be told at the last
    /// step; refusing the first quantity points them at the field instead.
    /// Removing a line is always allowed, so a basket staged before the rule
    /// can still be emptied.
    if (qty > 0 && !requireParty()) {
      /// Nothing was staged, so the box must not keep showing the number —
      /// including when the quantity was typed rather than stepped.
      _writeField(id, 0);
      update([rowId(id), bottomBarId]);
      return;
    }

    if (qty <= 0) {
      picked.remove(id);
    } else {
      picked[id] = PickedItem(
        item: item,
        brandName: selectedBrand?.brandname ?? '',
        qty: qty,
        mrp: mrpOf(item),
        netRate: netRateOf(item),
        discountPercent: discountOf(id),
        discountAmount: discountAmountOf(id),
        discountType: discountTypeOf(id),
      );
    }

    if (syncField) _writeField(id, qty);
    update([rowId(id), bottomBarId]);
  }

  void _writeField(int id, double qty) {
    final ctrl = _qtyCtrls[id];
    if (ctrl == null) return;
    final text = qty <= 0 ? '' : fmtQty(qty);
    if (ctrl.text == text) return;
    ctrl.text = text;
    ctrl.selection = TextSelection.collapsed(offset: text.length);
  }

  /// True when a company is selected. Otherwise it says so and returns false,
  /// so every caller can simply `if (!requireParty()) return;`.
  ///
  /// A Customer-type user always orders for their own account, which the
  /// screen fills in and locks, so they are never asked.
  bool requireParty() {
    if (isCustomerUser || selectedParty?.partyid != null) return true;
    ShowMessage.showSnackBar('Company required',
        'Select a company before adding items to the order');
    return false;
  }

  void increaseQty(ProductDataList item) => setQty(item, qtyOf(item.itemid) + 1);

  void decreaseQty(ProductDataList item) {
    final next = qtyOf(item.itemid) - 1;
    setQty(item, next < 0 ? 0 : next);
  }

  /// Accepts decimals — the backend stores quantity as a decimal and several
  /// units here are weight based (KGS).
  void onQtyTyped(ProductDataList item, String raw) {
    final parsed = double.tryParse(raw.trim());
    setQty(item, parsed ?? 0, syncField: false);
  }

  /// Estimate only. An MRP of 0 is rejected at save time by [mrpError] rather
  /// than here, so the user can clear the box and retype without the value
  /// being snapped back under the caret.
  void onMrpTyped(ProductDataList item, String raw) {
    final id = item.itemid;
    if (id == null) return;

    final text = raw.trim();
    final parsed = double.tryParse(text);
    if (text.isEmpty || parsed == null) {
      /// Empty means "no override" — the line goes back to the master rate.
      _mrps.remove(id);
    } else {
      _mrps[id] = parsed;
    }

    final entry = picked[id];
    if (entry != null) {
      entry.mrp = mrpOf(item);

      /// The Net Rate follows the MRP only while it has not been typed over.
      entry.netRate = netRateOf(item);
    }
    update([rowId(id), bottomBarId]);
  }

  /// The first staged line whose MRP is not a usable price, or null when every
  /// line is fine. An MRP must be a number greater than zero.
  ///
  /// Only meaningful on an Estimate; a PI always prices off the master rate.
  String? get mrpError {
    if (!orderType.allowsMrpEdit) return null;
    for (final entry in picked.values) {
      if (entry.mrp <= 0) {
        return 'Enter an MRP greater than 0 for '
            '"${entry.item.itemname ?? 'this item'}"';
      }
    }
    return null;
  }

  void onNetRateTyped(ProductDataList item, String raw) {
    final id = item.itemid;
    if (id == null) return;

    /// The box is disabled while a discount is live, so this should not fire;
    /// refused here too, because a value that slipped past the UI would be
    /// applied on top of the discount instead of instead of it.
    if (netRateLocked(id)) return;

    final text = raw.trim();
    final parsed = double.tryParse(text);
    if (text.isEmpty || parsed == null) {
      /// Empty means "no override" — the line goes back to being priced at
      /// the MRP rather than at zero.
      _netRates.remove(id);
    } else {
      _netRates[id] = parsed;
    }

    /// Keep an already-staged line in step with the edit.
    picked[id]?.netRate = netRateOf(item);
    update([rowId(id), bottomBarId]);
  }

  /// Switches a line between a percentage and a flat amount, clearing whatever
  /// was typed under the old type. Only one discount can ever be live, so the
  /// two can never be applied together or sent together.
  void onPickDiscountType(ProductDataList item, OrderDiscountType type) {
    final id = item.itemid;
    if (id == null || discountTypeOf(id) == type) return;

    _discountTypes[id] = type;
    _discounts.remove(id);
    _discountAmounts.remove(id);
    _discCtrls[id]?.text = '';
    _discAmtCtrls[id]?.text = '';

    final entry = picked[id];
    if (entry != null) {
      entry.discountType = type;
      entry.discountPercent = 0;
      entry.discountAmount = 0;
    }
    update([rowId(id), bottomBarId]);
  }

  /// A percentage is clamped to 0-100; anything unparseable reads as no
  /// discount rather than throwing out of `onChanged`.
  void onDiscountTyped(ProductDataList item, String raw) {
    final id = item.itemid;
    if (id == null || discountLocked(id)) return;
    final value = (double.tryParse(raw.trim()) ?? 0).clamp(0, 100).toDouble();
    _discounts[id] = value;
    picked[id]?.discountPercent = value;
    update([rowId(id), bottomBarId]);
  }

  /// Flat rupees off one unit. Negatives are rejected, and anything above the
  /// Net Rate is capped by [discountPerUnitOf] so the line cannot go negative.
  void onDiscountAmountTyped(ProductDataList item, String raw) {
    final id = item.itemid;
    if (id == null || discountLocked(id)) return;
    final parsed = double.tryParse(raw.trim()) ?? 0;
    final value = parsed < 0 ? 0.0 : parsed;
    _discountAmounts[id] = value;
    picked[id]?.discountAmount = value;
    update([rowId(id), bottomBarId]);
  }

  void removePicked(int itemId) {
    picked.remove(itemId);
    _writeField(itemId, 0);
    update([rowId(itemId), bottomBarId]);
  }

  void clearPicked() {
    final entries = picked.values.toList();
    picked.clear();
    for (final e in entries) {
      _writeField(e.item.itemid ?? -1, 0);
      _resetPricing(e.item);
    }
    update();
  }

  /// Returns a line's MRP and Net Rate to the item-master rate and clears its
  /// discount, so a line that has gone to the cart does not leave stale
  /// pricing behind on the screen.
  void _resetPricing(ProductDataList item) {
    final id = item.itemid;
    if (id == null) return;
    _mrps.remove(id);
    _netRates.remove(id);
    _discounts.remove(id);
    _discountAmounts.remove(id);
    _discountTypes.remove(id);
    _mrpCtrls[id]?.text = '';
    _rateCtrls[id]?.text = '';
    _discCtrls[id]?.text = '';
    _discAmtCtrls[id]?.text = '';
  }

  // Bulk add to cart

  /// Pushes every staged line to the server cart. The endpoint takes one item
  /// per call, so this loops — sequentially, because the backend recomputes
  /// the cart total on each hit.
  Future<void> addAllToCart() async {
    if (isAddingToCart) return;

    if (!requireParty()) return;
    if (picked.isEmpty) {
      ShowMessage.showSnackBar('', 'Enter a quantity for at least one item');
      return;
    }

    /// An Estimate may be priced off a retyped MRP, and a zero one would post
    /// a free line. Blocked here rather than in the field so the box can be
    /// cleared and retyped without the value snapping back.
    final invalidMrp = mrpError;
    if (invalidMrp != null) {
      ShowMessage.showSnackBar('Check MRP', invalidMrp);
      return;
    }

    isAddingToCart = true;
    addedSoFar = 0;
    update([bottomBarId]);

    final entries = picked.values.toList();
    final failedIds = <int>{};
    int? latestCartCount;

    try {
      for (final entry in entries) {
        /// How each line goes to `addtocartwithnetrate` (contract in
        /// [callAddToCartWithNetRate], probed 2026-09-21/22):
        ///
        ///   no discount, no Net Rate   netrate 0 → server prices at MRP
        ///   no discount, Net Rate      netrate = net
        ///   any discount               netrate = net (PRE-discount), plus BOTH
        ///                              discountamount (₹ for the WHOLE LINE —
        ///                              the server divides by qty and subtracts
        ///                              it from the rate) and discountpercent
        ///                              (recorded only, for the print-out)
        ///
        /// The user types one of the two; the other is derived so the bill can
        /// show both columns filled (20 % of 600 = ₹120/unit; ₹1,000 off 9,000
        /// = 11.11 %). The stored rate still equals [PickedItem.finalRate],
        /// which is what the local pricing mirror is checked against.
        ///
        /// Probed 2026-09-22: netrate 900, qty 3, discountamount 300 → stored
        /// 800 (= 900 − 300/3), so the amount is per line, not per unit.
        ///
        /// Rates carry paise; the original code truncated with `toInt()`,
        /// which silently threw away most of a discount.
        ///
        /// An **Estimate** has no discount boxes, so its discount is derived:
        /// the line is posted at `netrate = MRP` with the MRP-to-Taxable-Amount
        /// gap as `discountamount`, which lands the stored rate back on the
        /// Taxable Amount the user typed (server: rate = netrate − amount/qty)
        /// and fills both discount columns on the printed document. Nothing
        /// about this is shown on screen.
        final id = entry.item.itemid;
        final derived = !orderType.showsDiscountFields;
        final offPerUnit = _round2(
            derived ? derivedDiscountPerUnitOf(entry.item) : entry.discountPerUnit);
        final discounted = offPerUnit > 0;

        /// The rate the discount is measured against: the MRP on an Estimate,
        /// the typed Net Rate on a PI.
        final base = derived ? entry.mrp : entry.netRate;
        final pct =
            discounted && base > 0 ? _round2(offPerUnit / base * 100) : 0.0;
        final res = await callAddToCartWithNetRate(
          itemId: id ?? 0,
          itemRate: _round2(entry.mrp),
          netRate: discounted || hasNetRateOverride(id) ? _round2(base) : 0,
          discountPercent: pct,
          discountAmount: _round2(offPerUnit * entry.qty),
          orderType: orderType.apiValue,
          quantity: entry.qty,
          unitId: entry.item.unitid ?? 0,
        );
        if (res.status == 200) {
          /// `data` may be an empty object on the newer endpoint, so never
          /// assume a row is present. The count is refreshed from the server
          /// afterwards regardless.
          final rows = res.data;
          if (rows != null && rows.isNotEmpty) {
            latestCartCount = rows.first.totalnumber ?? latestCartCount;
          }
        } else {
          failedIds.add(entry.item.itemid ?? -1);
        }
        addedSoFar++;
        update([bottomBarId]);
      }

      final successCount = entries.length - failedIds.length;
      if (latestCartCount != null) {
        homeController.itemInCart.value = latestCartCount;
      } else if (successCount > 0) {
        homeController.itemInCart.value += successCount;
      }

      /// Only clear what actually landed, so a partial failure leaves the
      /// failed rows staged to retry rather than silently dropping them.
      /// Mirror how each line was priced so the Place Order screen can show
      /// the MRP -> Net Rate -> discount calculation. The cart itself only
      /// keeps the final rate.
      final pricingToStore = <int, OrderLinePricing>{};

      final addedIds =
          picked.keys.where((id) => !failedIds.contains(id)).toList();
      for (final id in addedIds) {
        final entry = picked.remove(id);
        _writeField(id, 0);
        if (entry != null) {
          /// The mirror records what the line is CHARGED at, which is what
          /// the cart holds. On an Estimate that is the Taxable Amount with
          /// no discount on top — the derived discount posted above is a
          /// presentation of the MRP gap, not a second reduction.
          final derivedLine = !orderType.showsDiscountFields;
          pricingToStore[id] = OrderLinePricing(
            mrp: entry.mrp,
            netRate: entry.netRate,
            discountPercent: derivedLine ? 0 : entry.discountPercent,
            discountAmount: derivedLine ? 0 : entry.discountAmount,
            discountType: entry.discountType,
          );
          _resetPricing(entry.item);
        }
      }
      await OrderLinePricingStore.merge(pricingToStore);

      if (failedIds.isEmpty) {
        ShowMessage.showSnackBar('', '$successCount item(s) added to cart');
      } else {
        ShowMessage.showSnackBar(
          'Partly added',
          '$successCount added, ${failedIds.length} failed. Failed items are '
              'still listed — try again.',
        );
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      isAddingToCart = false;
      addedSoFar = 0;
      update();
      getCartCount();
    }
  }

  Future<void> getCartCount() async {
    try {
      Map<String, String> body = {};
      body[RequestKeys.userId] =
          homeController.currentUserData?.userid.toString() ?? '';
      body[RequestKeys.compId] =
          homeController.currentUserData?.compId.toString() ?? '';
      CartCountResponse res = await api.getCartCount(body);
      if (res.status == 200) {
        homeController.itemInCart.value =
            res.data?.first.totalcartcount?.toInt() ??
                homeController.itemInCart.value;
        update();
      }
    } catch (_) {
      /// Badge accuracy is cosmetic — never block entry on it.
    }
  }

  /// Same destination as the base implementation, but refreshes the badge on
  /// return so removing items in the cart is reflected here immediately.
  @override
  void tapOnCart() {
    Get.toNamed(AppRoutes.cart)?.then((_) => getCartCount());
  }
}
