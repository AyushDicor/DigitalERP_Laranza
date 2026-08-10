// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
//
// import 'package:digitalerp/model/issue_type_response_model.dart';
// import 'package:digitalerp/model/module_response_model.dart';
// import 'package:digitalerp/model/organization_response_model.dart';
// import 'package:digitalerp/model/related_servies_response_model.dart';
// import 'package:digitalerp/model/user_name_response_model.dart';
// import 'package:digitalerp/screen/ui/home/home_controller.dart';
// import 'package:digitalerp/screen/ui/issue_ticket/issue_tickit_controller/issue_ticket_controller.dart';
// import 'package:digitalerp/utils/app_constant.dart';
// import 'package:digitalerp/utils/app_drop_down.dart';
// import 'package:digitalerp/utils/file_attachment_wigets.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// import 'issue_tickit_controller/ticket_list_screen.dart';
//
// class IssueTicketForm extends StatefulWidget {
//   const IssueTicketForm({Key? key}) : super(key: key);
//
//   @override
//   State<IssueTicketForm> createState() => _IssueTicketFormState();
// }
//
// class _IssueTicketFormState extends State<IssueTicketForm> {
//   final CreateIssueTicketController controller = Get.put(CreateIssueTicketController());
//   HomeController homeController = Get.find<HomeController>();
//
//   @override
//   void initState() {
//     super.initState();
//     controller.organizationApi();
//     controller.userNameApi();
//     controller.issueTypeApi();
//     controller.relatedServicesFetchApi();
//   }
//
//   final List<String> _services = [
//     'Web Development',
//     'Mobile App',
//     'Database Management',
//     'Cloud Services',
//     'Technical Support',
//     'Training Services',
//   ];
//
//   final List<String> _modules = [
//     'User Management',
//     'Payment System',
//     'Reporting Module',
//     'Authentication',
//     'Dashboard',
//     'Settings',
//   ];
//
//   String? validateRequired(String? value, String fieldName) {
//     if (value == null || value.isEmpty) {
//       return '$fieldName is required';
//     }
//     return null;
//   }
//
//   String? _validateMobile(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Mobile number is required';
//     }
//     if (value.length < 10) {
//       return 'Please enter a valid mobile number';
//     }
//     return null;
//   }
//
//   String? _validateCustomer(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Customer Name is required';
//     }
//
//     return null;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<CreateIssueTicketController>(
//       builder: (controller) {
//         return Scaffold(
//           body: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [grTopColor, grBottomColor],
//               ),
//             ),
//             child: SafeArea(
//               child: Column(
//                 children: [
//                   // Header
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     child: Row(
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.1),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: IconButton(
//                             onPressed: () => Navigator.pop(context),
//                             icon: Icon(Icons.arrow_back_ios_new_rounded, color: purpleColor),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Text(
//                             'Create Issue Ticket',
//                             style: GoogleFonts.poppins(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   // Form Content
//                   Expanded(
//                     child: Container(
//                       margin: EdgeInsets.only(top: 20),
//                       decoration: BoxDecoration(
//                         color: lightGrey,
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(30),
//                           topRight: Radius.circular(30),
//                         ),
//                       ),
//                       child: Form(
//                         key: controller.formKey,
//                         child: ListView(
//                           padding: const EdgeInsets.all(24),
//                           children: [
//                             /*   // User Name
//                           CustomDropdown<int>(
//                             label: 'User Name',
//                             hint: 'Select user',
//                             value: controller.selectedUser?.userid, // use ID instead of object
//                             items: controller.userNameDataList
//                                 .where((u) => u.userid != null)
//                                 .map((u) => u.userid!)
//                                 .toList(),
//                             isRequired: true,
//                             displayText: (id) {
//                               final user = controller.userNameDataList.firstWhere(
//                                 (u) => u.userid == id,
//                                 orElse: () => UserNameData(userid: 0, username: ''),
//                               );
//                               return user.username ?? '';
//                             },
//                             onChanged: (id) {
//                               setState(() {
//                                 controller.selectedUser =
//                                     controller.userNameDataList.firstWhere((u) => u.userid == id);
//                               });
//                             },
//                             validator: (id) {
//                               final user = controller.userNameDataList.firstWhere(
//                                 (u) => u.userid == id,
//                                 orElse: () => UserNameData(userid: 0, username: ''),
//                               );
//                               return _validateRequired(user.username, 'User Name');
//                             },
//                           ),*/
//                             if (homeController.currentUserData?.usertype == "Admin") ...[
//                               CustomDropdown<int>(
//                                 label: 'Organization Name',
//                                 hint: 'Select organization Name',
//                                 // allow null if nothing selected yet
//                                 value: controller.selectedCompany?.orgid,
//                                 items: controller.fetchOrganizationList
//                                     .map((org) => org.orgid ?? 0) // convert null to 0 (or skip)
//                                     .toList(),
//                                 isRequired: true,
//                                 displayText: (id) {
//                                   final org = controller.fetchOrganizationList.firstWhere(
//                                     (o) => o.orgid == id,
//                                     orElse: () => OrganziatonList(orgid: 0, orgname: ''),
//                                   );
//                                   return org.orgname ?? '';
//                                 },
//                                 onChanged: (id) {
//                                   setState(() {
//                                     controller.selectedCompany =
//                                         controller.fetchOrganizationList.firstWhere((o) => o.orgid == id);
//                                     log(
//                                       'controller.selectedCompany=================>>>>>${jsonEncode(controller.selectedCompany)}',
//                                     );
//                                     controller.moduleDropdownApi();
//                                   });
//                                 },
//                                 validator: (id) {
//                                   final org = controller.fetchOrganizationList.firstWhere(
//                                     (o) => o.orgid == id,
//                                     orElse: () => OrganziatonList(orgid: 0, orgname: ''),
//                                   );
//                                   return validateRequired(org.orgname, 'Company/School Name');
//                                 },
//                               ),
//
//                               const SizedBox(height: 24),
//                               UserSearchField(),
//
//                               const SizedBox(height: 24),
//
//                               // Mobile No
//                               CustomTextField(
//                                 label: 'Mobile Number',
//                                 hint: 'Enter mobile number',
//                                 controller: controller.mobileController,
//                                 isRequired: true,
//                                 keyboardType: TextInputType.phone,
//                                 validator: (va) {
//                                   return _validateMobile(va);
//                                 },
//                               ),
//                               const SizedBox(height: 24),
//                             ],
//
//                             // Issue Type
//                             CustomDropdown<IssueTypeData>(
//                               label: 'Issue Type',
//                               hint: 'Select issue type',
//                               value: controller.selectedIssueType,
//                               items: controller.fetchIssueTypeList,
//                               isRequired: true,
//                               displayText: (item) => item.issuetype ?? '',
//                               onChanged: (value) => setState(() => controller.selectedIssueType = value),
//                               validator: (value) => validateRequired(value?.issuetype, 'Issue Type'),
//                             ),
//                             const SizedBox(height: 24),
//
//                             // Related Services,
//
//                             /*        if (homeController.currentUserData!.compId == 68)
//                             const SizedBox()
//                           else*/
//                             Column(
//                               children: [
//                                 CustomDropdown<RelatedServicesList>(
//                                   label: 'Related Services',
//                                   hint: 'Select related service',
//                                   value: controller.relatedServicesList,
//                                   items: controller.relatedServicesDataList,
//                                   isRequired: true,
//                                   displayText: (item) => item.servicename ?? "",
//                                   onChanged: (value) =>
//                                       setState(() => controller.relatedServicesList = value),
//                                   validator: (value) =>
//                                       validateRequired(value?.servicename, 'Related Services'),
//                                 ),
//                                 const SizedBox(height: 24),
//                               ],
//                             ),
//
//                             if (homeController.currentUserData!.compId == 68)
//                               const SizedBox()
//                             else
//                               Column(
//                                 children: [
//                                   CustomDropdown<ModuleDropdowns>(
//                                     label: 'Modules/Items',
//                                     hint: 'Select module or item',
//                                     value: controller.moduleDropdownDataList
//                                             .contains(controller.moduleDropdownList)
//                                         ? controller.moduleDropdownList
//                                         : null,
//                                     items: controller.moduleDropdownDataList,
//                                     isRequired: true,
//                                     displayText: (item) => item.modulename ?? "",
//                                     onChanged: (value) =>
//                                         setState(() => controller.moduleDropdownList = value),
//                                     validator: (value) =>
//                                         validateRequired(value?.modulename, 'Module Dropdowns'),
//                                   ),
//                                   const SizedBox(height: 24),
//                                 ],
//                               ),
//
//                             // Subject
//                             CustomTextField(
//                               label: 'Subject',
//                               hint: 'Enter issue subject',
//                               controller: controller.subjectController,
//                               isRequired: true,
//                               validator: (value) => validateRequired(value, 'Subject'),
//                             ),
//                             const SizedBox(height: 24),
//
//                             // Description
//                             CustomTextField(
//                               label: 'Description',
//                               hint: 'Describe the issue in detail...',
//                               controller: controller.descriptionController,
//                               isRequired: true,
//                               maxLines: 5,
//                               validator: (value) => validateRequired(value, 'Description'),
//                             ),
//                             const SizedBox(height: 24),
//
//                             // Attachments
//                             FileAttachmentWidget(
//                               label: 'Attachments',
//                               selectedFiles: controller.selectedFiles,
//                               onFilesSelected: (files) async {
//                                 final base64List = await controller.convertFilesToBase64(
//                                   files.map((f) => File(f.path!)).toList(),
//                                 );
//                                 controller.selectedFiles = files;
//                                 controller.selectedFileList = base64List;
//                                 controller.update();
//                                 log('Base64 Encoded Files ==================>>>>> ${controller.selectedFileList}');
//                               },
//                             ),
//                             const SizedBox(height: 24),
//
//                             CustomTextField(
//                               label: 'Any Special Instructions',
//                               hint: 'Enter any additional instructions or notes...',
//                               controller: controller.instructionController,
//                               maxLines: 3,
//                             ),
//                             const SizedBox(height: 32),
//
//                             Container(
//                               height: 56,
//                               decoration: BoxDecoration(
//                                 gradient: LinearGradient(
//                                   colors: [purpleColor, blueColor],
//                                 ),
//                                 borderRadius: BorderRadius.circular(16),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: purpleColor.withOpacity(0.3),
//                                     blurRadius: 12,
//                                     offset: const Offset(0, 4),
//                                   ),
//                                 ],
//                               ),
//                               child: ElevatedButton(
//                                 onPressed: () {
//                                   controller.submitForm(context);
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.transparent,
//                                   shadowColor: Colors.transparent,
//                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     const Icon(Icons.send_rounded, color: Colors.white, size: 20),
//                                     const SizedBox(width: 8),
//                                     Text(
//                                       'Submit Issue Ticket',
//                                       style: GoogleFonts.poppins(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 24),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// class UserSearchField extends StatefulWidget {
//   @override
//   State<UserSearchField> createState() => _UserSearchFieldState();
// }
//
// class _UserSearchFieldState extends State<UserSearchField> {
//   final _controller = TextEditingController();
//   List<UserNameData> filteredList = [];
//   UserNameData? selectedUser;
//   bool showSuggestions = false; // <-- Visibility variable
//   CreateIssueTicketController controller = Get.find<CreateIssueTicketController>();
//
//   @override
//   void initState() {
//     super.initState();
//     filteredList = controller.userNameDataList;
//   }
//
//   void _filterUsers(String query) {
//     filteredList = controller.userNameDataList
//         .where((u) => u.username != null && u.username!.toLowerCase().contains(query.toLowerCase()))
//         .toList();
//
//     setState(() {
//       showSuggestions = query.isNotEmpty; // Show list when typing
//       selectedUser = null; // Clear selection while typing
//     });
//   }
//
//   void _selectUser(UserNameData user) {
//     setState(() {
//       selectedUser = user;
//       _controller.text = user.username ?? '';
//       filteredList = controller.userNameDataList; // reset list
//       showSuggestions = false; // Hide list after selection
//     });
//     FocusScope.of(context).unfocus();
//   }
//
//   void _clearField() {
//     setState(() {
//       _controller.clear();
//       selectedUser = null;
//       filteredList = controller.userNameDataList;
//       showSuggestions = false; // Hide list
//     });
//   }
//
//   String? validateRequired(String? value, String fieldName) {
//     if (value == null || value.isEmpty) {
//       return '$fieldName is required';
//     }
//     return null;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         CustomTextField(
//           label: 'User Name',
//           hint: 'Enter user Name',
//           controller: _controller,
//           isRequired: true,
//           keyboardType: TextInputType.text,
//           validator: (value) => validateRequired(value, 'user Name'),
//           onChanged: (value) {
//             setState(() {
//               selectedUser = null;
//               _filterUsers(value);
//               showSuggestions = value.isNotEmpty;
//             });
//           },
//           inputDecoration: InputDecoration(
//             hintText: 'Enter user Name',
//             hintStyle: GoogleFonts.poppins(
//               fontSize: 14,
//               color: grey,
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 16,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: lightGrey),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: showSuggestions
//                   ? const BorderRadius.only(
//                       topLeft: Radius.circular(12),
//                       topRight: Radius.circular(12),
//                     )
//                   : BorderRadius.circular(12),
//               borderSide: const BorderSide(color: lightGrey),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: showSuggestions
//                   ? const BorderRadius.only(
//                       topLeft: Radius.circular(12),
//                       topRight: Radius.circular(12),
//                     )
//                   : BorderRadius.circular(12),
//               borderSide: const BorderSide(color: purpleColor, width: 1.5),
//             ),
//           ),
//         ),
//
//         // Suggestion list
//         if (showSuggestions)
//           Container(
//             decoration: BoxDecoration(
//               border: Border.all(color: purpleColor, width: 1.5),
//               borderRadius: const BorderRadius.only(
//                 bottomLeft: Radius.circular(12),
//                 bottomRight: Radius.circular(12),
//               ),
//               color: Colors.white,
//             ),
//             constraints: const BoxConstraints(maxHeight: 200),
//             child: filteredList.isNotEmpty
//                 ? ListView.separated(
//                     shrinkWrap: true,
//                     itemCount: filteredList.length,
//                     separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade500),
//                     itemBuilder: (context, index) {
//                       final user = filteredList[index];
//                       return ListTile(
//                         title: Text(
//                           user.username ?? '',
//                           style: const TextStyle(fontSize: 14),
//                         ),
//                         onTap: () => _selectUser(user),
//                       );
//                     },
//                   )
//                 : const Center(
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(vertical: 16),
//                       child: Text(
//                         'No users found',
//                         style: TextStyle(color: Colors.grey, fontSize: 14),
//                       ),
//                     ),
//                   ),
//           ),
//       ],
//     );
//   }
// }
import 'dart:developer';
import 'dart:io';

