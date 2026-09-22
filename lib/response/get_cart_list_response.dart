// To parse this JSON data, do
//
//     final getCartListResponse = getCartListResponseFromJson(jsonString);

import 'dart:convert';

GetCartListResponse getCartListResponseFromJson(String str) => GetCartListResponse.fromJson(json.decode(str));

String getCartListResponseToJson(GetCartListResponse data) => json.encode(data.toJson());

class GetCartListResponse {
  GetCartListResponse({
    this.success,
    this.data,
    this.message,
    this.status,
  });

  bool? success;
  List<GetCartListData>? data;
  String? message;
  int? status;

  factory GetCartListResponse.fromJson(Map<String, dynamic> json) => GetCartListResponse(
        success: json["success"],
        /// `cartdetailnew` answers an empty cart with ONE all-zero row (id 0,
        /// productid 0) instead of an empty list — drop it so the cart really
        /// reads as empty.
        data: json["data"] == null
            ? null
            : (json["data"] as List)
                .map((x) => GetCartListData.fromJson(x))
                .where((x) => (x.id ?? 0) > 0)
                .toList(),
        message: json["message"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": data == null ? null : List<dynamic>.from(data!.map((x) => x.toJson())),
        "message": message,
        "status": status,
      };
}

class GetCartListData {
  GetCartListData(
      {this.id,
      this.productimage,
      this.productid,
      this.productname,
      this.unit,
      this.quantity,
      this.itemrate,
      this.total,
      this.subtotal,
      this.shippingamount,
      this.grandtotal,
      this.ordertype,
      this.gstpercent,
      this.gstamount,
      this.discountpercent,
      this.discountamount,
      this.isTextField});

  int? id;
  String? productimage;
  int? productid;
  String? productname;
  String? unit;
  double? quantity;
  double? itemrate;
  double? total;
  double? subtotal;
  double? shippingamount;
  double? grandtotal;

  /// Laranza-only columns from `cartdetailnew`. [ordertype] is what the line
  /// was added as ("Estimate" / "PI" / "" for legacy rows). [gstpercent] is
  /// zeroed by the server on an Estimate; [gstamount] is for the WHOLE line
  /// (rate x qty x %), already worked out on the discounted rate.
  String? ordertype;
  double? gstpercent;
  double? gstamount;
  double? discountpercent;
  double? discountamount;
  bool? isTextField;
  factory GetCartListData.fromJson(Map<String, dynamic> json) => GetCartListData(
      id: json["id"],
      productimage: json["productimage"],
      productid: json["productid"],
      productname: json["productname"],
      unit: json["unit"],
      quantity: json["quantity"],
      itemrate: json["itemrate"],
      total: json["total"],
      subtotal: json["subtotal"],
      shippingamount: json["shippingamount"],
      grandtotal: json["grandtotal"],
      ordertype: json["ordertype"],
      gstpercent: (json["gstpercent"] as num?)?.toDouble(),
      gstamount: (json["gstamount"] as num?)?.toDouble(),
      discountpercent: (json["discountpercent"] as num?)?.toDouble(),
      discountamount: (json["discountamount"] as num?)?.toDouble(),
      isTextField: json["isTextField"] ?? false);

  Map<String, dynamic> toJson() => {
        "id": id,
        "productimage": productimage,
        "productid": productid,
        "productname": productname,
        "unit": unit,
        "quantity": quantity,
        "itemrate": itemrate,
        "total": total,
        "subtotal": subtotal,
        "shippingamount": shippingamount,
        "grandtotal": grandtotal,
        "ordertype": ordertype,
        "gstpercent": gstpercent,
        "gstamount": gstamount,
        "discountpercent": discountpercent,
        "discountamount": discountamount,
      };
}
