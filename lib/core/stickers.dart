// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:stickystuff/core/resizer.dart';
import 'package:stickystuff/core/sticker_image.dart';
import 'package:stickystuff/core/sticker_validation.dart';
import 'package:stickystuff/core/types.dart';
import 'package:flutter_whatsapp_stickers/flutter_whatsapp_stickers.dart';

class Stickers {
  Future<StickerSearchModal?> fetchStickers(String packLink) async {
    final dio = Dio();
    final res =
        await dio.get("https://icey-api.vercel.app/telesticker?url=$packLink");
    if (res.statusCode != 200) {
      return null;
    }
    final result = res.data;
    final List<dynamic> stickers = result['stickers'];
    final List<String> stickerLinks = [];
    stickers.forEach((it) => stickerLinks.add(it['link']));
    return StickerSearchModal(
        author: result['title'], name: result['name'], stickers: stickerLinks);
  }

  Future addPackToWhatsApp(
      List<String> urls, String packName, DownloadProgressCallback callback,
      {int trayIconIndex = 0,
      String author = "stickystuff",
      CancelToken? cancelToken,
      void Function()? onInstalling}) async {
    cancelToken?.throwIfCancellationRequested();
    StickerValidation.validateCount(urls.length);
    if (trayIconIndex < 0 || trayIconIndex >= urls.length) {
      throw const FormatException('Select a valid tray icon.');
    }
    if (packName.trim().isEmpty ||
        packName.length > 128 ||
        author.trim().isEmpty ||
        author.length > 128) {
      throw const FormatException(
          'Pack name and author must contain 1-128 characters.');
    }
    final packDir = (await getApplicationDocumentsDirectory()).path;
    final identifier = 'pack_${DateTime.now().microsecondsSinceEpoch}';
    try {
      await _downloadStickers(
          urls, identifier, author, packDir, trayIconIndex, callback,
          displayName: packName,
          cancelToken: cancelToken,
          onInstalling: onInstalling);
    } catch (_) {
      await _deleteStickers("$packDir/sticker_packs/$identifier");
      rethrow;
    }
    final result = Completer<void>();
    final launch = WhatsAppStickers().addStickerPack(
      packageName: WhatsAppPackage.Consumer,
      stickerPackIdentifier: identifier,
      stickerPackName: packName,
      listener: (action, status, {error = ''}) async {
        if (result.isCompleted) return;
        if (error.isNotEmpty || action == StickerPackResult.ERROR || !status) {
          result.completeError(Exception(
              error.isEmpty ? 'WhatsApp could not add this pack.' : error));
        } else if (action == StickerPackResult.CANCELLED) {
          result.completeError(
              Exception('Adding the sticker pack was cancelled.'));
        } else {
          result.complete();
        }
      },
    );
    // Observe launch failures as well as WhatsApp's eventual activity result.
    // Listen to both immediately because callbacks can arrive before launch ends.
    await Future.wait<void>([launch, result.future], eagerError: true);
  }

  //creates the tray icon by resizing the selected icon
  Future<void> _createTrayIcon(
      Uint8List bytes, String packName, String packDir) async {
    final codec = await ui.instantiateImageCodec(bytes,
        targetWidth: 96, targetHeight: 96);
    late Uint8List croppedPngBytes;
    try {
      final frame = await codec.getNextFrame();
      try {
        final png =
            await frame.image.toByteData(format: ui.ImageByteFormat.png);
        if (png == null) throw const FormatException('Invalid tray image.');
        croppedPngBytes =
            png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
    // Animated codecs may ignore targetWidth/targetHeight. Resize the decoded
    // static frame explicitly so the exported tray is always exactly 96 x 96.
    croppedPngBytes = img.encodePng(
        img.copyResize(img.decodePng(croppedPngBytes)!, width: 96, height: 96),
        singleFrame: true);
    if (croppedPngBytes.length > StickerValidation.trayMaxBytes) {
      throw const FormatException(
          'Tray icons must be at most 50 KB. Choose another sticker.');
    }
    if (!(await Directory("$packDir/sticker_packs/$packName").exists())) {
      await Directory("$packDir/sticker_packs/$packName")
          .create(recursive: true);
    }
    final newFile = File("$packDir/sticker_packs/$packName/tray_$packName.png");
    await newFile.writeAsBytes(croppedPngBytes);
  }

  /// Downloads the stickers, makes and saves the tray icon and json file
  Future<void> _downloadStickers(
      List<String> urls,
      String packName,
      String author,
      String docsDir,
      int trayIconIndex,
      DownloadProgressCallback callback,
      {required String displayName,
      CancelToken? cancelToken,
      void Function()? onInstalling}) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.bytes,
    ));
    final downloadToken = cancelToken ?? CancelToken();

