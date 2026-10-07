import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stickystuff/core/sticker_validation.dart';
import 'package:stickystuff/core/resizer.dart';

Uint8List fixture(String name) =>
    File('test/fixtures/$name.webp').readAsBytesSync();

Uint8List withDurations(int duration) {
  final bytes = fixture('animated');
  final data = ByteData.sublistView(bytes);
  for (var offset = 12; offset < bytes.length;) {
    if (String.fromCharCodes(bytes.sublist(offset, offset + 4)) == 'ANMF') {
      for (var i = 0; i < 3; i++) {
        bytes[offset + 20 + i] = (duration >> (8 * i)) & 255;
      }
    }
    final size = data.getUint32(offset + 4, Endian.little);
    offset += 8 + size + (size & 1);
  }
  return bytes;
}

Uint8List padded(String name, int length) {
  final original = fixture(name);
  final bytes = Uint8List(length)..setAll(0, original);
  bytes.setAll(original.length, 'JUNK'.codeUnits);
  final data = ByteData.sublistView(bytes);
  data.setUint32(4, length - 8, Endian.little);
  data.setUint32(
      original.length + 4, length - original.length - 8, Endian.little);
  return bytes;
}

void main() {
  test('detects and validates real static and animated WebP', () {
    expect(StickerValidation.validate(fixture('static')).hasAnimation, isFalse);
    final info = StickerValidation.validate(fixture('animated'));
    expect(info.hasAnimation, isTrue);
    expect(info.frames.length, 2);
  });

  test('enforces inclusive timing boundaries', () {
    expect(() => StickerValidation.validate(withDurations(7)),
        throwsFormatException);
    expect(() => StickerValidation.validate(withDurations(0)),
        throwsFormatException);
    expect(StickerValidation.validate(withDurations(8)).hasAnimation, isTrue);
    expect(
        StickerValidation.validate(withDurations(5000)).hasAnimation, isTrue);
    expect(() => StickerValidation.validate(withDurations(5001)),
        throwsFormatException);
  });

  test('enforces size limits for both types', () {
    for (final entry
        in {'static': 100 * 1024, 'animated': 500 * 1024}.entries) {
      StickerValidation.validate(padded(entry.key, entry.value));
      expect(
          () => StickerValidation.validate(padded(entry.key, entry.value + 2)),
          throwsFormatException);
    }
  });

  test('rejects incorrect canvas dimensions and invalid input', () {
    final bytes = fixture('animated');
    bytes[24] = 254; // VP8X canvas width minus one: 511 -> 510.
    expect(() => StickerValidation.validate(bytes), throwsFormatException);
    expect(() => StickerValidation.validate(Uint8List.fromList([1, 2, 3])),
        throwsFormatException);
    expect(
        () => StickerValidation.validate(
            Uint8List.sublistView(fixture('animated'), 0, 40)),
        throwsFormatException);
  });

  test('enforces pack count and homogeneous types', () {
    for (final count in [0, 1, 2, 31]) {
      expect(
          () => StickerValidation.validateCount(count), throwsFormatException);
    }
    StickerValidation.validateCount(3);
    StickerValidation.validateCount(30);
    StickerValidation.validatePackTypes([true, true, true]);
    StickerValidation.validatePackTypes([false, false, false]);
    expect(() => StickerValidation.validatePackTypes([true, false]),
        throwsFormatException);
  });

  test('static resizer never flattens animated input', () async {
    await expectLater(Resizer().resizeWebp(fixture('animated'), 'unused.webp'),
        throwsFormatException);
  });
}
