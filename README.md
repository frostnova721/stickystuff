# stickystuff

An app to add Telegram sticker packs to Whatsapp.

made with ❤️ using flutter

## Disclaimer

This app (stickystuff) is only made for educational purposes and serves no ill intend!

## Limitaions
- Supports static and animated WebP stickers; animated files are preserved without re-encoding.
- Telegram TGS, WebM and GIF sources require conversion to animated WebP before import.
- Animated input must already be 512 x 512, at most 500 KB and at most 10 seconds, with each frame lasting at least 8 ms. Invalid animations are rejected, never flattened.
- Each pack must contain 3-30 stickers of one type (static or animated). Static stickers are resized/compressed to 512 x 512 and at most 100 KB.
- Tray icons are static 96 x 96 PNGs from the first frame, at most 50 KB.
- Design artwork with a transparent background and a complete first frame: WhatsApp rests on that frame after playback.

Requirements: [WhatsApp's official Android sticker specification](https://github.com/WhatsApp/stickers/blob/main/Android/README.md).
- Cannot add morethan 30 stickers from a pack (limitation from whatsapp)

## Credits
special thanks to this package:
[flutter_whatsapp_stickers](https://pub.dev/packages/flutter_whatsapp_stickers) by [Vince Kruger](https://github.com/vincekruger)