    Map<String, dynamic> jsonContent = {};
    final types = <bool>[];
    List<Map<String, dynamic>> stickerDataArray = [];
    for (int count = 0; count < urls.length; count++) {
      final itemName = "${packName}_$count";
      stickerDataArray.add({
        "image_file": "$itemName.webp",
        "emojis": ['💀', '☠️']
      });
    }

    var nextIndex = 0;
    var completed = 0;
    Object? failure;
    StackTrace? failureStack;

    Future<void> downloadWorker() async {
      try {
        while (!downloadToken.isCancelled && nextIndex < urls.length) {
          final index = nextIndex++;
          final bytes = await StickerImageCache.shared
              .load(urls[index], dio, cancelToken: downloadToken);
          if (downloadToken.isCancelled) return;
          final path =
              "$docsDir/sticker_packs/$packName/${packName}_$index.webp";
          final animated = await _validateAndSaveSticker(path, bytes);
          if (downloadToken.isCancelled) return;
          types.add(animated);
          StickerValidation.validatePackTypes(types);
          if (index == trayIconIndex) {
            // Reuse the validated sticker instead of downloading it twice.
            await _createTrayIcon(
                await File(path).readAsBytes(), packName, docsDir);
          }
          if (downloadToken.isCancelled) return;
          callback.call(++completed, urls.length);
        }
      } catch (error, stack) {
        if (failure == null) {
          failure = error;
          failureStack = stack;
          downloadToken.cancel('Sticker import failed');
        }
      }
    }

    try {
      await Directory("$docsDir/sticker_packs/$packName")
          .create(recursive: true);
      // Bound network requests and image decoding memory, while overlapping I/O.
      await Future.wait(List.generate(
          urls.length < 4 ? urls.length : 4, (_) => downloadWorker()));
      // All workers have stopped before the caller removes a failed pack.
      if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
      downloadToken.throwIfCancellationRequested();
    } finally {
      dio.close(force: true);
    }

    jsonContent = {
      "identifier": packName,
      "animated_sticker_pack": types.first,
      "name": displayName,
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

    // Cancellation ends at publication: WhatsApp may read these files afterward.
    downloadToken.throwIfCancellationRequested();
    onInstalling?.call();
    await _createLocalFiles(jsonContent, docsDir);
  }

  Future<bool> _validateAndSaveSticker(
      String path, Uint8List stickerBuffer) async {
    final webp = StickerValidation.inspect(stickerBuffer);
    if (webp.hasAnimation) {
      await StickerValidation.validateDecoding(stickerBuffer);
      await File(path).writeAsBytes(stickerBuffer);
      return true;
    }
    print("dimensions: ${webp.width}x${webp.height}");
    if (webp.width != 512 ||
        webp.height != 512 ||
        stickerBuffer.length > StickerValidation.staticMaxBytes) {
      final resized = await Resizer().resizeWebp(stickerBuffer, path);
      if (!resized) throw Exception("Error Resizing Webp File");
      await StickerValidation.validateDecoding(await File(path).readAsBytes());
    } else {
      await StickerValidation.validateDecoding(stickerBuffer);
      await File(path).writeAsBytes(stickerBuffer);
    }
    return false;
  }

  Future<void> _createLocalFiles(
      Map<String, dynamic> jsonContent, String docsDir) async {
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
    final packs = List<dynamic>.from(mapped['sticker_packs']);
    if (packs.length >= 10) {
      throw const FormatException(
          'WhatsApp supports at most 10 packs per sticker app.');
    }
    packs.add(jsonContent);
    mapped['sticker_packs'] = packs;

    await json.writeAsString(jsonEncode(mapped));
  }

  Future<void> _deleteStickers(String packDir) async {
    final dir = Directory(packDir);
    if (!(await dir.exists())) {
      return;
    }
    await dir.delete(recursive: true);
  }
}
