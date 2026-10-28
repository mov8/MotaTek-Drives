import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:drives/models/other_models.dart';

void main() {
  // The live server's Home item, as it came on 28 October: images a list of
  // maps written as strings, and no style
  Map<String, dynamic> live = {
    'id': '0123456789abcdef0123456789abcdef',
    'heading': 'New trip planning app',
    'subheading': 'there is always somewhere to go',
    'markdown': '# Drives',
    'style': null,
    'images': jsonEncode([
      jsonEncode({'url': '33a90434.jpg', 'caption': '', 'rotation': 0})
    ]),
    'added': '2026-01-10 09:30:00.000000',
    'author': 'James Seddon',
  };

  test('an item with images written as strings, and no style', () {
    HomeItem item = HomeItem.fromMap(map: live);
    expect(item.heading, 'New trip planning app');
    expect(item.markdown, '# Drives');
    expect(item.style, isNull);
    expect(item.images!.last['url'], '33a90434.jpg');
  });

  test('images however they were kept', () {
    expect(decodeItemImages('["a.jpg","b.jpg"]').skip(1).map((i) => i['url']),
        ['a.jpg', 'b.jpg']);
    expect(decodeItemImages('[{"url":"c.jpg","caption":"x"}]').last['caption'],
        'x');
    expect(decodeItemImages(''), [{}]);
    expect(decodeItemImages(null), [{}]);
  });

  test('a style written as a string of a string', () {
    String style = jsonEncode({'p': {'color': 'black'}});
    expect(decodeItemStyle(style)!['p'], {'color': 'black'});
    expect(decodeItemStyle(jsonEncode(style))!['p'], {'color': 'black'});
    expect(decodeItemStyle('not json'), isNull);
  });

  test('a Shop item the same way', () {
    ShopItem item = ShopItem.fromMap(map: live);
    expect(item.heading, 'New trip planning app');
    expect(item.images!.last['url'], '33a90434.jpg');
  });
}
