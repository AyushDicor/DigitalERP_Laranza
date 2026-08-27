import 'dart:convert';

import 'package:digitalerp/app_routes/app_routes.dart';
import 'package:digitalerp/response/get_cart_list_response.dart';
import 'package:digitalerp/response/login_response.dart';
import 'package:digitalerp/screen/base/base_controller.dart';
import 'package:digitalerp/screen/ui/home/home_controller.dart';
import 'package:digitalerp/services/api_service/request_keys.dart';
import 'package:digitalerp/utils/offline_cart_list.dart';
import 'package:digitalerp/utils/shared_pre.dart';
import 'package:digitalerp/utils/show_message.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartController extends AppBaseController {
  final HomeController homeController = Get.find<HomeController>();

  final quantityTextController = TextEditingController();
  final quantityTextFocus = FocusNode();

  UserData? currentUserData;
  List<GetCartListData> cartList = [];
  List<GetCartListData> cartDeletedListItem = [];
  int? flag;
  bool isClearingCart = false;

  /// Local mirror of the cart used only by the old product screens to badge
  /// items as "in cart". It must always be a real list: this was previously a
  /// `late final` assigned only when the stored value was non-empty, so any
  /// cart built through a screen that does not write that key left it
  /// uninitialized and made [tapOnDelete] throw before it reached the API.
  List<OfflineCart> list = [];

  init() async {
    // TODO: implement onInit
    var obj = SharedPre.getObjs(SharedPre.userData) ?? {};
    currentUserData = UserData.fromJson(obj);
    getDetails();
    getOfflineList();

  }
  @override
  void onInit() {
    // TODO: implement onInit
    init();
    quantityTextFocus.addListener(() {
      if (!quantityTextFocus.hasFocus) {
        final index = cartList.indexWhere((e) => e.isTextField ?? false);
        if (index != -1) {
          onSubmitTextFieldQty(quantityTextController.text, index);
        }
      }
    });
    super.onInit();
  }

  void tapOnDelete(int index) async {
    if (index < 0 || index >= cartList.length) return;
    var item = cartList[index];

    /// Deleting must not depend on the local mirror — keeping it in sync is
    /// best-effort only, so a failure here can never stop the server call.
    try {
      list.removeWhere((element) => element.itemId == item.productid);
      await SharedPre.setValue(
          SharedPre.offlineCartList, json.encode(list));
    } catch (_) {}

    try {
      bool deleted = await removeFromCartAPI(itemId: item.id.toString());
      if (deleted) {
        cartList.removeAt(index);
        if (cartList.isEmpty) {
          await SharedPre.clear(SharedPre.offlineCartList);
        }
        homeController.itemInCart.value =
            homeController.itemInCart.value - 1 < 0
                ? 0
                : homeController.itemInCart.value - 1;
        getDetails();
        update();
      }
    } catch (e) {
      /// Previously this whole method was a fire-and-forget `async` with no
      /// guard, so any throw disappeared and the row simply never went away.
      ShowMessage.showSnackBar('', 'Could not remove item: $e');
    }
  }

  /// Empties the whole cart. The server cart is per user and persists across
  /// sessions until an order is placed, so stale items from an earlier session
  /// otherwise have to be deleted one row at a time. Always confirmed first —
  /// removals cannot be undone.
  Future<void> tapOnClearAll() async {
    if (cartList.isEmpty || isClearingCart) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Empty cart?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This removes all ${cartList.length} item(s) from your cart. '
          'It cannot be undone.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Empty cart',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    isClearingCart = true;
    update();

    /// The API removes one row per call, so this loops over a snapshot.
    final rows = List<GetCartListData>.from(cartList);
    int failed = 0;
    for (final row in rows) {
      try {
        final ok = await removeFromCartAPI(itemId: row.id.toString());
        if (!ok) failed++;
      } catch (_) {
        failed++;
      }
    }

    await SharedPre.clear(SharedPre.offlineCartList);
    list = [];
    isClearingCart = false;
    await getDetails();
    homeController.itemInCart.value = cartList.length;
    update();

    if (failed > 0) {
      ShowMessage.showSnackBar('', '$failed item(s) could not be removed');
    }
  }

  void tapOnProcess() {
    if (cartList.isNotEmpty) {
      Get.toNamed(AppRoutes.yourOrder);
    } else {
      ShowMessage.showSnackBar('', 'Cart List is Empty');
      backTap();
    }
  }

  Future<void> getOfflineList() async {
    final raw = await SharedPre.getStringValue(SharedPre.offlineCartList);
    if (raw.isEmpty) {
      list = [];
      return;
    }
    try {
      final decoded = json.decode(raw) as List;
      list = decoded
          .map((model) => OfflineCart.fromJson(model))
          .toList();
    } catch (_) {
      /// A malformed mirror must never block deleting from the cart.
      list = [];
    }
  }

  void tapOnProduct(String itemId) {
    Get.toNamed(AppRoutes.productDetails, arguments: itemId,);
  }

  void tapOnQuantityText(int index){
    for(var element in cartList){
      element.isTextField = false;
    }

    cartList[index].isTextField = true ;
    quantityTextController.text = (cartList[index].quantity?.toInt() ?? 1).toString();
    quantityTextController.selection = TextSelection(
        baseOffset: 0, extentOffset: quantityTextController.text.length);
    update();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => quantityTextFocus.requestFocus());
  }

  void productQtyDecrease(int index) {
    cartList[index].quantity = (cartList[index].quantity?.toInt() ?? 0) - 1;
    cartListLength = cartListLength! - 1;

    var item = cartList[index];
    flag = 0;
    updateCartAPI(item.id.toString(), cartList[index].quantity.toString());
    update();
  }

  void productQtyDecreaseFromTextField(int index) {
    //cartList[index].quantity = int.parse(quantityTextController.text) - 1;
    quantityTextController.text = (double.parse(quantityTextController.text) - 1).toString();
    var item = cartList[index];
    flag = 0;
    /*updateCartAPI(item.id.toString(), cartList[index].quantity.toString());

    update();*/
    update();
  }


  void productQtyIncrease(int index) {
    cartList[index].quantity = (cartList[index].quantity?.toInt() ?? 0) + 1;
    cartListLength = cartListLength! + 1;
    var item = cartList[index];
    flag = 1;
    updateCartAPI(item.id.toString(), cartList[index].quantity.toString());
    update();
  }

  void productQtyIncreaseFromTextField(int index) {
   // cartList[index].quantity = int.parse(quantityTextController.text) + 1;
    quantityTextController.text = (double.parse(quantityTextController.text) + 1).toString();
    var item = cartList[index];
    flag = 1;
    /*updateCartAPI(item.id.toString(), cartList[index].quantity.toString());
    update();*/
    update();
  }

 void onSubmitTextFieldQty(String qty, int index) async {
   if (!(cartList[index].isTextField ?? false)) return;
   final parsed = double.tryParse(qty);
   if (parsed != null && parsed > 0) {
     final item = cartList[index];
     final updated = await updateCartAPI(item.id.toString(), parsed.toString());
     if (updated) {
       cartList[index].quantity = parsed;
     }
   } else {
     ShowMessage.showSnackBar('MSG', 'QUANTITY MUST BE GRATER THEN 0');
   }
   cartList[index].isTextField = false;
   update();
 }


  Future<bool> updateCartAPI(String id, String qty) async {
    // UserData? currentUserData = await userDataController.getUserData;
    try {
      Map<String, String> body = {};
      body[RequestKeys.userId] = currentUserData?.userid?.toString() ?? '';
      body[RequestKeys.compId] = currentUserData?.compId?.toString() ?? '';
      body[RequestKeys.id] = id;
      body[RequestKeys.quantity] = qty;

      var res = await api.updateCart(body);
      if (res.status == 200) {
        ShowMessage.showSnackBar('', res.message.toString());

        getDetails();
        update();
        return true;
      } else {
        ShowMessage.showSnackBar('', '${res.message}');
        return false;
      }
    } catch (e) {
      ShowMessage.showSnackBar('', '$e');
      return false;
    } finally {}
  }

  Future<void> getDetails() async {
    setBusy(true);
    try {
      Map<String, String> body = {};
      body[RequestKeys.compId] = currentUserData!.compId.toString();
      body[RequestKeys.userId] = currentUserData!.userid.toString();
      var res = await api.getCartList(body);
      if (res.status == 200) {
        cartList = res.data ?? [];
        cartListLength = cartList.length;
        SharedPre.setValue(SharedPre.cartListLength, cartListLength);
      } else {
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      setBusy(false);
    }
  }
}
