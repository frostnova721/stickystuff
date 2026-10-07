import 'dart:collection';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

extension StickerCancellation on CancelToken {
  void throwIfCancellationRequested() {
    if (isCancelled) throw cancelError!;
  }
}

/// Keeps original encoded images, including every animation frame, for export.
class StickerImageCache {
  static final shared = StickerImageCache();
  StickerImageCache({this.maxBytes = 20 * 1024 * 1024});

  final int maxBytes;
  final _entries = LinkedHashMap<String, (DateTime, Uint8List)>();
  int _size = 0;

  Uint8List? get(String url) {
    final entry = _entries.remove(url);
    if (entry == null) return null;
    if (DateTime.now().difference(entry.$1) > const Duration(minutes: 10)) {
      _size -= entry.$2.length;
      return null;
    }
    _entries[url] = entry;
    return entry.$2;
  }

  void put(String url, Uint8List bytes) {
    final old = _entries.remove(url);
    if (old != null) _size -= old.$2.length;
    if (bytes.length > maxBytes) return;
    while (_size + bytes.length > maxBytes && _entries.isNotEmpty) {
      _size -= _entries.remove(_entries.keys.first)!.$2.length;
    }
    _entries[url] = (DateTime.now(), bytes);
    _size += bytes.length;
  }

  void clear() {
    _entries.clear();
    _size = 0;
  }

  Future<Uint8List> load(String url, Dio dio,
      {CancelToken? cancelToken}) async {
    cancelToken?.throwIfCancellationRequested();
    final cached = get(url);
    if (cached != null) return cached;
    final response = await dio.get<List<int>>(url,
        options: Options(responseType: ResponseType.bytes),
        cancelToken: cancelToken);
    cancelToken?.throwIfCancellationRequested();
    final bytes = Uint8List.fromList(response.data!);
    put(url, bytes);
    return bytes;
  }
}

class StickerImage extends ImageProvider<StickerImage> {
  const StickerImage(this.url);
  final String url;

  @override
  Future<StickerImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
      StickerImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1);
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ));
    try {
      final bytes = await StickerImageCache.shared.load(url, dio);
      return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  bool operator ==(Object other) => other is StickerImage && other.url == url;
  @override
  int get hashCode => url.hashCode;
}
