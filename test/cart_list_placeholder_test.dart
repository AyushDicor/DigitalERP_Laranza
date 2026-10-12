import 'package:digitalerp/response/get_cart_list_response.dart';
import 'package:flutter_test/flutter_test.dart';

/// `cartdetailnew` answers an EMPTY cart with one all-zero row rather than an
/// empty array. Left in, it renders a phantom item and enables Place Order.
///
/// That row used to be filtered in CartController.getDetails; since 2026-10-07
/// it is dropped inside [GetCartListResponse.fromJson], so every screen that
/// parses a cart gets a clean list instead of each one having to remember.
void main() {
  test('empty-cart placeholder row is dropped during parsing', () {
    final res = getCartListResponseFromJson(
      '{"success":true,"status":200,"message":"Cart List","data":[{'
      '"id":0,"productimage":"","productid":0,"productname":"","unit":"",'
      '"quantity":0.0,"itemrate":0.0,"total":0.0,"subtotal":0.0,'
      '"shippingamount":0.0,"grandtotal":0.0,"ordertype":"","gstpercent":0.0,'
      '"gstamount":0.0,"discountpercent":0.0,"discountamount":0.0}]}',
    );
    expect(res.data, isEmpty, reason: 'the zero row must not reach the UI');
    expect(res.status, 200);
  });

  test('a genuine cart row is kept, with its Laranza columns', () {
    final res = getCartListResponseFromJson(
      '{"success":true,"status":200,"message":"Cart List","data":[{'
      '"id":8616,"productimage":"x","productid":256788,"productname":"MAXIDURA",'
      '"unit":"KGS","quantity":5.0,"itemrate":1250.0,"total":6250.0,'
      '"subtotal":6250.0,"shippingamount":0.0,"grandtotal":6250.0,'
      '"ordertype":"PI","gstpercent":18.0,"gstamount":1125.0,'
      '"discountpercent":10.0,"discountamount":500.0}]}',
    );
    expect(res.data, hasLength(1));
    final row = res.data!.single;
    expect(row.productid, 256788);
    expect(row.ordertype, 'PI');
    expect(row.gstpercent, 18.0);
    expect(row.gstamount, 1125.0);
    expect(row.discountpercent, 10.0);
    expect(row.discountamount, 500.0);
  });

  test('a real row survives even when mixed with the placeholder', () {
    final res = getCartListResponseFromJson(
      '{"success":true,"status":200,"message":"Cart List","data":['
      '{"id":0,"productid":0,"productname":"","quantity":0.0,"itemrate":0.0},'
      '{"id":8617,"productid":378942,"productname":"Thali","quantity":2.0,'
      '"itemrate":600.0}]}',
    );
    expect(res.data, hasLength(1));
    expect(res.data!.single.productid, 378942);
  });
}