import 'package:digitalerp/model/issue_type_response_model.dart';
import 'package:digitalerp/model/organization_response_model.dart';
import 'package:digitalerp/model/related_servies_response_model.dart';
import 'package:digitalerp/model/user_name_response_model.dart';
import 'package:digitalerp/screen/ui/home/home_controller.dart';
import 'package:digitalerp/screen/ui/issue_ticket/issue_tickit_controller/issue_ticket_controller.dart';
import 'package:digitalerp/utils/app_constant_new.dart';
import 'package:digitalerp/utils/app_drop_down.dart';
import 'package:digitalerp/utils/file_attachment_wigets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IssueTicketForm extends StatefulWidget {
  const IssueTicketForm({Key? key}) : super(key: key);

  @override
  State<IssueTicketForm> createState() => _IssueTicketFormState();
}

class _IssueTicketFormState extends State<IssueTicketForm> {
  final CreateIssueTicketController controller =
      Get.put(CreateIssueTicketController());
  final HomeController homeController = Get.find<HomeController>();

  bool showValidation = false;

  @override
  void initState() {
    super.initState();
    // controller.organizationApi();
    controller.userNameApi();
    controller.issueTypeApi();
    controller.relatedServicesFetchApi();
  }

  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) return 'Mobile number is required';
    if (value.length < 10) return 'Please enter a valid mobile number';
    return null;
  }

  void _submitForm() {
    setState(() => showValidation = true);
    if (controller.formKey.currentState!.validate()) {
      controller.submitForm(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CreateIssueTicketController>(
      builder: (_) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios_new,
                            color: newTextPrimary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Create Issue Ticket',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: newTextPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Form(
                    key: controller.formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (homeController.currentUserData?.usertype ==
                            "Admin") ...[
                          OrganizationSearchField(
                            controllers: controller.orgName,
                            formKey: controller.formKey,
                            autovalidateMode: showValidation
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                          ),
                          const SizedBox(height: 24),
                          UserSearchField(
                            formKey: controller.formKey,
                            autovalidateMode: showValidation
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                          ),
                          const SizedBox(height: 24),
                          CustomTextField(
                            autovalidateMode: showValidation
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                            label: 'Mobile Number',
                            hint: 'Enter mobile number',
                            controller: controller.mobileController,
                            isRequired: true,
                            keyboardType: TextInputType.phone,
                            validator: _validateMobile,
                          ),
                          const SizedBox(height: 24),
                        ],
                        CustomDropdown<int>(
                          autovalidateMode: showValidation
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          label: 'Issue Type',
                          hint: 'Select issue type',
                          value: controller.selectedIssueType?.issuetypeid,
                          items: controller.fetchIssueTypeList
                              .map((e) => e.issuetypeid ?? 0)
                              .toList(),
                          isRequired: true,
                          displayText: (id) {
                            final issue =
                                controller.fetchIssueTypeList.firstWhere(
                              (e) => e.issuetypeid == id,
                              orElse: () =>
                                  IssueTypeData(issuetype: '', issuetypeid: 0),
                            );
                            return issue.issuetype ?? '';
                          },
                          onChanged: (id) {
                            setState(() {
                              controller.selectedIssueType = controller
                                  .fetchIssueTypeList
                                  .firstWhere((e) => e.issuetypeid == id);
                            });
                          },
                          validator: (id) {
                            final issue =
                                controller.fetchIssueTypeList.firstWhere(
                              (e) => e.issuetypeid == id,
                              orElse: () =>
                                  IssueTypeData(issuetype: '', issuetypeid: 0),
                            );
                            return validateRequired(
                                issue.issuetype, 'Issue Type');
                          },
                        ),
                        const SizedBox(height: 24),
                        CustomDropdown<int>(
                          autovalidateMode: showValidation
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          label: 'Related Services',
                          hint: 'Select related service',
                          value: controller.relatedServicesDataList.any((e) =>
                                  e.serviceid ==
                                  controller.relatedServicesList?.serviceid)
                              ? controller.relatedServicesList?.serviceid
                              : null,
                          items: controller.relatedServicesDataList
                              .map((e) => e.serviceid ?? 0)
                              .toSet()
                              .toList(),
                          isRequired: true,
                          displayText: (id) {
                            final service =
                                controller.relatedServicesDataList.firstWhere(
                              (e) => e.serviceid == id,
                              orElse: () => RelatedServicesList(
                                  serviceid: 0, servicename: ''),
                            );
                            return service.servicename ?? '';
                          },
                          onChanged: (id) {
                            setState(() {
                              controller.relatedServicesList =
                                  controller.relatedServicesDataList.firstWhere(
                                (e) => e.serviceid == id,
                                orElse: () => RelatedServicesList(
                                    serviceid: 0, servicename: ''),
                              );
                            });
                          },
                          validator: (id) {
                            final service =
                                controller.relatedServicesDataList.firstWhere(
                              (e) => e.serviceid == id,
                              orElse: () => RelatedServicesList(
                                  serviceid: 0, servicename: ''),
                            );
                            return validateRequired(
                                service.servicename, 'Related Services');
                          },
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          autovalidateMode: showValidation
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          label: 'Subject',
                          hint: 'Enter issue subject',
                          controller: controller.subjectController,
                          isRequired: true,
                          validator: (value) =>
                              validateRequired(value, 'Subject'),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          autovalidateMode: showValidation
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          label: 'Description',
                          hint: 'Describe the issue in detail...',
                          controller: controller.descriptionController,
                          isRequired: true,
                          maxLines: 5,
                          validator: (value) =>
                              validateRequired(value, 'Description'),
                        ),
                        const SizedBox(height: 24),
                        FileAttachmentWidget(
                          label: 'Attachments',
                          selectedFiles: controller.selectedFiles,
                          onFilesSelected: (files) async {
                            final base64List =
                                await controller.convertFilesToBase64(
                              files.map((f) => File(f.path!)).toList(),
                            );
                            controller.selectedFiles = files;
                            controller.selectedFileList = base64List;
                            controller.update();
                            log('Base64 Encoded Files: ${controller.selectedFileList}');
                          },
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          autovalidateMode: showValidation
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          label: 'Any Special Instructions',
                          hint: 'Enter any additional instructions or notes...',
                          controller: controller.instructionController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: newBlueColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Submit Issue Ticket',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------- UserSearchField ----------------------

class UserSearchField extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final AutovalidateMode? autovalidateMode;

  const UserSearchField({
    Key? key,
    required this.formKey,
    this.autovalidateMode,
  }) : super(key: key);

  @override
  State<UserSearchField> createState() => _UserSearchFieldState();
}

class _UserSearchFieldState extends State<UserSearchField> {
  final CreateIssueTicketController controller =
      Get.find<CreateIssueTicketController>();
  late final TextEditingController _controller;

  List<UserNameData> filteredList = [];
  bool showSuggestions = false;
  bool showValidation = false;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: controller.selectedUser?.username ?? '');
    filteredList = controller.userNameDataList;
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      filteredList = controller.userNameDataList;
      showSuggestions = false;
      controller.selectedUser = null;
    } else {
      filteredList = controller.userNameDataList
          .where((u) =>
              u.username != null &&
              u.username!.toLowerCase().contains(query.toLowerCase()))
          .toList();

      showSuggestions = filteredList.isNotEmpty;
      controller.selectedUser = null;
    }

    setState(() {
      showValidation = true;
    });
  }

  void _selectUser(UserNameData user) {
    setState(() {
      controller.selectedUser = user;
      _controller.text = user.username ?? '';
      showSuggestions = false;
      filteredList = controller.userNameDataList;
      showValidation = true;
    });
    FocusScope.of(context).unfocus();
    widget.formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          autovalidateMode: widget.autovalidateMode ??
              (showValidation
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled),
          label: 'User Name',
          hint: 'Enter user Name',
          controller: _controller,
          isRequired: true,
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) return 'User Name is required';
            if (controller.selectedUser == null ||
                controller.selectedUser!.username != value) {
              return 'Please select a valid user from the list';
            }
            return null;
          },
          onChanged: _filterUsers,
        ),
        if (showSuggestions)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: newBlueColor, width: 1.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              color: Colors.white,
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: filteredList.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final user = filteredList[index];
                      return ListTile(
                        title: Text(user.username ?? '',
                            style: const TextStyle(fontSize: 14)),
                        onTap: () => _selectUser(user),
                      );
                    },
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No users found',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

