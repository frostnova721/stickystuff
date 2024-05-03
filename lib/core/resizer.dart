import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_image_converter/flutter_image_converter.dart';
import 'package:image/image.dart';

class Resizer {
  Future<bool> resizeWebp(Uint8List webpBuffer, String path) async {
    try {
    final file = File(path);
    final img = decodeWebP(webpBuffer);
    final re = copyResizeCropSquare(img!, size: 512);
    final formatChange = await FlutterImageCompress.compressWithList(await re.pngUint8List, minHeight: 512, minWidth: 512, format: CompressFormat.webp, quality: 50,);
    await file.writeAsBytes(formatChange);
    return true;
    } catch(err) {
      print(err);
      return false;
    }
  }
}