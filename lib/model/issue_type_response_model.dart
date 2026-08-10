import 'dart:convert';

IssueTypeResponseModel issueTypeResponseModelFromJson(String str) =>
    IssueTypeResponseModel.fromJson(json.decode(str));

String issueTypeResponseModelToJson(IssueTypeResponseModel data) => json.encode(data.toJson());

class IssueTypeResponseModel {
  bool? success;
  List<IssueTypeData>? data;
  String? message;
  int? status;

  IssueTypeResponseModel({this.success, this.data, this.message, this.status});

  factory IssueTypeResponseModel.fromJson(Map<String, dynamic> json) => IssueTypeResponseModel(
    success: json["success"],
    data: json["data"] == null
        ? []
        : List<IssueTypeData>.from(json["data"]!.map((x) => IssueTypeData.fromJson(x))),
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

class IssueTypeData {
  String? issuetype;
  int? issuetypeid;

  IssueTypeData({this.issuetype, this.issuetypeid});

  factory IssueTypeData.fromJson(Map<String, dynamic> json) =>
      IssueTypeData(issuetype: json["issuetype"], issuetypeid: json["issuetypeid"]);

  Map<String, dynamic> toJson() => {"issuetype": issuetype, "issuetypeid": issuetypeid};
}
