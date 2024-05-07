// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_image_converter/flutter_image_converter.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stickystuff/core/resizer.dart';
import 'package:stickystuff/core/types.dart';
import 'package:flutter_whatsapp_stickers/flutter_whatsapp_stickers.dart';

class Stickers {
  Future<StickerSearchModal?> fetchStickers(String packLink) async {
    final dio = Dio();
    final res = await dio.get("https://weeb-api.vercel.app/telesticker?url=$packLink");
    if (res.statusCode != 200) {
      return null;
    }
    final result = res.data;
    return StickerSearchModal(
        author: result['title'], name: result['name'], stickers: List<String>.from(result['stickers']));
  }

  Future addPackToWhatsApp(List<String> urls, String packName, DownloadProgressCallback callback,
      {int trayIconIndex = 0, String author = "stickystuff"}) async {
    //no whatsapp checks since it always returns false!

    try {
      final packDir = (await getApplicationDocumentsDirectory()).path;
      final stickersDir = Directory(packDir);
      if (!(await stickersDir.exists())) {
        await stickersDir.create(recursive: true);
      }
      await _downloadStickers(urls, packName, author, packDir, trayIconIndex, callback);

      WhatsAppStickers().addStickerPack(
        packageName: WhatsAppPackage.Consumer,
        stickerPackIdentifier: packName,
        stickerPackName: packName,
        listener: (action, status, {error = ''}) async {
          print(action.name);
          print("status: $status");
          if (error.isNotEmpty) {
            print("ERROR: $error");
            throw Exception(error);
          }
        },
      );
    } on Exception catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  //creates the tray icon by resizing the selected icon
  Future<void> _createTrayIcon(String imgUrl, String packName, Dio dio, String packDir) async {
    final tempDir = Directory('/storage/emulated/0/Documents/stickystuff');
    if (!(await tempDir.exists())) {
      await tempDir.create(recursive: true);
    }
    await dio.download(imgUrl, "${tempDir.path}/tray_$packName.webp");
    final trayWebpFile = File("${tempDir.path}/tray_$packName.webp");
    final pngBytes = await trayWebpFile.pngUint8List;
    await trayWebpFile.delete();
    final image = decodePng(pngBytes);
    if (image == null) throw Exception("Invalid Tray Image");
    final resizedImage = copyResize(image, height: 96, width: 96);
    final resizedImageBytes = await resizedImage.pngUint8List;

    print("${resizedImageBytes.lengthInBytes / 1000}kb size for tray icon");

    //just to check the image!
    final trayFile = File("${tempDir.path}/tray_$packName.png");
    await trayFile.writeAsBytes(resizedImageBytes);

    final croppedPngBytes = await trayFile.pngUint8List;
    if (!(await Directory("$packDir/sticker_packs/$packName").exists())) {
      await Directory("$packDir/sticker_packs/$packName").create(recursive: true);
    }
    final newFile = File("$packDir/sticker_packs/$packName/tray_$packName.png");
    await newFile.writeAsBytes(croppedPngBytes);
  }

  /// Downloads the stickers, makes and saves the tray icon and json file
  Future<void> _downloadStickers(List<String> urls, String packName, String author, String docsDir, int trayIconIndex,
      DownloadProgressCallback callback) async {
    final dio = Dio();

    await _createTrayIcon(urls[trayIconIndex], packName, dio, docsDir);

    Map<String, dynamic> jsonContent = {};
    if (urls.length > 30) urls = urls.sublist(0, 30);
    List<Map<String, dynamic>> stickerDataArray = [];
    // List<double> sizeArray = [];

    for (int count = 0; count < urls.length; count++) {
      final itemName = "${packName}_$count";
      stickerDataArray.add({
        "image_file": "$itemName.webp",
        "emojis": ['💀', '☠️']
      });
      final download = await dio.get(urls[count], options: Options(responseType: ResponseType.bytes));
      final validation =
          await _validateAndSaveSticker("$docsDir/sticker_packs/$packName/$itemName.webp", download.data);
      print(validation);
      print("downloaded $itemName.webp");
      callback.call(count + 1, urls.length);
      // sizeArray.add(int.parse(download.headers.map['content-length']![0]) / 1024);
    }

    // for (final size in sizeArray) {
    //   if (size > 100) {
    //     print("found an item over 100kb");
    //   }
    // }

    jsonContent = {
      "identifier": packName,
      "name": packName,
      "publisher": author,
      "tray_image_file": "tray_$packName.png",
      "image_data_version": "1",
      "avoid_cache": false,
      "publisher_email": "",
      "publisher_website": "",
      "privacy_policy_website": "",
      "license_agreement_website": "",
      "stickers": stickerDataArray,
    };

    await _createLocalFiles(jsonContent, docsDir);
  }

  Future<bool> _validateAndSaveSticker(String path, Uint8List stickerBuffer) async {
    final webp = decodeWebP(stickerBuffer);
    if (webp == null) throw Exception("ERR_WITH_WEBP");
    print("${webp.width} ${webp.height}");
    if (webp.width != 512 || webp.height != 512) {
      final resized = await Resizer().resizeWebp(stickerBuffer, path);
      if (!resized) throw Exception("Error Resizing Webp File");
    } else {
      await File(path).writeAsBytes(stickerBuffer);
      return true;
    }
    return false;
  }

  Future<void> _createLocalFiles(Map<String, dynamic> jsonContent, String docsDir) async {
    if (!(await Directory("$docsDir/sticker_packs").exists())) {
      await Directory("$docsDir/sticker_packs").create();
    }
    final json = File("$docsDir/sticker_packs/sticker_packs.json");
    if (!(await json.exists())) {
      final starter = {
        "android_play_store_link": "",
        "ios_app_store_link": "",
        "sticker_packs": [],
      };
      await json.writeAsString(jsonEncode(starter));
    }
    final jsonContentString = await json.readAsString();
    final mapped = jsonDecode(jsonContentString);
    mapped['sticker_packs'] = [jsonContent];

    await json.writeAsString(jsonEncode(mapped));
  }
}
