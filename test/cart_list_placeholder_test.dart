import 'package:digitalerp/response/get_cart_list_response.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the filter applied in CartController.getDetails.
List<GetCartListData> realRows(List<GetCartListData>? rows) =>
    (rows ?? []).where((e) => (e.id ?? 0) > 0 && (e.productid ?? 0) > 0).toList();

void main() {
  test('empty cart placeholder row is discarded', () {
    /// The API returns one blank row instead of an empty array when the cart
    /// is empty. Left in, it renders a phantom item and enables Place Order.
    final res = getCartListResponseFromJson(
      '{"success":true,"status":200,"message":"Cart List","data":[{'
      '"id":0,"productimage":"","productid":0,"productname":"","unit":"",'
      '"quantity":0.0,"itemrate":0.0,"total":0.0,"subtotal":0.0,'
      '"shippingamount":0.0,"grandtotal":0.0}]}',
    );
    expect(res.data, hasLength(1), reason: 'API really does send a row');
    expect(realRows(res.data), isEmpty);
  });

  test('a genuine cart row is kept', () {
    final res = getCartListResponseFromJson(
      '{"success":true,"status":200,"message":"Cart List","data":[{'
      '"id":8616,"productimage":"x","productid":256788,"productname":"MAXIDURA",'
      '"unit":"KGS","quantity":5.0,"itemrate":1250.0,"total":6250.0,'
      '"subtotal":6250.0,"shippingamount":0.0,"grandtotal":6250.0}]}',
    );
    expect(realRows(res.data), hasLength(1));
    expect(realRows(res.data).single.productid, 256788);
  });
}
