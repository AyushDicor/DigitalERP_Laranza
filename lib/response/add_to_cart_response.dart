// To parse this JSON data, do
//
//     final addToCartResponse = addToCartResponseFromJson(jsonString);

import 'dart:convert';

AddToCartResponse addToCartResponseFromJson(String str) => AddToCartResponse.fromJson(json.decode(str));

String addToCartResponseToJson(AddToCartResponse data) => json.encode(data.toJson());

class AddToCartResponse {
  AddToCartResponse({
    this.success,
    this.data,
    this.message,
    this.status,
  });

  bool? success;
  List<AddToCartData>? data;
  String? message;
  int? status;

  factory AddToCartResponse.fromJson(Map<String, dynamic> json) => AddToCartResponse(
    success: json["success"],
    data: _parseData(json["data"]),
    message: json["message"],
    status: json["status"],
  );

  /// `addtocartnew` returns `data` as a list; `addtocartwithnetrate` documents
  /// it as an object. Both are accepted, because a parse failure here would
  /// report a *successful* add as failed — and on an additive endpoint that
  /// invites a retry which silently doubles the quantity.
  static List<AddToCartData>? _parseData(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(AddToCartData.fromJson)
            .toList();
      }
      if (raw is Map<String, dynamic>) {
        return raw.isEmpty ? <AddToCartData>[] : [AddToCartData.fromJson(raw)];
      }
    } catch (_) {
      /// Shape we do not recognise — the caller falls back to re-reading the
      /// cart count rather than treating the add as failed.
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data == null ? null : List<dynamic>.from(data!.map((x) => x.toJson())),
    "message": message,
    "status": status,
  };
}

class AddToCartData {
  AddToCartData({
    this.totalnumber,
  });

  int? totalnumber;

  factory AddToCartData.fromJson(Map<String, dynamic> json) => AddToCartData(
    totalnumber: json["totalnumber"],
  );

  Map<String, dynamic> toJson() => {
    "totalnumber": totalnumber,
  };
}
