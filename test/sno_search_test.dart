import 'dart:convert';

import 'package:digitalerp/response/subcategory_brand_response.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rows copied verbatim from a live `itemwithbranchandsno` response
/// (compid 59, branch 97) — one item carries a serial, the rest are blank,
/// which is the real state of the data today.
const _liveJson = '''
{"success":true,"data":[
 {"itemid":379119,"itemname":"Slim Box Anthracite Grey Weight Capacity - 40 Kg. (199 mm)","itemcode":"LSBAG DD550","itemdescription":"","itemimage":"x.jpg","unit":"Pcs","rate":4250.0,"requiredpoint":18.0,"quantity":1.0,"unitid":8747,"sno":"1"},
 {"itemid":378942,"itemname":"Thali Fitment Rubber Coated","itemcode":"LTFRC","itemdescription":"","itemimage":"x.jpg","unit":"Pcs","rate":625.0,"requiredpoint":18.0,"quantity":1.0,"unitid":8747,"sno":""},
 {"itemid":262610,"itemname":"G-Handle Profile with Mica Insert-AG","itemcode":"AGHPMI-AG","itemdescription":"3 Mtr.","itemimage":"x.jpg","unit":"Pcs","rate":3430.0,"requiredpoint":18.0,"quantity":1.0,"unitid":8747,"sno":""}
],"message":"Item List","status":200}
''';

/// Mirrors QuickOrderController._applySearch.
List<ProductDataList> search(List<ProductDataList> all, String value) {
  final query = value.trim().toLowerCase();
  if (query.isEmpty) return List<ProductDataList>.from(all);
  return all.where((e) {
    final name = (e.itemname ?? '').toLowerCase();
    final code = (e.itemcode ?? '').toLowerCase();
    final serial = (e.sno ?? '').toLowerCase();
    final desc = (e.itemdescription ?? '').toLowerCase();
    return name.contains(query) ||
        code.contains(query) ||
        serial.contains(query) ||
        desc.contains(query);
  }).toList();
}

void main() {
  test('sno parses and is searchable', () {
    final items = productDataFromJson(_liveJson).data!;

    expect(items.length, 3);
    expect(items[0].sno, '1', reason: 'serial must survive parsing');
    expect(items[1].sno, '');
    expect(items[0].itemcode, 'LSBAG DD550');

    // A blank serial must never match and swallow the whole list.
    expect(search(items, 'zzz').length, 0);

    // Searching the serial finds the item that has it.
    final bySerial = search(items, '1');
    expect(bySerial.any((e) => e.itemid == 379119), isTrue);

    // Code and name still work.
    expect(search(items, 'LTFRC').single.itemid, 378942);
    expect(search(items, 'thali').single.itemid, 378942);
    expect(search(items, 'mica').single.itemid, 262610);

    // Empty query returns everything.
    expect(search(items, '   ').length, 3);

    // The old endpoint omits `sno` entirely — must parse as null, not crash.
    const legacy =
        '{"success":true,"data":[{"itemid":1,"itemname":"X","itemcode":"C","unitid":2}],"status":200}';
    final legacyItems = productDataFromJson(legacy).data!;
    expect(legacyItems.single.sno, isNull);
    expect(search(legacyItems, 'c').length, 1);

    print('PASS  sno parsed="${items[0].sno}" on ${items[0].itemcode}');
    print('PASS  search("1") -> ${bySerial.length} row(s)');
    print('PASS  legacy payload without sno -> ${legacyItems.single.sno}');
  });
}
