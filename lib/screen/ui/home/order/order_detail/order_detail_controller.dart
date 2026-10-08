import 'dart:async';
import 'dart:io';

import 'package:digitalerp/response/order_detail_response.dart';
import 'package:digitalerp/response/party_balance_detail_response.dart';
import 'package:digitalerp/screen/base/base_controller.dart';
import 'package:digitalerp/screen/ui/home/home_controller.dart';
import 'package:digitalerp/screen/ui/home/order/order_controller.dart';
import 'package:digitalerp/services/api_service/request_keys.dart';
import 'package:digitalerp/utils/show_message.dart';
import 'package:dio/dio.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../response/order_detail_pdf_url_response.dart';
import '../../../../../utils/pdf converter/pdf_analysis_report.dart';

class OrderDetailController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();
  OrderController orderController = Get.find<OrderController>();
  String? orderId;
  OrderDetailData? orderDetailData;
  PdfData? orderDetailPdfDownload;
  PartyBalanceDetailData? partyBalanceDetailData;
  PdfReportAnalysisApi pdfReportAnalysisApi = PdfReportAnalysisApi();
  String? downloadUrl;

  /// File name for the saved/shared PDF, from the order number with the
  /// characters a file system will not take ("Laranza/02245/22-22" ->
  /// "Laranza-02245-22-22"). Falls back to the order id.
  String get _pdfFileName {
    final no = (orderDetailData?.orderno ?? '').trim();
    if (no.isEmpty) return 'Order-${orderId ?? ''}';
    return no.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
  }

  List<String> statusList = [
    'Approved',
    'Pending',
    'Rejected',
  ];
  String? selectedStatusValue = '';
  var dio = Dio();

  final isPressed = RxBool(false);

  @override
  void onInit() async {
    orderId = Get.arguments as String;
    getOrderDetail();
    getPartyBalanceDetail();
    // TODO: implement onInit
    super.onInit();
  }

  void setSelectedStatusValue(String? value) {
    selectedStatusValue = value;
    update();
    debugPrint("------${selectedStatusValue}--------");
  }

  Future<void> getAndShareOrderDetailPdf() async {
    try {
      isPressed.value = true;
      Map<String, String> body = {};
      body[RequestKeys.orderId] = orderId.toString();
      body[RequestKeys.compId] =
          homeController.currentUserData?.compId.toString() ?? '';
      var res = await api.getOrderDetailPdfUrl(body);
      if (res.status == 200) {
        orderDetailPdfDownload = res.data!.first;
        downloadUrl = orderDetailPdfDownload?.url ?? '';

        /// Opens the document on screen first, with Download and Share as
        /// separate actions. It used to go straight to the OS share sheet, so
        /// the only way to read your own order was to send it somewhere.
        isPressed.value = false;
        openPdfPreview(
          downloadUrl: downloadUrl ?? '',

          /// Named after the order, not a millisecond counter — this is the
          /// name the saved/shared file carries.
          pdfFileName: _pdfFileName,
          title: orderDetailData?.orderno ?? 'Order',
        );
        update();
      } else {
        ShowMessage.showSnackBar('Failed Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('catch Server Res', '$e');
    } finally {}

    /*final date = DateTime.now();
    final dueDate = date.add(Duration(days: 7));
    final invoice = orderDetailData;
    final pdfFile = await pdfReportAnalysisApi.generate(invoice!);

    Share.shareFiles([pdfFile.path]);*/

    //PdfApi.openFile(pdfFile ?? File(''));
  }

  Future<void> getOrderDetail() async {
    setBusy(true);
    try {
      Map<String, String> body = {};
      body[RequestKeys.orderId] = orderId.toString();
      body[RequestKeys.compId] =
          homeController.currentUserData?.compId.toString() ?? '';
      var res = await api.getOrderDetail(body);
      if (res.status == 200) {
        orderDetailData = res.data?.first;
        selectedStatusValue = orderDetailData?.orderstatus;
        update();
      } else {
        ShowMessage.showSnackBar('Failed Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('catch Server Res', '$e');
    } finally {
      setBusy(false);
    }
  }

  Future<void> getPartyBalanceDetail() async {
    setBusy(true);
    try {
      Map<String, String> body = {};
      body[RequestKeys.orderId] = orderId.toString();
      body[RequestKeys.compId] =
          homeController.currentUserData?.compId.toString() ?? '';
      var res = await api.getPartyBalanceDetail(body);

      if (res.status == 200) {
        partyBalanceDetailData = res.data?.first;
        update();
      } else {
        ShowMessage.showSnackBar('Failed Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('catch Server Res', '$e');
    } finally {
      setBusy(false);
    }
  }

  Future<void> updateOrderStatusApi(String status) async {
    try {
      Map<String, String> body = {};
      body[RequestKeys.orderId] = orderId ?? '2422';
      body[RequestKeys.compId] =
          homeController.currentUserData?.compId.toString() ?? '39';
      body[RequestKeys.orderStatus] = status;
      var res = await api.updateOrderStatusApi(body);
      if (res.status == 200) {
        ShowMessage.showSnackBar('Success Server Res', res.message.toString());
      } else {
        ShowMessage.showSnackBar('Failed Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('catch Server Res', '$e');
    } finally {}
  }

  /// True while the delete call is in flight, so the button can show progress
  /// and refuse a second tap.
  final isDeleting = false.obs;

  /// Whether this order may still be deleted — the ERP only allows it on the
  /// day the order was raised ("Only today order can be deleted").
  ///
  /// The server remains the authority; this just keeps the button off an order
  /// it would refuse, so the action is never offered and then denied. An
  /// `orderdate` that cannot be read leaves the button visible rather than
  /// silently removing a legitimate action — the server still decides.
  bool get canDelete {
    final raw = orderDetailData?.orderdate?.trim();
    if (raw == null || raw.isEmpty) return true;
    final on = _parseOrderDate(raw);
    if (on == null) return true;
    final now = DateTime.now();
    return on.year == now.year && on.month == now.month && on.day == now.day;
  }

  /// `orderdate` arrives as `dd-MM-yyyy` (e.g. "06-10-2026"). Parsed by hand
  /// rather than with DateFormat so a stray format cannot throw on a screen
  /// that is only trying to decide whether to show a button.
  static DateTime? _parseOrderDate(String raw) {
    final parts = raw.split(RegExp(r'[-/]'));
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }

  /// Deletes this order, after the caller has confirmed with the user.
  ///
  /// The ERP only allows it on the day the order was raised and answers
  /// "Only today order can be deleted" otherwise — that message is shown
  /// as-is rather than being second-guessed here, because the cut-off is the
  /// server's clock, not the phone's.
  ///
  /// On success the screen pops and the list behind it reloads, so a deleted
  /// order cannot be left on screen looking live.
  Future<void> deleteOrder() async {
    if (isDeleting.value) return;
    isDeleting.value = true;
    try {
      final user = homeController.currentUserData;
      Map<String, String> body = {};

      /// All four are required — the endpoint answers "Order not found" if
      /// any one is missing, even when the order exists.
      body[RequestKeys.orderId] = orderId ?? '';
      body[RequestKeys.compId] = user?.compId.toString() ?? '';
      body[RequestKeys.userId] = user?.userid.toString() ?? '';
      body[RequestKeys.branchId] = user?.branchId.toString() ?? '';

      var res = await api.deleteOrderApi(body);
      if (res.status == 200) {
        /// Refresh the list this screen was opened from before leaving, so the
        /// deleted order is gone from it too.
        orderController.getOrderList();

        /// Pop BEFORE the snackbar. `Get.back()` closes the topmost overlay,
        /// and a snackbar counts as one — showing it first left the user
        /// staring at the detail screen of an order that no longer exists.
        Get.back();
        ShowMessage.showSnackBar('Deleted', res.message.toString());
      } else {
        ShowMessage.showSnackBar('Not deleted', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Not deleted', '$e');
    } finally {
      isDeleting.value = false;
    }
  }

  Future<void> sharePdfFromUrl({
    required String url,
    String fileName = 'pdfFile',
  }) async {
    try {
      isPressed.value = true;

      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        throw Exception('Invalid URL: $url');
      }
      final safeName =
          '${fileName.replaceAll(RegExp(r"[^\w\-. ]+"), "_")}_${DateTime.now().millisecondsSinceEpoch}';

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        responseType: ResponseType.bytes,
        followRedirects: true,
        headers: {'Accept': 'application/pdf'},
        validateStatus: (s) => s != null && s >= 200 && s < 400,
      ));

      final res = await dio.getUri(
        uri,
        onReceiveProgress: (count, total) => showDownloadProgress(count, total),
      );

      final data = res.data;
      if (data == null) throw Exception('No data received.');
      final bytes =
          data is Uint8List ? data : Uint8List.fromList(List<int>.from(data));
      if (bytes.isEmpty) throw Exception('Downloaded file is empty.');

      // Share directly from memory (no storage permission required)
      final xfile = XFile.fromData(
        bytes,
        name: '$safeName.pdf',
        mimeType: 'application/pdf',
      );
      await Share.shareXFiles([xfile], text: safeName);
    } catch (e, st) {
      debugPrint('sharePdfFromUrl error: $e\n$st');
      ShowMessage.showSnackBar('PDF Share Error', e.toString());
    } finally {
      isPressed.value = false;
    }
  }
}
