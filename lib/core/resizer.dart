import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart';
import 'package:stickystuff/core/sticker_validation.dart';

class Resizer {
  Future<bool> resizeWebp(Uint8List webpBuffer, String path) async {
    final info = StickerValidation.inspect(webpBuffer);
    if (info.hasAnimation) {
      throw const FormatException(
          'Animated WebP must already meet WhatsApp requirements.');
    }
    final codec = await ui.instantiateImageCodec(webpBuffer);
    late Uint8List sourcePng;
    try {
      final frame = await codec.getNextFrame();
      try {
        final data =
            await frame.image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw const FormatException('Invalid WebP sticker.');
        sourcePng =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
    final image = decodePng(sourcePng);
    if (image == null) throw const FormatException('Invalid WebP sticker.');
    final png =
        encodePng(copyResizeCropSquare(image, size: 512), singleFrame: true);
    for (final quality in [85, 70, 50, 30, 10]) {
      final bytes = await FlutterImageCompress.compressWithList(png,
          minHeight: 512,
          minWidth: 512,
          format: CompressFormat.webp,
          quality: quality);
      if (bytes.length <= StickerValidation.staticMaxBytes) {
        StickerValidation.validate(bytes);
        await File(path).writeAsBytes(bytes);
        return true;
      }
    }
    throw const FormatException(
        'Could not compress this sticker to the 100 KB limit.');
  }
}
