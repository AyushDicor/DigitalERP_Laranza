// import 'dart:convert';
// import 'package:digitalerp/screen/base/base_controller.dart';
// import 'package:digitalerp/screen/ui/home/home_controller.dart';
// import 'package:digitalerp/utils/app_constant.dart';
// import 'package:digitalerp/utils/show_message.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:get/get.dart';
//
// class LeadManagementController extends AppBaseController {
//   HomeController homeController = Get.find<HomeController>();
//
//   //  Lead list (used by LeadManagementView) 
//   // Replace `dynamic` with your actual LeadData model once the API is wired up
//   List<dynamic> leadList = [];
//
//   //  Text controllers 
//   /// Lead entry
//   final TextEditingController leadNumberController = TextEditingController();
//   final TextEditingController requirementController = TextEditingController();
//   final TextEditingController companyNameController = TextEditingController();
//   final TextEditingController ownerNameController = TextEditingController();
//   final TextEditingController contactPersonController = TextEditingController();
//   final TextEditingController mobileNumberController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController alternateNumberController = TextEditingController();
//   final TextEditingController websiteController = TextEditingController();
//   final TextEditingController companyAddressController = TextEditingController();
//   final TextEditingController phoneNumberController = TextEditingController();
//   final TextEditingController businessNatureController = TextEditingController();
//
//   /// Followup details
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController specificationController = TextEditingController();
//   final TextEditingController remarksController = TextEditingController();
//   final TextEditingController followupTimeController = TextEditingController();
//   final TextEditingController remarkFollowController = TextEditingController();
//
//   //  Focus nodes 
//   /// Lead entry
//   final FocusNode leadNoFocus = FocusNode();
//   final FocusNode requirementFocus = FocusNode();
//   final FocusNode companyNameFocus = FocusNode();
//   final FocusNode ownerNameFocus = FocusNode();
//   final FocusNode contactPersonFocus = FocusNode();
//   final FocusNode mobileNoFocus = FocusNode();
//   final FocusNode alternateNoFocus = FocusNode();
//   final FocusNode emailIdFocus = FocusNode();
//   final FocusNode websiteFocus = FocusNode();
//   final FocusNode companyAddresFocus = FocusNode();
//   final FocusNode phoneFocus = FocusNode();
//   final FocusNode businessFocus = FocusNode();
//
//   /// Followup details
//   final FocusNode addressFocus = FocusNode();
//   final FocusNode specificationFocus = FocusNode();
//   final FocusNode remarkFocus = FocusNode();
//   final FocusNode followupTimeFocus = FocusNode();
//   final FocusNode remarkFollowupFocus = FocusNode();
//
//   //  Observable 
//   RxBool isCheck = false.obs;
//
//   void onChangeValue(var value) {
//     isCheck.value = value;
//   }
//
//   //  Date fields 
//   String selectDate = 'Lead Date';
//   void setSelectedDate(String value) {
//     selectDate = value;
//     update();
//   }
//
//   void clearSelectedDate() {
//     selectDate = 'Lead Date';
//     update();
//   }
//
//   String selectDatef = 'Entry Date';
//   void setSelectedDatef(String value) {
//     selectDatef = value;
//     update();
//   }
//
//   void clearSelected() {
//     selectDatef = 'Entry Date';
//     update();
//   }
//
//   String selectDate2 = 'Entry Date';
//   void setSelectedDate2(String value) {
//     selectDate2 = value;
//     update();
//   }
//
//   void clearSelected2() {
//     selectDate2 = 'Entry Date';
//     update();
//   }
//
//   //  Validation 
//
//   bool _isLeadValidate() {
//     if (leadNumberController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt.tr, AppString.pleaseEnterLeadNo.tr);
//       return false;
//     }
//     if (requirementController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterRequirementSpecification.tr);
//       return false;
//     }
//     if (companyNameController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterCompanyName.tr);
//       return false;
//     }
//     if (ownerNameController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterOwnerName.tr);
//       return false;
//     }
//     if (contactPersonController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterContactPersonTxt.tr);
//       return false;
//     }
//     if (mobileNumberController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterMobileTxt.tr);
//       return false;
//     }
//     if (mobileNumberController.text.trim().length != 10) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterValidMobileTxt.tr);
//       return false;
//     }
//     if (alternateNumberController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterAlternateMobileNo.tr);
//       return false;
//     }
//     // ✅ FIX: was checking mobileNumber twice — now checks alternateNumber length
//     if (alternateNumberController.text.trim().length != 10) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterValidMobileTxt.tr);
//       return false;
//     }
//     if (emailController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterEmailIdTxt.tr);
//       return false;
//     }
//     if (websiteController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterWebsite.tr);
//       return false;
//     }
//     if (companyAddressController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterCompanyAddress.tr);
//       return false;
//     }
//     if (phoneNumberController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterPhoneNo.tr);
//       return false;
//     }
//     if (businessNatureController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterBusinessNature.tr);
//       return false;
//     }
//     return true;
//   }
//
//   // ✅ FIX: Removed unreachable code that came after `return true` inside
//   // the nested block — the original had dead validation checks after that.
//   bool _isFollowupValidate() {
//     if (addressController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterAddress);
//       return false;
//     }
//     if (selectDatef == 'Entry Date') {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, 'Please Select Entry Date');
//       return false;
//     }
//     if (specificationController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt,
//           AppString.pleaseEnterRequirementSpecification);
//       return false;
//     }
//     if (remarksController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterRemark);
//       return false;
//     }
//     if (followupTimeController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterFollowupTime);
//       return false;
//     }
//     if (remarkFollowController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterRemark);
//       return false;
//     }
//     return true;
//   }
//
//   //  API calls 
//
//   void addleadApi() async {
//     unfocus();
//     setBusy(true);
//     if (_isLeadValidate()) {
//       try {
//         // TODO: populate body with actual field values
//         final Map<String, String> body = {};
//         final res = await api.addCompanyJson(json.encode(body));
//         if (res.status == 200) {
//           backTap();
//           ShowMessage.showSnackBar(
//               'Success', res.message.toString());
//         } else {
//           ShowMessage.showSnackBar(
//               'Error', res.message.toString());
//         }
//       } catch (e) {
//         ShowMessage.showSnackBar('Error', '$e');
//       } finally {
//         setBusy(false);
//       }
//     } else {
//       setBusy(false);
//     }
//   }
//
//   void followupDetailsApi() async {
//     unfocus();
//     setBusy(true);
//     if (_isFollowupValidate()) {
//       try {
//         // TODO: populate body with actual field values
//         final Map<String, String> body = {};
//         final res = await api.addCompanyJson(json.encode(body));
//         if (res.status == 200) {
//           backTap();
//           ShowMessage.showSnackBar(
//               'Success', res.message.toString());
//         } else {
//           ShowMessage.showSnackBar(
//               'Error', res.message.toString());
//         }
//       } catch (e) {
//         ShowMessage.showSnackBar('Error', '$e');
//       } finally {
//         setBusy(false);
//       }
//     } else {
//       setBusy(false);
//     }
//   }
//
//   //  Dispose 
//
//   @override
//   void onClose() {
//     // Lead entry controllers
//     leadNumberController.dispose();
//     requirementController.dispose();
//     companyNameController.dispose();
//     ownerNameController.dispose();
//     contactPersonController.dispose();
//     mobileNumberController.dispose();
//     emailController.dispose();
//     alternateNumberController.dispose();
//     websiteController.dispose();
//     companyAddressController.dispose();
//     phoneNumberController.dispose();
//     businessNatureController.dispose();
//     // Followup controllers
//     addressController.dispose();
//     specificationController.dispose();
//     remarksController.dispose();
//     followupTimeController.dispose();
//     remarkFollowController.dispose();
//     super.onClose();
//   }
// }

