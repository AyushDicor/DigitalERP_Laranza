class EmpOption {
  final String id;
  final String label;

  const EmpOption({required this.id, required this.label});

  /// Tolerant of the several key spellings the existing endpoints use.
  factory EmpOption.fromJson(Map<String, dynamic> j) => EmpOption(
        id: (j['id'] ??
                j['Id'] ??
                j['stateid'] ??
                j['cityid'] ??
                j['designnationid'] ??
                '')
            .toString(),
        label: (j['label'] ??
                j['Label'] ??
                j['name'] ??
                j['Name'] ??
                j['statename'] ??
                j['cityname'] ??
                j['designnation'] ??
                '')
            .toString(),
      );

  @override
  bool operator ==(Object other) => other is EmpOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class EmployeeMasterPayload {

  final int compId;
  final int branchId;
  final int userId;
  final String vendorId;
  final String vendorName;
  final String siteId;
  final String siteName;
  final String employeePhoto;
  final String employeeName;
  final String genderId;
  final String genderName;
  final String departmentId;
  final String departmentName;
  final String pfNo;
  final String esiNo;
  final String designationId;
  final String designationName;
  final String personalPhoneNo;
  final String dateOfJoining;
  final String dateOfBirth;
  final String salaryType;
  final String weekOff;
  final String otApplicable;
  final String workHoursMode;
  final String shiftId;
  final String shiftName;
  final String dailyWorkingHours;
  final String aadharCardNo;
  final String aadharCardFile;
  final String panCardNo;
  final String panCardFile;
  final String fullAddress;
  final String stateId;
  final String stateName;
  final String cityId;
  final String cityName;
  final String pincode;

  const EmployeeMasterPayload({
    required this.compId,
    required this.branchId,
    required this.userId,
    required this.vendorId,
    required this.vendorName,
    required this.siteId,
    required this.siteName,
    required this.employeePhoto,
    required this.employeeName,
    required this.genderId,
    required this.genderName,
    required this.departmentId,
    required this.departmentName,
    required this.pfNo,
    required this.esiNo,
    required this.designationId,
    required this.designationName,
    required this.personalPhoneNo,
    required this.dateOfJoining,
    required this.dateOfBirth,
    required this.salaryType,
    required this.weekOff,
    required this.otApplicable,
    required this.workHoursMode,
    required this.shiftId,
    required this.shiftName,
    required this.dailyWorkingHours,
    required this.aadharCardNo,
    required this.aadharCardFile,
    required this.panCardNo,
    required this.panCardFile,
    required this.fullAddress,
    required this.stateId,
    required this.stateName,
    required this.cityId,
    required this.cityName,
    required this.pincode,
  });

  Map<String, dynamic> toJson() => {
        'compid': compId,
        'branchid': branchId,
        'userid': userId,
        'vendorid': vendorId,
        'vendorname': vendorName,
        'siteid': siteId,
        'sitename': siteName,
        'name': employeeName,
        'genderid': genderId,
        'gender': genderName,
        'departmentid': departmentId,
        'designationid': designationId,
        'designation': designationName,
        'pfno': pfNo,
        'esino': esiNo,
        'mobile': personalPhoneNo,
        'joiningdate': dateOfJoining,
        'dob': dateOfBirth,
        'salarytype': salaryType,
        'weekoff': weekOff,
        'otapplicable': otApplicable,
        'shiftid': shiftId,
        'workinghours': dailyWorkingHours,
        'aadharno': aadharCardNo,
        'panno': panCardNo,
        'address': fullAddress,
        'stateid': stateId,
        'statename': stateName,
        'cityid': cityId,
        'cityname': cityName,
        'pincode': pincode,
      };
}
