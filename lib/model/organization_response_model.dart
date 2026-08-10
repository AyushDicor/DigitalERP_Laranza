import 'dart:convert';

OrganizationResponseModel organizationResponseModelFromJson(String str) =>
    OrganizationResponseModel.fromJson(json.decode(str));

String organizationResponseModelToJson(OrganizationResponseModel data) => json.encode(data.toJson());

class OrganizationResponseModel {
  bool? success;
  List<OrganziatonList>? data;
  String? message;
  int? status;

  OrganizationResponseModel({this.success, this.data, this.message, this.status});

  factory OrganizationResponseModel.fromJson(Map<String, dynamic> json) => OrganizationResponseModel(
    success: json["success"],
    data: json["data"] == null
        ? []
        : List<OrganziatonList>.from(json["data"]!.map((x) => OrganziatonList.fromJson(x))),
    message: json["message"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "message": message,
    "status": status,
  };
}

class OrganziatonList {
  String? orgname;
  int? orgid;

  OrganziatonList({this.orgname, this.orgid});

  factory OrganziatonList.fromJson(Map<String, dynamic> json) =>
      OrganziatonList(orgname: json["orgname"], orgid: json["orgid"]);

  Map<String, dynamic> toJson() => {"orgname": orgname, "orgid": orgid};
}
