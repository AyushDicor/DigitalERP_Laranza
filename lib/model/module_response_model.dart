class ModuleDropdownResponseModel {
  bool success;
  List<ModuleDropdowns> data;
  String message;
  int status;

  ModuleDropdownResponseModel({required this.success, required this.data, required this.message, required this.status});

  factory ModuleDropdownResponseModel.fromJson(Map<String, dynamic> json) {
    return ModuleDropdownResponseModel(
      success: json["success"] ?? false,
      data: (json["data"] != null && json["data"] is List)
          ? List<ModuleDropdowns>.from(json["data"].map((x) => ModuleDropdowns.fromJson(x)))
          : [],
      message: json["message"] ?? "",
      status: json["status"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "message": message,
    "status": status,
  };
}

class ModuleDropdowns {
  String modulename;
  int moduleid;

  ModuleDropdowns({required this.modulename, required this.moduleid});

  factory ModuleDropdowns.fromJson(Map<String, dynamic> json) {
    return ModuleDropdowns(
      modulename: (json["modulename"] ?? "").toString(),
      moduleid: json["moduleid"] is int ? json["moduleid"] : int.tryParse(json["moduleid"].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {"modulename": modulename, "moduleid": moduleid};
}
