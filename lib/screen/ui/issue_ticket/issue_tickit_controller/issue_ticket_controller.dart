import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:digitalerp/model/get_tickit_list_issue_response_model.dart';
import 'package:digitalerp/model/issue_type_response_model.dart';
import 'package:digitalerp/model/module_response_model.dart';
import 'package:digitalerp/model/organization_response_model.dart';
import 'package:digitalerp/model/related_servies_response_model.dart';
import 'package:digitalerp/model/user_name_response_model.dart';
import 'package:digitalerp/repo/create_issue_ticket_repo.dart';
import 'package:digitalerp/screen/ui/home/home_controller.dart';
import 'package:digitalerp/utils/app_constant.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ticket_list_screen.dart';

class CreateIssueTicketController extends GetxController {
  HomeController homeController = Get.find<HomeController>();
  bool isLoading = false;

  var fetchOrganizationList = <OrganziatonList>[];
  List<PlatformFile> selectedFiles = [];
  OrganizationResponseModel? organizationResponseModel;
  OrganziatonList? selectedCompany;
  UserNameData? selectedUser;
  IssueTypeData? selectedIssueType;
  RelatedServicesList? relatedServicesList;
  ModuleDropdowns? moduleDropdownList;
  String? selectedService;
  String? selectedModule;
  var userNameDataList = <UserNameData>[];
  UserNameResponseModel? userNameResponseModel;
  RelatedServicesResponseModel? relatedServicesResponseModel;
  ModuleDropdownResponseModel? moduleDropdownResponseModel;
  final subjectController = TextEditingController();
  final descriptionController = TextEditingController();
  final nameController = TextEditingController();
  List<String>? selectedFileList;
  List<RelatedServicesList> relatedServicesDataList = [];
  List<ModuleDropdowns> moduleDropdownDataList = [];

