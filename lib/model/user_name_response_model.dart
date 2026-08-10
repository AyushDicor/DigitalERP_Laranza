import 'dart:convert';

UserNameResponseModel userNameResponseModelFromJson(String str) =>
    UserNameResponseModel.fromJson(json.decode(str));

String userNameResponseModelToJson(UserNameResponseModel data) => json.encode(data.toJson());

class UserNameResponseModel {
  bool? success;
  List<UserNameData>? data;
  String? message;
  int? status;

  UserNameResponseModel({this.success, this.data, this.message, this.status});

  factory UserNameResponseModel.fromJson(Map<String, dynamic> json) => UserNameResponseModel(
    success: json["success"],
    data: json["data"] == null
        ? []
        : List<UserNameData>.from(json["data"]!.map((x) => UserNameData.fromJson(x))),
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

class UserNameData {
  String? username;
  int? userid;

  UserNameData({this.username, this.userid});

  factory UserNameData.fromJson(Map<String, dynamic> json) =>
      UserNameData(username: json["username"], userid: json["userid"]);

  Map<String, dynamic> toJson() => {"username": username, "userid": userid};
}