class OrganizationSearchField extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final AutovalidateMode? autovalidateMode;
  final TextEditingController controllers;

  const OrganizationSearchField({
    Key? key,
    required this.formKey,
    this.autovalidateMode,
    required this.controllers,
  }) : super(key: key);

  @override
  State<OrganizationSearchField> createState() =>
      _OrganizationSearchFieldState();
}

class _OrganizationSearchFieldState extends State<OrganizationSearchField> {
  final CreateIssueTicketController controller =
      Get.find<CreateIssueTicketController>();

  bool showValidation = false;
  bool showSuggestions = false;
  List<OrganziatonList> filteredList = [];

  @override
  void initState() {
    super.initState();

    controller.organizationApi().then((_) {
      if (controller.fetchOrganizationList.length == 1 &&
          controller.selectedCompany == null) {
        final org = controller.fetchOrganizationList.first;
        controller.selectedCompany = org;
        controller.relatedServicesFetchApi();
        controller.moduleDropdownApi();

        widget.controllers.text = org.orgname ?? '';
        setState(() {
          showSuggestions = false;
        });
      }
    });
  }

  void _filterOrganizations(String query) {
    final matches = controller.fetchOrganizationList
        .where((o) =>
            o.orgname != null &&
            o.orgname!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      filteredList = matches;
      showSuggestions = matches.isNotEmpty && query.isNotEmpty;
      controller.selectedCompany = null;
      showValidation = true;
    });
  }

  void _selectOrganization(OrganziatonList org) {
    setState(() {
      controller.selectedCompany = org;
      widget.controllers.text = org.orgname ?? '';
      showSuggestions = false;
    });

    FocusScope.of(context).unfocus();
    widget.formKey.currentState?.validate();
    controller.relatedServicesFetchApi();
    controller.moduleDropdownApi();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CreateIssueTicketController>(
      builder: (_) {
        if (controller.selectedCompany != null &&
            widget.controllers.text.isEmpty) {
          widget.controllers.text = controller.selectedCompany!.orgname ?? '';
          widget.controllers.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controllers.text.length),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: widget.controllers,
              onChanged: _filterOrganizations,
              label: 'Organization Name',
              hint: 'Enter organization name',
              autovalidateMode: widget.autovalidateMode ??
                  (showValidation
                      ? AutovalidateMode.always
                      : AutovalidateMode.disabled),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Organization Name is required';
                if (controller.selectedCompany == null ||
                    controller.selectedCompany!.orgname != value)
                  return 'Please select a valid organization from the list';
                return null;
              },
              isRequired: true,
            ),
            if (showSuggestions && filteredList.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: newBlueColor, width: 1.2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  color: Colors.white,
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final org = filteredList[index];
                    return ListTile(
                      dense: true,
                      title: Text(org.orgname ?? '',
                          style: const TextStyle(fontSize: 14)),
                      onTap: () => _selectOrganization(org),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
