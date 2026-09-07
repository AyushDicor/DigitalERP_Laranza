import 'package:digitalerp/response/add_to_cart_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('list data (addtocartnew) still parses', () {
    final r = addToCartResponseFromJson(
        '{"success":true,"data":[{"totalnumber":3}],"message":"ok","status":200}');
    expect(r.status, 200);
    expect(r.data!.single.totalnumber, 3);
  });

  test('object data (addtocartwithnetrate) parses instead of throwing', () {
    final r = addToCartResponseFromJson(
        '{"success":true,"data":{"totalnumber":4},"message":"ok","status":200}');
    expect(r.status, 200);
    expect(r.data!.single.totalnumber, 4);
  });

  test('empty object data yields an empty list, not a crash', () {
    final r = addToCartResponseFromJson(
        '{"success":true,"data":{},"message":"ok","status":200}');
    expect(r.status, 200);
    expect(r.data, isEmpty);
  });

  test('null data is tolerated', () {
    final r = addToCartResponseFromJson(
        '{"success":true,"data":null,"message":"ok","status":200}');
    expect(r.status, 200);
    expect(r.data, isNull);
  });

  test('a success is never reported as a failure by an odd data shape', () {
    for (final body in [
      '{"success":true,"data":"x","message":"ok","status":200}',
      '{"success":true,"data":7,"message":"ok","status":200}',
    ]) {
      expect(addToCartResponseFromJson(body).status, 200,
          reason: 'status must survive: $body');
    }
  });
}
