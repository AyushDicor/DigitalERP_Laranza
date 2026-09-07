import 'package:digitalerp/app_routes/app_routes.dart';
import 'package:digitalerp/response/get_executive_dropdown_response.dart';
import 'package:digitalerp/screen/base/base_controller.dart';
import 'package:digitalerp/screen/ui/home/cart/your_order/your_order_controller.dart';
import 'package:digitalerp/utils/app_constant_new.dart';
import 'package:digitalerp/utils/show_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../../../../response/party_dropdown_list_response.dart';
import '../../../../../../services/api_service/request_keys.dart';
import '../../../home_controller.dart';

class SelectCompanyController extends AppBaseController {
  final YourOrderController yourOrderController = Get.find<YourOrderController>();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  final HomeController _homeController = Get.find<HomeController>();
  bool isManager = false;
  PartyDropdownData? partyData;

  /// Full list from the server, never mutated by searching.
  List<PartyDropdownData> companyList = [];

  /// What the list actually renders. The old code assigned search results back
  /// over [companyList], so each keystroke narrowed an already-narrowed list
  /// and only a full re-fetch could restore it.
  List<PartyDropdownData> filteredList = [];

  ExecutiveDropdownData? selectedDropdownValue;

  Position? currentPosition;

  /// Party id currently being geo-validated, so only that row shows a spinner.
  int? validatingPartyId;


  @override
  void onInit() async{
    // TODO: implement onInit
    getPartyList();

    /// Only needed for the geo-fence. Also wrapped because
    /// getUserCurrentPosition returns a Future.error when location is off,
    /// which in this un-guarded async onInit became an unhandled error.
    if (kEnforcePartyGeofence) {
      try {
        currentPosition = await getUserCurrentPosition();
      } catch (_) {
        currentPosition = null;
      }
    }
    super.onInit();

  }

  void tapOnCard(int index) {
    searchFocus.unfocus();
    update();

    /// Geo-fence disabled — see [kEnforcePartyGeofence]. No party in the ERP
    /// has coordinates, so the check rejected every customer.
    if (!kEnforcePartyGeofence) {
      if (index < 0 || index >= filteredList.length) return;
      yourOrderController.selectCompany = filteredList[index];
      yourOrderController.persistSelectedParty();
      yourOrderController.update();
      update();
      backTap();
      return;
    }

    checkCompanyLatLng(index);

    //checkCompanyValidate(index);


   // yourOrderController.selectCompany = companyList[index];
    //update();
    //backTap();
/*     if (companyList[index].isPending) {
      ShowMessage.showSnackBar(messageTxt, companyPendingTxt);
    } else {
      yourOrderController.selectCompany = companyList[index];
      backTap();
    }*/
  }
  void searchCompany(String value) {
    final query = value.trim().toLowerCase();
    filteredList = query.isEmpty
        ? List<PartyDropdownData>.from(companyList)
        : companyList
            .where((e) => (e.partyname ?? '').toLowerCase().contains(query))
            .toList();
    update();
  }

  void setDropdownValue(ExecutiveDropdownData value) {
    searchFocus.unfocus();
    selectedDropdownValue = value;
    update();
  }

  void tapOnAdd() {
    searchFocus.unfocus();
    Get.toNamed(AppRoutes.addCompany)?.then((value) {
      getPartyList();
    });
  }

  void getPartyList() async {
    try {
      isListLoading = true;
      Map<String, String> body = {};
      body[RequestKeys.compId] = _homeController.currentUserData?.compId.toString() ?? '39';
      body[RequestKeys.userId] = _homeController.currentUserData?.userid.toString() ?? '39';//424655.toString();
      body[RequestKeys.branchId] = _homeController.currentUserData?.branchId.toString() ?? '39';
      var res = await api.getPartyDropdownList(body);
      if (res.status == 200) {
        companyList = res.data ?? [];
        searchCompany(searchController.text);
        if (companyList.length > 1) {
          isManager = true;
        } else if (companyList.isNotEmpty) {
          partyData = companyList.first;
        }
        update();
      } else {
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
      isListLoading = false;
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      setBusy(false);
    }
  }
  void checkCompanyValidate(int index) async {
    try {
      isListLoading = true;
      Map<String, String> body = {};
      body[RequestKeys.compId] = _homeController.currentUserData?.compId.toString() ?? '39';
      body[RequestKeys.userId] = _homeController.currentUserData?.userid.toString() ?? '39';
      body[RequestKeys.partyId] = filteredList[index].partyid.toString();



      var res = await api.checkPartyValidation(body);
      if (res.status == 200) {
        if(res.success??true){
          yourOrderController.selectCompany = filteredList[index];
          update();
          backTap();
        }else{
          ShowMessage.showSnackBar('Server Res', res.message.toString());
        }

      } else {
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
      isListLoading = false;
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      setBusy(false);
    }
  }
  /// Indexes [filteredList], not [companyList] — after a search the two no
  /// longer line up and the old code selected whichever party happened to sit
  /// at that position in the unfiltered list.
  void checkCompanyLatLng(int index) async {
    if (index < 0 || index >= filteredList.length) return;
    final party = filteredList[index];
    validatingPartyId = party.partyid;
    update();
    try {
      Map<String, String> body = {};
      body[RequestKeys.compId] = _homeController.currentUserData?.compId.toString() ?? '39';
      body[RequestKeys.userId] = _homeController.currentUserData?.userid.toString() ?? '39';
      body[RequestKeys.partyId] = party.partyid.toString();
      body[RequestKeys.latitude] = currentPosition?.latitude.toString()??'0';
      body[RequestKeys.longitude] = currentPosition?.longitude.toString()??'0';
      var res = await api.matchPartyLatLng(body);
      if (res.status == 200) {
        if(res.success??true){
          yourOrderController.selectCompany = party;
          yourOrderController.persistSelectedParty();
          yourOrderController.update();
          update();
          backTap();
        }else{
          ShowMessage.showSnackBar('Server Res', res.message.toString());
        }

      } else {
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      validatingPartyId = null;
      update();
    }
  }


}

class CompanyData {
  String? name, companyCode, imageUrl, customerName;
  bool? isPending;

  CompanyData({this.name, this.companyCode, this.imageUrl, this.customerName, this.isPending});
}
