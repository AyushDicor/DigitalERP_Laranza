// Declarative spec of the ERP Employee Master, laid out for mobile.
//
// The web ERP renders all ~150 fields as one long form. On mobile the same
// fields are split into 9 sections; each section is one page with its own
// View/Edit toggle and its own save call.
//
// Field `key`s mirror the ERP's own model/proc names (Models/Master/EmployeeMaster.cs
// and proc_EmployeeGeneralDetailsnew) so the backend can map them 1:1. Keys marked
// NEW below have no column in the current ERP model — they come from the web form
// screenshots and the backend is expected to add them.

import 'package:flutter/material.dart';

enum ErpFieldType {
  text,
  multiline,
  number,
  email,
  phone,
  date,
  dropdown,
  toggle,
  file,
}

class ErpField {
  const ErpField(
    this.key,
    this.label, {
    this.type = ErpFieldType.text,
    this.readOnly = false,
    this.lookup,
    this.idKey,
    this.options,
    this.dependsOn,
    this.hint,
  });

  final String key;
  final String label;
  final ErpFieldType type;

  /// Rendered as a value row even in edit mode (ERP/HR-controlled data).
  final bool readOnly;

  /// Name of the lookup list supplied by the lookups endpoint.
  final String? lookup;

  /// Companion id column the ERP stores alongside the display name
  /// (departmentname → department, permanentstate → permanentstateid).
  /// Set on selection so the save proc receives both.
  final String? idKey;

  /// Static fallback options, used when [lookup] returned nothing.
  final List<String>? options;

  /// For dependent dropdowns — key of the parent field (city depends on state).
  final String? dependsOn;

  final String? hint;

  /// Where the picked file's payload is stored on the working copy.
  String get base64Key => '${key}base64';
  String get fileNameKey => '${key}filename';
}

/// A titled run of fields inside a section (e.g. "Father" inside Family Details).
class ErpGroup {
  const ErpGroup({this.title, required this.fields});

  final String? title;
  final List<ErpField> fields;
}

/// A repeatable child list — the ERP form's "Add" button rows.
class ErpRepeatable {
  const ErpRepeatable({
    required this.listKey,
    required this.itemLabel,
    required this.titleKey,
    required this.fields,
    this.visibleWhenFlag,
  });

  /// Key on the profile holding the list of rows.
  final String listKey;

  /// Singular noun, used for the "Add ..." button and the card headers.
  final String itemLabel;

  /// Field key used as the card's heading.
  final String titleKey;

  final List<ErpField> fields;

  /// Only shown when this section field is checked (Employee Type → Experienced).
  final String? visibleWhenFlag;
}

class ErpSection {
  const ErpSection({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.groups,
    this.repeatable,
  });

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<ErpGroup> groups;
  final ErpRepeatable? repeatable;

  List<ErpField> get allFields =>
      groups.expand((g) => g.fields).toList(growable: false);
}

// Reusable field runs

/// Sections whose content is entirely a repeatable list carry no plain fields.
const List<ErpField> _noFields = [];

List<ErpField> _relativeFields(String prefix, String who) => [
      ErpField('${prefix}firstname', "$who's First Name"),
      ErpField('${prefix}lastname', "$who's Last Name"),
      ErpField('${prefix}phone', 'Phone Number', type: ErpFieldType.phone),
      ErpField('${prefix}profession', 'Profession'),
      ErpField('${prefix}adhaar', 'Aadhaar Number', type: ErpFieldType.number),
      ErpField('${prefix}pan', 'PAN Number'),
      ErpField('${prefix}imagepath', 'Photo', type: ErpFieldType.file),
    ];

