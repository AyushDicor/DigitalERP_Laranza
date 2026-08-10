import 'dart:convert';

RelatedServicesResponseModel relatedServicesResponseModelFromJson(String str) =>
    RelatedServicesResponseModel.fromJson(json.decode(str));

String relatedServicesResponseModelToJson(RelatedServicesResponseModel data) => json.encode(data.toJson());

class RelatedServicesResponseModel {
  bool? success;
  List<RelatedServicesList>? data;
  String? message;
  int? status;

  RelatedServicesResponseModel({this.success, this.data, this.message, this.status});

  factory RelatedServicesResponseModel.fromJson(Map<String, dynamic> json) => RelatedServicesResponseModel(
    success: json["success"],
    data: json["data"] == null
        ? []
        : List<RelatedServicesList>.from(json["data"]!.map((x) => RelatedServicesList.fromJson(x))),
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

class RelatedServicesList {
  String? servicename;
  int? serviceid;

  RelatedServicesList({this.servicename, this.serviceid});

  factory RelatedServicesList.fromJson(Map<String, dynamic> json) =>
      RelatedServicesList(servicename: json["servicename"], serviceid: json["serviceid"]);

  Map<String, dynamic> toJson() => {"servicename": servicename, "serviceid": serviceid};
}
