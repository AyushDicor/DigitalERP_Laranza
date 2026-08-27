import 'dart:convert';

import 'package:digitalerp/app_routes/app_routes.dart';
import 'package:digitalerp/response/employee_profile_response.dart';
import 'package:digitalerp/screen/base/base_controller.dart';
import 'package:digitalerp/screen/ui/home/home_controller.dart';
import 'package:digitalerp/services/api_service/request_keys.dart';
import 'package:digitalerp/utils/app_constant.dart';
import 'package:digitalerp/utils/shared_pre.dart';
import 'package:digitalerp/utils/show_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'employee_profile_fields.dart';

/// Overview screen of the Employee Master profile: photo + summary + the list
/// of the 9 sections. Each section is edited on its own page — see
/// [ProfileSectionController].
class ProfileController extends AppBaseController {
  final HomeController homeController = Get.find<HomeController>();

  // Kept so the legacy photo/name/email/address endpoint keeps working.
  final TextEditingController userTypeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final FocusNode userTypeFocus = FocusNode();
  final FocusNode nameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode addressFocus = FocusNode();

  final picker = ImagePicker();
  var selectedImage = ''.obs;
  var selectedImageBase64 = ''.obs;
  var selectedImageFileName = ''.obs;

  /// Full employee record. Never null — starts empty and is seeded from the
  /// login payload when the detail endpoint is unavailable.
  EmployeeProfile profile = EmployeeProfile();

  /// Dropdown lists keyed by lookup name ('departments', 'states', ...).
  Map<String, List<LookupItem>> lookups = {};

  /// True once the live detail endpoint has answered successfully. While false
  /// the screen shows what the login payload gave us and marks the rest empty.
  bool detailApiAvailable = false;

  @override
  void onInit() {
    init();
    super.onInit();
  }

  Future<void> init() async {
    final user = homeController.currentUserData;
    nameController.text = user?.name?.toString() ?? '';
    emailController.text = user?.email?.toString() ?? '';
    addressController.text = user?.address?.toString() ?? '';
    userTypeController.text = user?.usertype?.toString() ?? '';
    update();
    await loadProfile();
  }

  Map<String, String> get _identity {
    final user = homeController.currentUserData;
    return {
      RequestKeys.userId: user?.userid?.toString() ?? '',
      RequestKeys.compId: user?.compId?.toString() ?? '',
    };
  }

  Future<void> loadProfile({bool showLoader = true}) async {
    if (showLoader) setBusy(true);
    try {
      final res = await api.getEmployeeProfile(json.encode(_identity));
      if (res.status == 200 && res.data != null && !res.data!.isEmpty) {
        profile = res.data!;
        detailApiAvailable = true;
      } else {
        detailApiAvailable = false;
      }
    } catch (_) {
      detailApiAvailable = false;
    }
    _seedFromLoginData();
    await _loadLookups();
    setBusy(false);
  }

  /// Everything the login response already knows, so the screen is useful even
  /// before the Employee Master endpoint exists.
  void _seedFromLoginData() {
    final user = homeController.currentUserData;
    if (user == null) return;

    final name = user.name?.toString().trim() ?? '';
    if (name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      profile.setIfEmpty('firstname', parts.first);
      if (parts.length > 1) {
        profile.setIfEmpty('lastname', parts.sublist(1).join(' '));
      }
    }
    profile.setIfEmpty('fullname', name);
    profile.setIfEmpty('companyemailid', user.email);
    profile.setIfEmpty('permanentfulladdress', user.address);
    profile.setIfEmpty('personalphone', user.mobile);
    profile.setIfEmpty(EmployeeProfileSpec.photoKey, user.photo);
    profile.setIfEmpty('usertype', user.usertype);
  }

  Future<void> _loadLookups() async {
    try {
      final res = await api.getEmployeeProfileLookups(json.encode(_identity));
      if (res.status == 200 && res.data.isNotEmpty) {
        lookups = res.data;
      }
    } catch (_) {
      // Dropdowns fall back to free text — see ProfileSectionController.
    }
  }

  // Header values

  String get displayName {
    final full = profile.str('fullname');
    if (full.isNotEmpty) return full;
    final composed =
        '${profile.str('firstname')} ${profile.str('lastname')}'.trim();
    if (composed.isNotEmpty) return composed;
    return homeController.currentUserData?.name?.toString() ?? '';
  }

  /// "Designation · Department", falling back to the login user type.
  String get roleLine {
    final parts = [
      profile.str('desginationname'),
      profile.str('departmentname'),
    ].where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) {
      return homeController.currentUserData?.usertype?.toString() ?? '';
    }
    return parts.join('  ·  ');
  }

  String get employeeIdLine {
    final id = profile.str('employeeid');
    return id.isEmpty ? '' : 'Employee ID  $id';
  }

  String get photoUrl {
    final p = profile.str(EmployeeProfileSpec.photoKey);
    return p.isNotEmpty
        ? p
        : (homeController.currentUserData?.photo?.toString() ?? '');
  }

  // Section completion, shown on each overview tile

  int filledCount(ErpSection section) {
    if (section.repeatable != null) {
      return profile.list(section.repeatable!.listKey).length;
    }
    return section.allFields
        .where((f) => profile.str(f.key).isNotEmpty)
        .length;
  }

  int totalCount(ErpSection section) {
    if (section.repeatable != null) {
      return profile.list(section.repeatable!.listKey).length;
    }
    return section.allFields.length;
  }

  String sectionStatus(ErpSection section) {
    if (section.repeatable != null) {
      final n = filledCount(section);
      if (n == 0) return 'None added';
      return '$n ${n == 1 ? section.repeatable!.itemLabel : '${section.repeatable!.itemLabel}s'}';
    }
    final filled = filledCount(section);
    if (filled == 0) return 'Not filled';
    return '$filled of ${totalCount(section)} filled';
  }

  Future<void> openSection(ErpSection section) async {
    await Get.toNamed(AppRoutes.profileSection, arguments: section.key);
    // The section page edits a copy; pull the saved values back in.
    await loadProfile(showLoader: false);
    update();
  }

  // Profile photo

  void setSelectedImage(String value) {
    selectedImage.value = value;
    update();
  }

  /// Photo still goes through the existing, working UserProfile endpoint.
  Future<void> saveProfilePhoto() async {
    if (selectedImageBase64.value.isEmpty) return;
    setBusy(true);
    try {
      final user = homeController.currentUserData;
      final body = <String, String>{
        RequestKeys.userId: user?.userid?.toString() ?? '',
        RequestKeys.compId: user?.compId?.toString() ?? '',
        RequestKeys.name: nameController.text.trim(),
        RequestKeys.email: emailController.text.trim(),
        RequestKeys.address: addressController.text.trim(),
        RequestKeys.photo: selectedImageBase64.value,
        RequestKeys.filename: selectedImageFileName.value,
      };
      final res = await api.updateProfileJson(json.encode(body));
      if (res.status == 200) {
        ShowMessage.showSnackBar('Profile', 'Photo updated');
        SharedPre.setValue(SharedPre.userData, res.data?.toJson());
        homeController.currentUserData = await userDataController.getUserData;
        selectedImageBase64.value = '';
        selectedImageFileName.value = '';
        await loadProfile(showLoader: false);
      } else {
        ShowMessage.showSnackBar(
            AppString.somethingTxt, res.message?.toString() ?? '');
      }
    } catch (e) {
      ShowMessage.showSnackBar(AppString.somethingTxt, '$e');
    } finally {
      setBusy(false);
    }
  }
}
