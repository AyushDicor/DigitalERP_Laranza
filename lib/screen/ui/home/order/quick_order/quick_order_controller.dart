import 'dart:convert';

import 'package:digitalerp/app_routes/app_routes.dart';
import 'package:digitalerp/response/brand_list_data_response.dart';
import 'package:digitalerp/response/cart_count_response.dart';
import 'package:digitalerp/response/party_dropdown_list_response.dart';
import 'package:digitalerp/response/select_category_list_response.dart';
import 'package:digitalerp/response/subcategory_brand_response.dart';
import 'package:digitalerp/screen/base/base_controller.dart';
import 'package:digitalerp/screen/ui/home/home_controller.dart';
import 'package:digitalerp/services/api_service/request_keys.dart';
import 'package:digitalerp/utils/app_constant_new.dart';
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

  PickedItem({required this.item, required this.brandName, required this.qty});

  double get lineTotal => (item.rate ?? 0) * qty;
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

  // Category chips (0 == "All")
  List<CategoryItem> categoryList = [];
  int selectedCategoryId = 0;

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
    getPartyList();
    getBrandList();
    getCartCount();
    _resolveCurrentPosition();
    super.onInit();
  }

  @override
  void onClose() {
    searchController.dispose();
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    _qtyCtrls.clear();
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
  Future<void> _resolveCurrentPosition() async {
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
          getCategoryList();
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
    selectedCategoryId = 0;
    categoryList = [];
    _allProducts = [];
    productList = [];
    searchController.clear();
    update();
    getCategoryList();
    getProductList();
  }

  Future<void> getCategoryList() async {
    if (selectedBrand?.brandid == null) return;
    try {
      Map<String, String> body = {};
      body[RequestKeys.compId] =
          homeController.currentUserData?.compId.toString() ?? '';
      body[RequestKeys.brandId] = selectedBrand!.brandid.toString();
      body[RequestKeys.branchId] =
          homeController.currentUserData?.branchId.toString() ?? '0';
      var res = await api.getCategoryData(body);
      if (res.status == 200) {
        categoryList = (res.data as List?)?.cast<CategoryItem>() ?? [];
        update();
      }
    } catch (_) {
      /// Chips are a convenience filter — if they fail the full list still
      /// renders, so this stays silent rather than throwing a snackbar at the
      /// user mid-entry.
    }
  }

  void onPickCategory(int categoryId) {
    if (categoryId == selectedCategoryId) return;
    selectedCategoryId = categoryId;
    update();
    getProductList();
  }

  // Products

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
    productList = _allProducts.where((e) {
      final name = (e.itemname ?? '').toLowerCase();
      final code = (e.itemcode ?? '').toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();
  }

  // Quantity staging

  /// [syncField] must stay false when the change *came from* the text field —
  /// writing back into the controller mid-edit would move the caret.
  void setQty(ProductDataList item, double qty, {bool syncField = true}) {
    final id = item.itemid;
    if (id == null) return;

    if (qty <= 0) {
      picked.remove(id);
    } else {
      picked[id] = PickedItem(
        item: item,
        brandName: selectedBrand?.brandname ?? '',
        qty: qty,
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

  void removePicked(int itemId) {
    picked.remove(itemId);
    _writeField(itemId, 0);
    update([rowId(itemId), bottomBarId]);
  }

  void clearPicked() {
    final ids = picked.keys.toList();
    picked.clear();
    for (final id in ids) {
      _writeField(id, 0);
    }
    update();
  }

  // Bulk add to cart

  /// Pushes every staged line to the server cart. The endpoint takes one item
  /// per call, so this loops — sequentially, because the backend recomputes
  /// the cart total on each hit.
  Future<void> addAllToCart() async {
    if (isAddingToCart) return;

    if (selectedParty?.partyid == null) {
      ShowMessage.showSnackBar('', 'Please select a company first');
      return;
    }
    if (picked.isEmpty) {
      ShowMessage.showSnackBar('', 'Enter a quantity for at least one item');
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
        final res = await callAddToCart(
          itemId: entry.item.itemid.toString(),
          itemRate: (entry.item.rate ?? 0).toInt().toString(),
          quantity: fmtQty(entry.qty),
          unitId: (entry.item.unitid ?? 0).toString(),
        );
        if (res.status == 200) {
          latestCartCount = res.data?.first.totalnumber ?? latestCartCount;
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
      final addedIds =
          picked.keys.where((id) => !failedIds.contains(id)).toList();
      for (final id in addedIds) {
        picked.remove(id);
        _writeField(id, 0);
      }

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
