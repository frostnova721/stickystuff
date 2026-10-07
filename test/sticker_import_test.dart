import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/painting.dart';
import 'package:stickystuff/core/sticker_image.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:stickystuff/core/stickers.dart';

class TestPaths extends PathProviderPlatform {
  TestPaths(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('io.github.vincekruger/whatsapp_stickers');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory directory;
  late HttpServer server;
  late PathProviderPlatform originalPaths;
  HttpOverrides? originalHttp;
  final calls = <MethodCall>[];
  final requestedPaths = <String>[];
  var activeRequests = 0;
  var peakRequests = 0;

  setUp(() async {
    originalHttp = HttpOverrides.current;
    HttpOverrides.global = null;
    directory = await Directory.systemTemp.createTemp('sticker_import_');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = TestPaths(directory.path);
    calls.clear();
    StickerImageCache.shared.clear();
    requestedPaths.clear();
    activeRequests = 0;
    peakRequests = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      Future.microtask(() => messenger.handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(const MethodCall(
              'onSuccess', {'action': 'add_successful', 'result': true})),
          (_) {}));
      return true;
    });
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requestedPaths.add(request.uri.path);
      activeRequests++;
      if (activeRequests > peakRequests) peakRequests = activeRequests;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      if (request.uri.path.contains('missing')) {
        request.response.statusCode = HttpStatus.notFound;
        activeRequests--;
        await request.response.close();
        return;
      }
      final file = request.uri.path.contains('static') ? 'static' : 'animated';
      request.response
          .add(await File('test/fixtures/$file.webp').readAsBytes());
      activeRequests--;
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    messenger.setMockMethodCallHandler(channel, null);
    PathProviderPlatform.instance = originalPaths;
    HttpOverrides.global = originalHttp;
    await directory.delete(recursive: true);
  });

  test('exports animation unchanged with animated metadata and a static tray',
      () async {
    final url = 'http://127.0.0.1:${server.port}/animated.webp';
    await Stickers()
        .addPackToWhatsApp([url, url, url], 'Animated pack', (_, __) {});
    final manifest = jsonDecode(
        await File('${directory.path}/sticker_packs/sticker_packs.json')
            .readAsString());
    final pack = manifest['sticker_packs'][0];
    expect(pack['animated_sticker_pack'], isTrue);
    expect(pack['name'], 'Animated pack');
    final path = '${directory.path}/sticker_packs/${pack['identifier']}';
    final original = await File('test/fixtures/animated.webp').readAsBytes();
    for (final sticker in pack['stickers']) {
      expect(
          await File('$path/${sticker['image_file']}').readAsBytes(), original);
    }
    final trayBytes =
        await File('$path/${pack['tray_image_file']}').readAsBytes();
    final tray = img.decodePng(trayBytes)!;
    expect([tray.width, tray.height, tray.numFrames], [96, 96, 1]);
    expect(trayBytes.length, lessThanOrEqualTo(50 * 1024));
    expect(calls.single.method, 'addStickerPack');
    expect(calls.single.arguments['identifier'], pack['identifier']);
    expect(requestedPaths.length, 3);
  });

  test('downloads concurrently with ordered output and monotonic progress',
      () async {
    final base = 'http://127.0.0.1:${server.port}';
    final urls = List.generate(9, (index) => '$base/animated_$index.webp');
    final progress = <int>[];
    await Stickers().addPackToWhatsApp(urls, 'Parallel pack', (done, total) {
      expect(total, urls.length);
      progress.add(done);
    }, trayIconIndex: 7);
    expect(peakRequests, inInclusiveRange(2, 4));
    expect(requestedPaths,
        unorderedEquals(urls.map((url) => Uri.parse(url).path)));
    expect(progress, List.generate(urls.length, (index) => index + 1));
    final manifest = jsonDecode(
        await File('${directory.path}/sticker_packs/sticker_packs.json')
            .readAsString());
    final pack = manifest['sticker_packs'][0];
    expect(
        (pack['stickers'] as List).map((sticker) => sticker['image_file']),
        List.generate(
            urls.length, (index) => '${pack['identifier']}_$index.webp'));
  });

  test('reuses original animated preview bytes during export', () async {
    final base = 'http://127.0.0.1:${server.port}';
    final urls = List.generate(3, (index) => '$base/preview_$index.webp');
    for (final url in urls) {
      final ready = Completer<void>();
      final stream = StickerImage(url).resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener((image, _) {
        image.dispose();
        if (!ready.isCompleted) ready.complete();
      }, onError: (Object error, StackTrace? stack) {
        if (!ready.isCompleted) ready.completeError(error, stack);
      });
      stream.addListener(listener);
      try {
        await ready.future;
      } finally {
        stream.removeListener(listener);
      }
    }
    expect(requestedPaths.length, 3);
    await Stickers().addPackToWhatsApp(urls, 'Cached pack', (_, __) {});
    expect(requestedPaths.length, 3);
    final manifest = jsonDecode(
        await File('${directory.path}/sticker_packs/sticker_packs.json')
            .readAsString());
    final pack = manifest['sticker_packs'][0];
    final original = await File('test/fixtures/animated.webp').readAsBytes();
    for (final sticker in pack['stickers']) {
      expect(
          await File(
                  '${directory.path}/sticker_packs/${pack['identifier']}/${sticker['image_file']}')
              .readAsBytes(),
          original);
    }
  });

  test('cancellation cleans up and never hands off to WhatsApp', () async {
    final base = 'http://127.0.0.1:${server.port}';
    final urls = List.generate(9, (index) => '$base/cancel_$index.webp');
    final token = CancelToken();
    final progress = <int>[];
    await expectLater(
        Stickers().addPackToWhatsApp(urls, 'Cancelled pack', (done, _) {
          progress.add(done);
          token.cancel('User cancelled');
        }, cancelToken: token),
        throwsA(isA<DioException>().having(
            (error) => CancelToken.isCancel(error), 'cancelled', isTrue)));
    expect(progress, [1]);
    expect(calls, isEmpty);
    expect(await Directory('${directory.path}/sticker_packs').list().toList(),
        isEmpty);
    expect(requestedPaths.length, lessThan(urls.length));
  });

  test('already cancelled imports make no requests', () async {
    final token = CancelToken()..cancel();
    final url = 'http://127.0.0.1:${server.port}/animated.webp';
    await expectLater(
        Stickers().addPackToWhatsApp([url, url, url], 'Cancelled', (_, __) {},
            cancelToken: token),
        throwsA(isA<DioException>()));
    expect(requestedPaths, isEmpty);
    expect(calls, isEmpty);
  });

  test('native launch errors fail the import instead of waiting at completion',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      throw PlatformException(
          code: 'ACTIVITY_ERROR', message: 'WhatsApp is unavailable');
    });
    final url = 'http://127.0.0.1:${server.port}/animated.webp';
    await expectLater(
      Stickers().addPackToWhatsApp([url, url, url], 'Launch failure',
          (_, __) {}).timeout(const Duration(seconds: 5)),
      throwsA(isA<PlatformException>()
          .having((error) => error.code, 'code', 'ACTIVITY_ERROR')),
    );
    expect(calls.length, 1);
  });

  test('WhatsApp validation errors reach the import caller', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      Future.microtask(() => messenger.handlePlatformMessage(
            channel.name,
            const StandardMethodCodec().encodeMethodCall(const MethodCall(
              'onError',
              {
                'action': 'failed',
                'result': false,
                'error': 'Invalid sticker pack'
              },
            )),
            (_) {},
          ));
      return true;
    });
    final url = 'http://127.0.0.1:${server.port}/animated.webp';
    await expectLater(
      Stickers().addPackToWhatsApp([url, url, url], 'Invalid pack',
          (_, __) {}).timeout(const Duration(seconds: 5)),
      throwsA(isA<Exception>().having((error) => error.toString(), 'message',
          contains('Invalid sticker pack'))),
    );
  });

  test('failed downloads stop workers and remove the incomplete pack',
      () async {
    final base = 'http://127.0.0.1:${server.port}';
    final urls = [
      '$base/missing.webp',
      ...List.generate(8, (index) => '$base/animated_$index.webp'),
    ];
    await expectLater(
        Stickers().addPackToWhatsApp(urls, 'Failed pack', (_, __) {}),
        throwsA(isA<Exception>()));
    expect(calls, isEmpty);
    expect(requestedPaths.length, lessThan(urls.length));
    expect(await Directory('${directory.path}/sticker_packs').list().toList(),
        isEmpty);
  });

  test('rejects mixed packs before handing off to WhatsApp', () async {
    final base = 'http://127.0.0.1:${server.port}';
    await expectLater(
        Stickers().addPackToWhatsApp(
            ['$base/animated.webp', '$base/static.webp', '$base/animated.webp'],
            'Mixed pack',
            (_, __) {}),
        throwsFormatException);
    expect(calls, isEmpty);
    expect(
        File('${directory.path}/sticker_packs/sticker_packs.json').existsSync(),
        isFalse);
  });
}