List<ErpField> _addressFields(String prefix, {required bool present}) => [
      ErpField('${prefix}fulladdress', 'Full Address',
          type: ErpFieldType.multiline),
      ErpField('${prefix}state', 'State',
          type: ErpFieldType.dropdown,
          lookup: 'states',
          idKey: '${prefix}stateid'),
      ErpField('${prefix}city', 'City',
          type: ErpFieldType.dropdown,
          lookup: 'cities',
          idKey: '${prefix}cityid',
          dependsOn: '${prefix}state'),
      ErpField('${prefix}pincode', 'Pincode', type: ErpFieldType.number),
      ErpField('${prefix}addressproofpath', 'Address Proof',
          type: ErpFieldType.file),
      if (present) const ErpField('ownername', 'Owner Name'),
      ErpField(
        '${prefix}contactnumber',
        present
            ? 'Owner Contact Number (Emergency)'
            : 'Contact Number (Emergency)',
        type: ErpFieldType.phone,
      ),
    ];

// The 9 sections

class EmployeeProfileSpec {
  EmployeeProfileSpec._();

  static const String photoKey = 'employeephoto';
  static const String childrenListKey = 'items';
  static const String experienceListKey = 'experienceitems';

  static final List<ErpSection> sections = [
    // 1 — General Details
    ErpSection(
      key: 'general',
      title: 'General Details',
      subtitle: 'Name, ID, department and joining information',
      icon: Icons.badge_outlined,
      groups: [
        ErpGroup(fields: [
          const ErpField('firstname', 'First Name'),
          const ErpField('lastname', 'Last Name'),
          const ErpField('gender', 'Gender',
              type: ErpFieldType.dropdown,
              lookup: 'genders',
              idKey: 'genderid',
              options: ['Male', 'Female', 'Other']),
          const ErpField('employeeid', 'Employee ID', readOnly: true),
          const ErpField('departmentname', 'Department',
              type: ErpFieldType.dropdown,
              lookup: 'departments',
              idKey: 'department',
              readOnly: true),
          const ErpField('desginationname', 'Designation',
              type: ErpFieldType.dropdown,
              lookup: 'designations',
              idKey: 'desgination',
              readOnly: true),
          const ErpField('pfno', 'PF No', readOnly: true),
          const ErpField('esino', 'ESI No', readOnly: true),
          const ErpField('biometricid', 'Biometric ID', readOnly: true),
        ]),
        ErpGroup(title: 'Contact', fields: [
          const ErpField('companyemailid', 'Company Email ID',
              type: ErpFieldType.email),
          const ErpField('personalemailid', 'Personal Email ID',
              type: ErpFieldType.email),
          const ErpField('personalphone', 'Personal Phone Number',
              type: ErpFieldType.phone),
          const ErpField('alternativenumber', 'Alternate Number',
              type: ErpFieldType.phone),
        ]),
        ErpGroup(title: 'Employment', fields: [
          const ErpField('dob', 'Date of Birth', type: ErpFieldType.date),
          const ErpField('dateofjoining', 'Date of Joining',
              type: ErpFieldType.date, readOnly: true),
          const ErpField('placeofjoining', 'Place of Joining', readOnly: true),
          const ErpField('reqby', 'Reporting Person', readOnly: true),
          const ErpField('assestsissued', 'Assets Issued',
              type: ErpFieldType.multiline, readOnly: true),
          const ErpField('signaturepath', 'Signature',
              type: ErpFieldType.file),
          const ErpField('remarks', 'Remarks', type: ErpFieldType.multiline),
        ]),
      ],
    ),

    // 2 — Family Details
    ErpSection(
      key: 'family',
      title: 'Family Details',
      subtitle: 'Spouse, father and mother information',
      icon: Icons.family_restroom_outlined,
      groups: [
        ErpGroup(title: 'Spouse', fields: _relativeFields('spouse', 'Spouse')),
        ErpGroup(title: 'Father', fields: _relativeFields('father', 'Father')),
        ErpGroup(title: 'Mother', fields: _relativeFields('mother', 'Mother')),
        ErpGroup(title: 'Status', fields: [
          // NEW — present on the web form, no column in EmployeeMaster.cs yet.
          const ErpField('status', 'Status',
              type: ErpFieldType.dropdown, lookup: 'maritalstatus'),
          const ErpField('statusdate', 'Status Date', type: ErpFieldType.date),
        ]),
      ],
    ),

    // 3 — Reference Details
    ErpSection(
      key: 'references',
      title: 'Reference Details',
      subtitle: 'Two personal references',
      icon: Icons.groups_2_outlined,
      groups: [
        ErpGroup(title: 'Reference 1', fields: [
          const ErpField('reference1name', 'Name'),
          const ErpField('reference1phone', 'Phone Number',
              type: ErpFieldType.phone),
          const ErpField('reference1address', 'Address',
              type: ErpFieldType.multiline),
          const ErpField('reference1idproofpath', 'ID Proof',
              type: ErpFieldType.file),
        ]),
        ErpGroup(title: 'Reference 2', fields: [
          const ErpField('reference2name', 'Name'),
          const ErpField('reference2phone', 'Phone Number',
              type: ErpFieldType.phone),
          const ErpField('reference2address', 'Address',
              type: ErpFieldType.multiline),
          const ErpField('reference2idproofpath', 'ID Proof',
              type: ErpFieldType.file),
        ]),
      ],
    ),

    // 4 — Children Details
    ErpSection(
      key: 'children',
      title: 'Children Details',
      subtitle: 'Add one entry per child',
      icon: Icons.child_care_outlined,
      groups: const [ErpGroup(fields: _noFields)],
      repeatable: ErpRepeatable(
        listKey: childrenListKey,
        itemLabel: 'Child',
        titleKey: 'childname',
        fields: [
          ErpField('childname', 'Name'),
          ErpField('childgender', 'Gender',
              type: ErpFieldType.dropdown,
              lookup: 'genders',
              idKey: 'childgenderid',
              options: ['Male', 'Female', 'Other']),
          ErpField('childage', 'Age', type: ErpFieldType.number),
          ErpField('childeducation', 'Education'),
          ErpField('childaadharno', 'Aadhaar Number',
              type: ErpFieldType.number),
          ErpField('childpanno', 'PAN Number'),
          ErpField('childimagepath', 'Photo', type: ErpFieldType.file),
        ],
      ),
    ),

    // 5 — Employee Type
    ErpSection(
      key: 'employeetype',
      title: 'Employee Type',
      subtitle: 'Fresher or experienced, and past employment',
      icon: Icons.work_history_outlined,
      groups: [
        ErpGroup(fields: [
          const ErpField('experienced', 'Experienced',
              type: ErpFieldType.toggle),
          const ErpField('freshers', 'Fresher', type: ErpFieldType.toggle),
          // NEW — "Employee Nature" radio on the web form.
          const ErpField('employeenature', 'Employee Nature',
              type: ErpFieldType.dropdown,
              lookup: 'employeenature',
              options: ['SALARIED', 'IMPREST']),
        ]),
        ErpGroup(title: 'Previous employment summary', fields: [
          const ErpField('esideduction', 'ESI Deduction',
              type: ErpFieldType.dropdown,
              lookup: 'esideduction',
              idKey: 'esideductionid',
              options: ['Yes', 'No']),
          const ErpField('lastwithdrawalsalary', 'Last Withdrawn Salary',
              type: ErpFieldType.number),
        ]),
      ],
      repeatable: ErpRepeatable(
        listKey: experienceListKey,
        itemLabel: 'Organization',
        titleKey: 'organizationname',
        visibleWhenFlag: 'experienced',
        fields: [
          ErpField('organizationname', 'Organization Name'),
          ErpField('organizationwebsite', 'Organization Website'),
          ErpField('fromdate', 'From Date', type: ErpFieldType.date),
          ErpField('todate', 'To Date', type: ErpFieldType.date),
          ErpField('contactnumber', 'Contact Number', type: ErpFieldType.phone),
          ErpField('emloyeedepartment', 'Department'),
          ErpField('emloyeedesignation', 'Designation'),
          ErpField('workexperience', 'Work Experience'),
          ErpField('reasontoleaveprevious', 'Reason to Leave',
              type: ErpFieldType.multiline),
          ErpField('yourcomment', 'Your Comment', type: ErpFieldType.multiline),
        ],
      ),
    ),

    // 6 — Salary Details
    ErpSection(
      key: 'salary',
      title: 'Salary Details',
      subtitle: 'Payroll information (view only)',
      icon: Icons.payments_outlined,
      groups: [
        ErpGroup(fields: [
          const ErpField('basicsalary', 'Basic Salary',
              type: ErpFieldType.number, readOnly: true),
          const ErpField('effectform', 'Effect From', readOnly: true),
          const ErpField('grade', 'Grade', readOnly: true),
          // NEW — on the web form, not yet in EmployeeMaster.cs.
          const ErpField('incrementmonth', 'Increment Month', readOnly: true),
          const ErpField('incrementpercent', 'Increment %',
              type: ErpFieldType.number, readOnly: true),
        ]),
        ErpGroup(title: 'Location', fields: [
          const ErpField('latitude', 'Latitude', readOnly: true),
          const ErpField('longitude', 'Longitude', readOnly: true),
          const ErpField('distance', 'Distance', readOnly: true),
        ]),
      ],
    ),

    // 7 — Documents
    ErpSection(
      key: 'documents',
      title: 'Documents',
      subtitle: 'Identity and education documents',
      icon: Icons.folder_shared_outlined,
      groups: [
        ErpGroup(title: 'Identity documents', fields: [
          const ErpField('aadharcardnumber', 'Aadhaar Card No',
              type: ErpFieldType.number),
          const ErpField('aadharcardpath', 'Aadhaar Card',
              type: ErpFieldType.file),
          const ErpField('pancardnumber', 'PAN Card No'),
          const ErpField('pancardpath', 'PAN Card', type: ErpFieldType.file),
          const ErpField('drivinglicencenumber', 'Driving Licence No'),
          const ErpField('drivinglicencepath', 'Driving Licence',
              type: ErpFieldType.file),
          const ErpField('voteridcardnumber', 'Voter ID Card No'),
          const ErpField('voteridcardpath', 'Voter ID Card',
              type: ErpFieldType.file),
        ]),
        ErpGroup(title: 'Education documents', fields: [
          const ErpField('documentname', 'Document Name',
              type: ErpFieldType.dropdown,
              lookup: 'documentnames',
              idKey: 'documentnameid'),
          const ErpField('documentpath', 'Document', type: ErpFieldType.file),
        ]),
      ],
    ),

    // 8 — Bank Details
    ErpSection(
      key: 'bank',
      title: 'Bank Details',
      subtitle: 'Salary account information',
      icon: Icons.account_balance_outlined,
      groups: [
        ErpGroup(fields: [
          const ErpField('createbyorganization', 'Create by Organization',
              type: ErpFieldType.toggle),
          const ErpField('havealready', 'Have Already',
              type: ErpFieldType.toggle),
          const ErpField('bankname', 'Bank Name'),
          const ErpField('ifsccode', 'IFSC Code'),
          const ErpField('accountnumber', 'Account Number',
              type: ErpFieldType.number),
          const ErpField('holdername', 'Holder Name'),
          const ErpField('branchname', 'Branch Name'),
          const ErpField('accounttype', 'Account Type',
              type: ErpFieldType.dropdown,
              lookup: 'accounttypes',
              idKey: 'accounttypeid',
              options: ['Savings', 'Current']),
        ]),
      ],
    ),

    // 9 — Address Details
    ErpSection(
      key: 'address',
      title: 'Address Details',
      subtitle: 'Permanent and present address',
      icon: Icons.location_on_outlined,
      groups: [
        ErpGroup(
          title: 'Permanent Address',
          fields: _addressFields('permanent', present: false),
        ),
        ErpGroup(
          title: 'Present Address',
          fields: _addressFields('present', present: true),
        ),
      ],
    ),
  ];

  static ErpSection byKey(String key) =>
      sections.firstWhere((s) => s.key == key, orElse: () => sections.first);
}
