import 'package:digitalerp/response/subcategory_brand_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unitid survives fromJson', () {
    /// Regression: the constructor took `required unitid` instead of
    /// `required this.unitid`, so the value was accepted and thrown away.
    /// Every cart call then sent unitid 0, which `addtocartwithnetrate`
    /// rejects with "Data Not Added".
    final data = productDataFromJson(
      '{"success":true,"status":200,"message":"ok","data":[{'
      '"itemid":256788,"itemname":"MAXIDURA--310L (3.15X350MM)",'
      '"itemcode":"248","itemdescription":"","itemimage":"x","unit":"KGS",'
      '"rate":0.0,"requiredpoint":0.0,"quantity":1.0,"unitid":8651}]}',
    );

    final item = data.data!.single;
    expect(item.itemid, 256788);
    expect(item.unitid, 8651, reason: 'unitid must not be dropped');
    expect(item.unit, 'KGS');
  });

  test('a missing unitid stays null rather than throwing', () {
    final data = productDataFromJson(
      '{"success":true,"status":200,"message":"ok","data":[{'
      '"itemid":1,"itemname":"x","itemcode":"1","unit":"KGS","rate":10.0}]}',
    );
    expect(data.data!.single.unitid, isNull);
  });
}
