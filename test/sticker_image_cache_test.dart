import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickystuff/core/sticker_image.dart';

void main() {
  test('encoded cache evicts least recently used entries within its byte limit',
      () {
    final cache = StickerImageCache(maxBytes: 6);
    cache.put('a', Uint8List.fromList([1, 2, 3]));
    cache.put('b', Uint8List.fromList([4, 5, 6]));
    expect(cache.get('a'), [1, 2, 3]);
    cache.put('c', Uint8List.fromList([7, 8, 9]));
    expect(cache.get('b'), isNull);
    expect(cache.get('a'), [1, 2, 3]);
    expect(cache.get('c'), [7, 8, 9]);
    cache.put('oversized', Uint8List(7));
    expect(cache.get('oversized'), isNull);
    cache.clear();
    expect(cache.get('a'), isNull);
  });
}
