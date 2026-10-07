import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

/// WhatsApp's third-party sticker requirements:
/// https://github.com/WhatsApp/stickers/blob/main/Android/README.md
class StickerValidation {
  static const staticMaxBytes = 100 * 1024;
  static const animatedMaxBytes = 500 * 1024;
  static const trayMaxBytes = 50 * 1024;

  static void validateCount(int count) {
    if (count < 3 || count > 30) {
      throw const FormatException('Choose 3–30 stickers per WhatsApp pack.');
    }
  }

  static void validatePackTypes(Iterable<bool> animated) {
    if (animated.toSet().length > 1) {
      throw const FormatException(
          'WhatsApp packs cannot mix animated and static stickers. Select only one type.');
    }
  }

  /// Reads the original container so an animation never enters a static encoder.
  static img.WebPInfo inspect(Uint8List bytes) {
    try {
      if (bytes.length < 12 ||
          ByteData.sublistView(bytes).getUint32(4, Endian.little) + 8 !=
              bytes.length) {
        throw const FormatException('Invalid WebP container.');
      }
      final info = img.WebPDecoder().startDecode(bytes);
      if (info == null) throw const FormatException('Invalid WebP image.');
      return info;
    } catch (_) {
      throw const FormatException(
          'Use a valid WebP sticker. Telegram TGS, WebM and GIF files must first be converted to animated WebP.');
    }
  }

  static img.WebPInfo validate(Uint8List bytes) {
    final info = inspect(bytes);
    final maxBytes = info.hasAnimation ? animatedMaxBytes : staticMaxBytes;
    if (bytes.length > maxBytes) {
      throw FormatException(
          '${info.hasAnimation ? "Animated" : "Static"} stickers must be at most ${maxBytes ~/ 1024} KB.');
    }
    if (info.width != 512 || info.height != 512) {
      throw const FormatException('Stickers must be exactly 512 × 512 pixels.');
    }
    if (info.hasAnimation) {
      if (info.frames.length < 2) {
        throw const FormatException(
            'Animated stickers must contain at least two frames.');
      }
      var duration = 0;
      for (final frame in info.frames) {
        if (frame.duration < 8) {
          throw const FormatException(
              'Every animation frame must last at least 8 ms.');
        }
        duration += frame.duration;
        if (frame.x + frame.width > 512 || frame.y + frame.height > 512) {
          throw const FormatException(
              'Animation frames must fit the 512 × 512 canvas.');
        }
      }
      if (duration > 10000) {
        throw const FormatException(
            'Animated stickers must last at most 10 seconds.');
      }
    }
    return info;
  }

  /// Use Flutter's native WebP decoder for payload validation. The pure Dart
  /// decoder cannot decode some valid lossless/palette WebP images.
  static Future<void> validateDecoding(Uint8List bytes) async {
    final info = validate(bytes);
    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      if (info.hasAnimation && codec.frameCount != info.frames.length) {
        throw const FormatException('Invalid animation frame count.');
      }
      for (var i = 0; i < codec.frameCount; i++) {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      }
    } catch (_) {
      throw const FormatException('The sticker contains a damaged WebP frame.');
    } finally {
      codec?.dispose();
    }
  }
}