import 'dart:convert';
import 'dart:developer';

import 'package:digitalerp/model/getleadentry_response_model.dart';
import 'package:digitalerp/model/lead_sources_response_model.dart';
import 'package:digitalerp/repo/lead_management_repo.dart';
import 'package:digitalerp/response/area_data_response.dart';
import 'package:digitalerp/response/city_data_response.dart';
import 'package:digitalerp/response/state_data_response.dart';
import 'package:digitalerp/screen/base/base_controller.dart';
import 'package:digitalerp/screen/ui/home/home_controller.dart';
import 'package:digitalerp/services/api_service/request_keys.dart';
import 'package:digitalerp/utils/app_constant.dart';
import 'package:digitalerp/utils/show_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class LeadManagementController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();

  //  Lead list
  List<GetleadentryList> leadList = [];

  // ─────────────────────────────────────────────────────────────────────
  //  Lead entry dropdowns: State → City → Area (cascading) and Source.
  //  Previously these were `_DropdownRow` widgets in the view — a grey box
  //  with a chevron and no data, no state and no tap handler.
  // ─────────────────────────────────────────────────────────────────────
  List<StateDataList> stateList = [];
  List<CityDataList> cityList = [];
  List<AreaDataList> areaList = [];
  List<LeadSourcesData> sourceList = [];

  StateDataList? selectedState;
  CityDataList? selectedCity;
  AreaDataList? selectedArea;
  LeadSourcesData? selectedSource;

  bool isStateLoading = false;
  bool isCityLoading = false;
  bool isAreaLoading = false;

  @override
  void onInit() {
    super.onInit();
    getLeadList(); // ✅ FIX: fetch leads on init so the list is never null/empty
    getStateList();
    getSourceList();
  }

  //  State / City / Area

  Future<void> getStateList() async {
    isStateLoading = true;
    update();
    try {
      Map<String, String> body = {
        RequestKeys.compId: homeController.currentUserData?.compId.toString() ?? '',
      };
      var res = await api.getStateData(body);
      if (res.status == 200) stateList = res.data ?? [];
    } catch (e) {
      log('getStateList error: $e');
    } finally {
      isStateLoading = false;
      update();
    }
  }

  Future<void> onStateChanged(StateDataList? value) async {
    selectedState = value;
    // Changing State invalidates the City and Area beneath it.
    selectedCity = null;
    selectedArea = null;
    cityList = [];
    areaList = [];
    update();
    if (value?.stateid == null) return;
    await getCityList(value!.stateid.toString());
  }

  Future<void> getCityList(String stateId) async {
    isCityLoading = true;
    update();
    try {
      Map<String, String> body = {
        RequestKeys.compId: homeController.currentUserData?.compId.toString() ?? '',
        RequestKeys.stateId: stateId,
      };
      var res = await api.getCityData(body);
      // No `.first` auto-select here — that pattern crashes on a state with no
      // cities and silently applies a value the user never chose.
      if (res.status == 200) cityList = res.data ?? [];
    } catch (e) {
      log('getCityList error: $e');
    } finally {
      isCityLoading = false;
      update();
    }
  }

  Future<void> onCityChanged(CityDataList? value) async {
    selectedCity = value;
    selectedArea = null;
    areaList = [];
    update();
    if (value?.cityid == null) return;
    await getAreaList(value!.cityid.toString());
  }

  Future<void> getAreaList(String cityId) async {
    isAreaLoading = true;
    update();
    try {
      Map<String, String> body = {
        RequestKeys.compId: homeController.currentUserData?.compId.toString() ?? '',
        RequestKeys.cityId: cityId,
      };
      var res = await api.getAreaData(body);
      if (res.status == 200) areaList = res.data ?? [];
    } catch (e) {
      log('getAreaList error: $e');
    } finally {
      isAreaLoading = false;
      update();
    }
  }

  void onAreaChanged(AreaDataList? value) {
    selectedArea = value;
    update();
  }

  //  Source

  Future<void> getSourceList() async {
    try {
      final requestData = {
        "compid": homeController.currentUserData?.compId.toString() ?? '',
      };
      final result = await LeadManagementRepo.leadSourcesMethod(requestData);
      if (result.statusCode == 200 && result.data != null) {
        sourceList = LeadSourcesResponseModel.fromJson(result.data).data ?? [];
      }
    } catch (e) {
      log('getSourceList error: $e');
    }
    update();
  }

  void onSourceChanged(LeadSourcesData? value) {
    selectedSource = value;
    update();
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Lead LIST filter (client-side).
  //
  //  getleadentry/getleadentry accepts no filter parameters and returns only
  //  6 fields per lead — LeadEntryId, LeadName, CompanyName, MobileNo,
  //  LeadDate, Ageing. So those are the only things that can be filtered on.
  //  "Lead Type", "Status" and "Handler" are not in the list payload at all,
  //  which is why those dropdowns could never have worked.
  // ─────────────────────────────────────────────────────────────────────
  String? filterCompany;
  String? filterContact;
  DateTime? filterFromDate;
  DateTime? filterToDate;

  /// Distinct company names present in the loaded leads.
  List<String> get filterCompanyOptions {
    final s = leadList
        .map((e) => e.companyName.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return s;
  }

  /// Distinct contact names present in the loaded leads.
  List<String> get filterContactOptions {
    final s = leadList
        .map((e) => e.leadName.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return s;
  }

  bool get isLeadFilterActive =>
      filterCompany != null ||
      filterContact != null ||
      filterFromDate != null ||
      filterToDate != null;

  /// LeadDate arrives as dd-MM-yyyy.
  DateTime? _parseLeadDate(String raw) {
    final p = raw.split('-');
    if (p.length != 3) return null;
    return DateTime.tryParse('${p[2]}-${p[1]}-${p[0]}');
  }

  List<GetleadentryList> get filteredLeadList {
    return leadList.where((e) {
      if (filterCompany != null && e.companyName.trim() != filterCompany) {
        return false;
      }
      if (filterContact != null && e.leadName.trim() != filterContact) {
        return false;
      }
      if (filterFromDate != null || filterToDate != null) {
        final d = _parseLeadDate(e.leadDate);
        if (d == null) return false;
        if (filterFromDate != null && d.isBefore(filterFromDate!)) return false;
        if (filterToDate != null) {
          final end = DateTime(filterToDate!.year, filterToDate!.month,
              filterToDate!.day, 23, 59, 59);
          if (d.isAfter(end)) return false;
        }
      }
      return true;
    }).toList();
  }

  void setLeadFilterCompany(String? v) { filterCompany = v; update(); }
  void setLeadFilterContact(String? v) { filterContact = v; update(); }
  void setLeadFilterFromDate(DateTime? v) { filterFromDate = v; update(); }
  void setLeadFilterToDate(DateTime? v) { filterToDate = v; update(); }

  void resetLeadFilter() {
    filterCompany = null;
    filterContact = null;
    filterFromDate = null;
    filterToDate = null;
    update();
  }

  void clearLeadEntryDropdowns() {
    selectedState = null;
    selectedCity = null;
    selectedArea = null;
    selectedSource = null;
    cityList = [];
    areaList = [];
    update();
  }

  /// Fetch the lead list from the existing getleadentry endpoint.
  ///
  /// This used to be a placeholder that unconditionally set `leadList = []`,
  /// so the Lead Management list was permanently empty even though the data
  /// existed. `getleadentry/getleadentry` was already declared in base_url.dart
  /// but never called from anywhere — no new backend work was needed.
  void getLeadList() async {
    setBusy(true);
    try {
      final requestData = {
        "userId": homeController.currentUserData?.userid.toString() ?? '',
        "compId": homeController.currentUserData?.compId.toString() ?? '',
        "branchid": homeController.currentUserData?.branchId.toString() ?? '',
      };
      final result = await LeadManagementRepo.getLeadEntryMethod(requestData);
      if (result.statusCode == 200 && result.data != null) {
        final model = GetleadentryResponseModel.fromJson(result.data);
        leadList = model.data.toList();
      } else {
        leadList = [];
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      setBusy(false);
    }
  }

  //  Text controllers 
  /// Lead entry
  final TextEditingController leadNumberController = TextEditingController();
  final TextEditingController requirementController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController contactPersonController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController alternateNumberController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController companyAddressController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController businessNatureController = TextEditingController();

  /// Followup details
  final TextEditingController addressController = TextEditingController();
  final TextEditingController specificationController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController followupTimeController = TextEditingController();
  final TextEditingController remarkFollowController = TextEditingController();

  //  Focus nodes 
  final FocusNode leadNoFocus = FocusNode();
  final FocusNode requirementFocus = FocusNode();
  final FocusNode companyNameFocus = FocusNode();
  final FocusNode ownerNameFocus = FocusNode();
  final FocusNode contactPersonFocus = FocusNode();
  final FocusNode mobileNoFocus = FocusNode();
  final FocusNode alternateNoFocus = FocusNode();
  final FocusNode emailIdFocus = FocusNode();
  final FocusNode websiteFocus = FocusNode();
  final FocusNode companyAddresFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode businessFocus = FocusNode();
  final FocusNode addressFocus = FocusNode();
  final FocusNode specificationFocus = FocusNode();
  final FocusNode remarkFocus = FocusNode();
  final FocusNode followupTimeFocus = FocusNode();
  final FocusNode remarkFollowupFocus = FocusNode();

  //  Observables 
  RxBool isCheck = false.obs;

  void onChangeValue(var value) {
    isCheck.value = value;
  }

  //  Date fields 
  String selectDate = 'Lead Date';
  void setSelectedDate(String value) { selectDate = value; update(); }
  void clearSelectedDate() { selectDate = 'Lead Date'; update(); }

  String selectDatef = 'Entry Date';
  void setSelectedDatef(String value) { selectDatef = value; update(); }
  void clearSelected() { selectDatef = 'Entry Date'; update(); }

  String selectDate2 = 'Entry Date';
  void setSelectedDate2(String value) { selectDate2 = value; update(); }
  void clearSelected2() { selectDate2 = 'Entry Date'; update(); }

  //  Validation 
  bool _isLeadValidate() {
    if (leadNumberController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr, AppString.pleaseEnterLeadNo.tr);
      return false;
    }
    if (requirementController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr, AppString.pleaseEnterRequirementSpecification.tr);
      return false;
    }
    if (companyNameController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr, AppString.pleaseEnterCompanyName.tr);
      return false;
    }
    if (ownerNameController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr, AppString.pleaseEnterOwnerName.tr);
      return false;
    }
    if (contactPersonController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr, AppString.pleaseEnterContactPersonTxt.tr);
      return false;
    }
    if (mobileNumberController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr, AppString.pleaseEnterMobileTxt.tr);
      return false;
    }
    if (mobileNumberController.text.trim().length != 10) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr, AppString.pleaseEnterValidMobileTxt.tr);
      return false;
    }
    if (alternateNumberController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr, AppString.pleaseEnterAlternateMobileNo.tr);
      return false;
    }
    // ✅ FIX: was checking mobileNumber length twice — now correctly checks alternateNumber
    if (alternateNumberController.text.trim().length != 10) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr, AppString.pleaseEnterValidMobileTxt.tr);
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt, AppString.pleaseEnterEmailIdTxt.tr);
      return false;
    }
    if (websiteController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt, AppString.pleaseEnterWebsite.tr);
      return false;
    }
    if (companyAddressController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt, AppString.pleaseEnterCompanyAddress.tr);
      return false;
    }
    if (phoneNumberController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt, AppString.pleaseEnterPhoneNo.tr);
      return false;
    }
    if (businessNatureController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt, AppString.pleaseEnterBusinessNature.tr);
      return false;
    }
    return true;
  }

  bool _isFollowupValidate() {
    if (addressController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt, AppString.pleaseEnterAddress);
      return false;
    }
    if (selectDatef == 'Entry Date') {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt, 'Please Select Entry Date');
      return false;
    }
    if (specificationController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt, AppString.pleaseEnterRequirementSpecification);
      return false;
    }
    if (remarksController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt, AppString.pleaseEnterRemark);
      return false;
    }
    if (followupTimeController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt, AppString.pleaseEnterFollowupTime);
      return false;
    }
    if (remarkFollowController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(AppString.requiredFieldTxt, AppString.pleaseEnterRemark);
      return false;
    }
    return true;
  }

  //  API calls
  /// Save a new lead.
  ///
  /// This used to post an EMPTY body to `addCompanyJson` with a
  /// "TODO: populate body with actual field values" comment — so nothing the
  /// user typed was ever saved. It now posts the real form values to
  /// `leadentry/saveleadentry`, the same endpoint the lead edit screen uses.
  void addleadApi() async {
    unfocus();
    setBusy(true);
    if (_isLeadValidate()) {
      try {
        final String leadDate = (selectDate == 'Lead Date') ? '' : selectDate;
        final Map<String, dynamic> body = {
          "leadName": contactPersonController.text.trim(),
          "companyName": companyNameController.text.trim(),
          "ownerName": ownerNameController.text.trim(),
          "mobileNo": mobileNumberController.text.trim(),
          "alternateMobile": alternateNumberController.text.trim(),
          "phoneNo": phoneNumberController.text.trim(),
          "email": emailController.text.trim(),
          "website": websiteController.text.trim(),
          "address": companyAddressController.text.trim(),
          "businessNature": businessNatureController.text.trim(),
          "requirement": requirementController.text.trim(),
          "leadDate": leadDate,
          "sourceid": selectedSource?.sourceid ?? 0,
          "source": selectedSource?.sourcename ?? '',
          // NOTE: the lead record has no state/city/area columns yet — see
          // Leadedit/getlead, which returns only a free-text `address`. These
          // are sent so the module is ready the moment the backend adds them.
          "stateid": selectedState?.stateid ?? 0,
          "statename": selectedState?.statename ?? '',
          "cityid": selectedCity?.cityid ?? 0,
          "cityname": selectedCity?.cityname ?? '',
          "areaid": selectedArea?.areaid ?? 0,
          "areaname": selectedArea?.areaname ?? '',
          "compId": homeController.currentUserData?.compId,
          "branchId": homeController.currentUserData?.branchId,
          "userId": homeController.currentUserData?.userid,
          "yearId": homeController.currentUserData?.yearId,
        };
        log('addleadApi body => ${json.encode(body)}');
        final res = await LeadManagementRepo.saveLeadEntryMethod(body);
        if (res.statusCode == 200 && (res.data?["success"] == true)) {
          backTap();
          // ✅ Refresh the list after a successful add
          getLeadList();
          ShowMessage.showSnackBar('Success', res.data?["message"]?.toString() ?? 'Lead saved');
        } else {
          ShowMessage.showSnackBar(
              'Could not save lead', res.data?["message"]?.toString() ?? res.message.toString());
        }
      } catch (e) {
        ShowMessage.showSnackBar('Error', '$e');
      } finally {
        setBusy(false);
      }
    } else {
      setBusy(false);
    }
  }

  void followupDetailsApi() async {
    unfocus();
    setBusy(true);
    if (_isFollowupValidate()) {
      try {
        // TODO: populate body with actual field values
        final Map<String, String> body = {};
        final res = await api.addCompanyJson(json.encode(body));
        if (res.status == 200) {
          backTap();
          ShowMessage.showSnackBar('Success', res.message.toString());
        } else {
          ShowMessage.showSnackBar('Error', res.message.toString());
        }
      } catch (e) {
        ShowMessage.showSnackBar('Error', '$e');
      } finally {
        setBusy(false);
      }
    } else {
      setBusy(false);
    }
  }

  //  Dispose 
  @override
  void onClose() {
    leadNumberController.dispose();
    requirementController.dispose();
    companyNameController.dispose();
    ownerNameController.dispose();
    contactPersonController.dispose();
    mobileNumberController.dispose();
    emailController.dispose();
    alternateNumberController.dispose();
    websiteController.dispose();
    companyAddressController.dispose();
    phoneNumberController.dispose();
    businessNatureController.dispose();
    addressController.dispose();
    specificationController.dispose();
    remarksController.dispose();
    followupTimeController.dispose();
    remarkFollowController.dispose();
    super.onClose();
  }
}