  Future<void> organizationApi() async {
    try {
      isLoading = true;

      final requestData = {
        "compid": homeController.currentUserData!.compId.toString(),
        "branchid": homeController.currentUserData!.branchId.toString(),
        "userid": homeController.currentUserData!.userid.toString()
      };

      log('requestData For organizationApi =================>>>>> $requestData');

      final result = await CreateIssueTicketRepo.organizationNameListMethod(requestData);
      log('result for organization=================>>>>>${result.statusCode}');

      if (result.statusCode == 200) {
        organizationResponseModel = OrganizationResponseModel.fromJson(result.data);
        fetchOrganizationList = organizationResponseModel?.data?.toList() ?? [];

        log('fetchOrganizationList =================>>>>> ${jsonEncode(fetchOrganizationList)}');

        if (fetchOrganizationList.length == 1 && selectedCompany == null) {
          selectedCompany = fetchOrganizationList.first;
          log('Auto-selected organization: ${selectedCompany?.orgname}');

          await relatedServicesFetchApi();
          await moduleDropdownApi();
        }
      } else {
        log("organizationApi error: ${result.message}");
      }

      update();
    } catch (e, s) {
      log("Error in organizationApi: $e", stackTrace: s);
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> moduleDropdownApi() async {
    try {
      isLoading = true;

      final requestData = {
        "compid": homeController.currentUserData!.compId.toString(),
        "branchid": homeController.currentUserData!.branchId.toString(),
        "clientid": selectedCompany?.orgid
      };
      log('requestData For moduleDropdownApi =================>>>>> $requestData');

      final result = await CreateIssueTicketRepo.moduleDropdownListMethod(requestData);

      if (result.statusCode == 200) {
        moduleDropdownResponseModel = ModuleDropdownResponseModel.fromJson(result.data);
        moduleDropdownDataList = moduleDropdownResponseModel!.data.toList();

        log('modulle name =================>>>>> ${jsonEncode(moduleDropdownDataList)}');
      } else {
        log("relatedServicesDataList error: ${result.message}");
      }
      update();
    } catch (e, s) {
      log("Error in relatedServicesDataList: $e", stackTrace: s);
    } finally {
      isLoading = false;
    }
    update();
  }

  Future<void> userNameApi() async {
    try {
      isLoading = true;

      final requestData = {
        "compid": homeController.currentUserData!.compId.toString(),
        "branchid": homeController.currentUserData!.branchId.toString(),
        "userid": homeController.currentUserData!.userid.toString()
      };

      log('requestData For userNameApi =================>>>>> $requestData');

      final result = await CreateIssueTicketRepo.userNameListMethod(requestData);

      if (result.statusCode == 200) {
        userNameResponseModel = UserNameResponseModel.fromJson(result.data);
        userNameDataList = userNameResponseModel?.data?.toList() ?? [];

        log('userNameDataList =================>>>>> ${jsonEncode(userNameDataList)}');
      } else {
        log("userNameApi error: ${result.message}");
      }
      update();
    } catch (e, s) {
      log("Error in userNameApi: $e", stackTrace: s);
    } finally {
      isLoading = false;
    }
    update();
  }

  List<IssueTypeData> fetchIssueTypeList = [];

  IssueTypeResponseModel? issueTypeResponseModel;

  Future<void> issueTypeApi() async {
    try {
      isLoading = true;

      final requestData = {"compid": homeController.currentUserData!.compId.toString()};
      log('requestData For userNameApi =================>>>>> $requestData');
      final result = await CreateIssueTicketRepo.issueTypeListMethod(requestData);
      if (result.statusCode == 200) {
        issueTypeResponseModel = IssueTypeResponseModel.fromJson(result.data);
        fetchIssueTypeList = issueTypeResponseModel?.data?.toList() ?? [];

        log('fetchIssueTypeList =================>>>>> ${jsonEncode(fetchIssueTypeList)}');
      } else {
        log("fetchIssueTypeList error: ${result.message}");
      }
      update();
    } catch (e, s) {
      log("Error in fetchIssueTypeList: $e", stackTrace: s);
    } finally {
      isLoading = false;
    }
    update();
  }

  Future<void> relatedServicesFetchApi() async {
    try {
      isLoading = true;

      final requestData = {
        "compid": homeController.currentUserData!.compId.toString(),
        "branchid": homeController.currentUserData!.branchId.toString(),
        "clientid": selectedCompany?.orgid
      };
      log('requestData For relatedServicesFetchApi =================>>>>> $requestData');

      final result = await CreateIssueTicketRepo.relatedServicesListMethod(requestData);

      if (result.statusCode == 200) {
        relatedServicesResponseModel = RelatedServicesResponseModel.fromJson(result.data);
        relatedServicesDataList = (relatedServicesResponseModel?.data ?? []).map((e) {
          e.servicename = (e.servicename ?? "").split("/").last;
          return e;
        }).toList();

        log('relatedServicesDataList =================>>>>> ${jsonEncode(relatedServicesDataList)}');
      } else {
        log("relatedServicesDataList error: ${result.message}");
      }
      update();
    } catch (e, s) {
      log("Error in relatedServicesDataList: $e", stackTrace: s);
    } finally {
      isLoading = false;
    }
    update();
  }

  Future<List<String>> convertFilesToBase64(List<File> files) async {
    List<String> base64Files = [];
    for (var file in files) {
      final bytes = await file.readAsBytes();
      String base64String = base64Encode(bytes);
      base64Files.add(base64String);
    }
    return base64Files;
  }

  final formKey = GlobalKey<FormState>();

  final instructionController = TextEditingController();
  final mobileController = TextEditingController();
  final customerNameController = TextEditingController();
  final userName = TextEditingController();
  void submitForm(context) {
    if (formKey.currentState!.validate()) {
      submitIssueTicket(context);
    }
  }

  @override
  void onInit() {
    super.onInit();
    filteredTickets = List.from(allIssueTicketList);
  }

  TextEditingController orgName = TextEditingController();

  Future<void> submitIssueTicket(context) async {
    try {
      isLoading = true;

      final requestData = {
        "complaining": 0,
        "orgId": selectedCompany?.orgid != null ? selectedCompany?.orgid ?? "" : 0,
        "orgName": orgName.text,
        // "orgName": selectedCompany?.orgname?.isNotEmpty ?? false ? selectedCompany?.orgname : "",
        "userId": homeController.currentUserData?.userid,
        // "userId": userName.text.isNotEmpty ? userName.text : homeController.currentUserData?.name ?? '',
        "mobile": mobileController.text.isNotEmpty
            ? mobileController.text
            : homeController.currentUserData?.mobile ?? '',
        "issueTypeId": selectedIssueType?.issuetypeid,
        "issueType": selectedIssueType?.issuetype,
        "servicesId": relatedServicesList?.serviceid,
        "serviceName": relatedServicesList?.servicename,
        // "servicesId": homeController.currentUserData!.compId == 68 ? 0 : relatedServicesList?.serviceid,
        // "serviceName": homeController.currentUserData!.compId == 68 ? 0 : relatedServicesList?.servicename,
        // "moduleId": homeController.currentUserData!.compId == 68 ? 0 : moduleDropdownList?.moduleid,
        // "moduleName": homeController.currentUserData!.compId == 68 ? 0 : moduleDropdownList?.modulename,
        "moduleId": 0,
        "moduleName": 0,
        "subject": subjectController.text,
        "complain": descriptionController.text,
        "files": selectedFileList,
        "extraRemark": instructionController.text,
        "compId": homeController.currentUserData!.compId.toString(),
        "branchId": homeController.currentUserData!.branchId.toString(),
      };
      log('requestData For submitIssueTicket =================>>>>> $requestData');

      final result = await CreateIssueTicketRepo.submitIssueTicketMethod(requestData);

      if (result.statusCode == 200) {
        relatedServicesResponseModel = RelatedServicesResponseModel.fromJson(result.data);
        relatedServicesDataList = (relatedServicesResponseModel?.data ?? []).map((e) {
          e.servicename = (e.servicename ?? "").split("/").last;
          return e;
        }).toList();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Issue ticket submitted successfully!',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            backgroundColor: purpleColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          getAllIssueTicketList();
        });
        Get.offAll(const TicketListScreen());
        log('relatedServicesDataList =================>>>>> ${jsonEncode(relatedServicesDataList)}');

        Get.back();
      } else {
        log("relatedServicesDataList error: ${result.message}");
      }
      update();
    } catch (e, s) {
      log("Error in relatedServicesDataList: $e", stackTrace: s);
    } finally {
      isLoading = false;
    }
    update();
  }

