class StickerSearchModal {
  final String name;
  final String author;
  final List<String> stickers;

  StickerSearchModal({required this.author, required this.name, required this.stickers});
}

typedef DownloadProgressCallback = void Function(int completedDownloads, int totalItems);