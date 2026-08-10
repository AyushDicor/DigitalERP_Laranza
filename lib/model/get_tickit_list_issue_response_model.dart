import 'dart:convert';

GetTicketIssueResponseModel getTicketIssueResponseModelFromJson(String str) =>
    GetTicketIssueResponseModel.fromJson(json.decode(str));

String getTicketIssueResponseModelToJson(GetTicketIssueResponseModel data) => json.encode(data.toJson());

class GetTicketIssueResponseModel {
  bool? success;
  List<AllIsueTicketList>? data;
  String? message;
  int? status;

  GetTicketIssueResponseModel({this.success, this.data, this.message, this.status});

  factory GetTicketIssueResponseModel.fromJson(Map<String, dynamic> json) => GetTicketIssueResponseModel(
    success: json["success"],
    data: json["data"] == null
        ? []
        : List<AllIsueTicketList>.from(json["data"]!.map((x) => AllIsueTicketList.fromJson(x))),
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

class AllIsueTicketList {
  int? ticketNo;
  String? complain;
  String? customer;
  String? complaintype;
  String? createDate;
  String? dueDate;
  String? status;
  bool? isConfirmed;
  List<String>? files;

  AllIsueTicketList({
    this.ticketNo,
    this.complain,
    this.customer,
    this.complaintype,
    this.createDate,
    this.dueDate,
    this.status,
    this.files,
  });

  factory AllIsueTicketList.fromJson(Map<String, dynamic> json) => AllIsueTicketList(
    ticketNo: json["TicketNo"],
    complain: json["Complain"],
    customer: json["Customer"],
    complaintype: json["complaintype"],
    createDate: json["CreateDate"],
    dueDate: json["DueDate"],
    status: json["Status"],
    files: json["Files"] == null ? [] : List<String>.from(json["Files"]!.map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "TicketNo": ticketNo,
    "Complain": complain,
    "Customer": customer,
    "complaintype": complaintype,
    "CreateDate": createDate,
    "DueDate": dueDate,
    "Status": status,
    "Files": files == null ? [] : List<dynamic>.from(files!.map((x) => x)),
  };
}