  GetTicketIssueResponseModel? getTicketIssueResponseModel;

  List<AllIsueTicketList> allIssueTicketList = [];
  List<AllIsueTicketList> filteredTickets = [];

  Future<void> getAllIssueTicketList() async {
    try {
      isLoading = true;

      final requestData = {
        "compid": homeController.currentUserData!.compId.toString(),
        "userid": homeController.currentUserData!.userid.toString()
      };
      log('requestData For getAllIssueTicketList =================>>>>> $requestData');

      final result = await CreateIssueTicketRepo.getAllTicKetList(requestData);

      if (result.statusCode == 200) {
        getTicketIssueResponseModel = GetTicketIssueResponseModel.fromJson(result.data);

        allIssueTicketList = getTicketIssueResponseModel?.data?.toList() ?? [];
        filteredTickets = List.from(allIssueTicketList);

        log('allIssueTicketList =================>>>>> ${jsonEncode(allIssueTicketList)}');
      } else {
        log("allIssueTicketList error: ${result.message}");
      }
      update();
    } catch (e, s) {
      log("Error in allIssueTicketList: $e", stackTrace: s);
    } finally {
      isLoading = false;
      update();
    }
  }

  String? validateUserName(String? value) {
    if (value == null || value.isEmpty) {
      return 'User Name is required';
    }

    return null;
  }

  Future<void> updateTicketEntryApi(BuildContext context, String? ticketNumber) async {
    try {
      isLoading = true;

      final requestData = {
        "feedback": feedbackController.text,
        "rate": rating,
        "ticketno": ticketNumber,
        "compid": homeController.currentUserData!.compId.toString()
      };

      log('requestData For updateTicketEntryApi =================>>>>> $requestData');

      final result = await CreateIssueTicketRepo.updateTicketEntryMethod(requestData);

      if (result.statusCode == 200) {
        Get.snackbar(
          "Success",
          "Feedback inserted successfully.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: blueColor,
          duration: Duration(seconds: 2),
        );
        Navigator.pop(context);
      } else {
        Get.snackbar(
          "Error",
          result.message ?? "Something went wrong",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: blueColor,
          duration: Duration(seconds: 3),
        );
      }
    } catch (e, s) {
      log("Error in updateTicketEntryApi: $e", stackTrace: s);
      Get.snackbar(
        "Exception",
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: blueColor,
        duration: Duration(seconds: 3),
      );
    } finally {
      isLoading = false;
      feedbackController.clear();
      rating = 0;
      update();
    }
  }

  double rating = 0;
  TextEditingController feedbackController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  void filterTickets(String query) {
    if (query.isEmpty) {
      filteredTickets = List.from(allIssueTicketList);
    } else {
      filteredTickets = allIssueTicketList.where((ticket) {
        return (ticket.complain?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (ticket.ticketNo?.toString().toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (ticket.customer?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (ticket.status?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    }
    update();
  }

  void applyFilter(String status, String fromDate, String toDate) {
    filteredTickets = allIssueTicketList.where((ticket) {
      bool statusMatch = status == 'All' || ticket.status == status;
      return statusMatch;
    }).toList();
    update();
  }
}
