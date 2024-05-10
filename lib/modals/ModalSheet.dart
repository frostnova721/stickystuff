import 'package:flutter/material.dart';
import 'package:stickystuff/core/types.dart';
import 'package:stickystuff/modals/snackbar.dart';
import 'package:stickystuff/pages/finalPage.dart';

class ModalSheet extends StatefulWidget {
  final StickerSearchModal searchModal;
  const ModalSheet({super.key, required this.searchModal});

  @override
  State<ModalSheet> createState() => _ModalSheetState();
}

class _ModalSheetState extends State<ModalSheet> {
  late StickerSearchModal stickerPack;

  bool hasVideo = false;

  @override
  void initState() {
    stickerPack = widget.searchModal;
    isVideoPresent();
    super.initState();
  }

  void isVideoPresent() {
    for(final item in stickerPack.stickers) {
      if(item.endsWith("webm")) {
        setState(() {
          hasVideo = true;
        });
        
        break;
      }
    }
  }

  // Future<void>

  @override
  Widget build(BuildContext context) {
    final itemWidth = MediaQuery.of(context).size.width / 5.2;
    return Container(
      padding: EdgeInsets.only(
          top: 10,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stickerPack.name,
                style: TextStyle(fontFamily: "PTSans", fontSize: 23),
              ),
              Text(
                stickerPack.author,
                style: TextStyle(
                    fontFamily: "PTSans",
                    fontSize: 14,
                    color: Colors.grey[600]),
              ),
              Container(
                margin: EdgeInsets.only(top: 20),
                height: 270,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      //j represents column and i represents row
                      for (int i = 0;
                          i <= (stickerPack.stickers.length / 4);
                          i++)
                        Row(
                          children: [
                            for (int j = 0; j <= 3; j++)
                              if (i * 4 + j < stickerPack.stickers.length)
                                Container(
                                  margin: EdgeInsets.all(5),
                                  height: itemWidth,
                                  width: itemWidth,
                                  child: Image.network(
                                    stickerPack.stickers[(i * 4 + j)],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.fill,
                                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[50] , child: Center(child: Text("Couldn't load image!"))),
                                    frameBuilder: (context, child, frame,
                                        wasSynchronouslyLoaded) {
                                      if (wasSynchronouslyLoaded) return child;
                                      return AnimatedOpacity(
                                        opacity: frame == null ? 0 : 1,
                                        duration: Duration(milliseconds: 250),
                                        curve: Curves.easeOut,
                                        child: child,
                                      );
                                    },
                                  ),
                                ),
                          ],
                        )
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () {
                if(hasVideo) {
                   showSnackBar(context, "This pack contains animated sticker which isnt supported!", duration: 4);
                   return Navigator.pop(context);
                }
                Navigator.of(context).push(
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 75),
                    reverseTransitionDuration: Duration(milliseconds: 100),
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        FadeTransition(
                      opacity: animation,
                      child: FinalPage(
                        stickerPack: stickerPack,
                      ),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  backgroundColor: Colors.deepPurple[400]),
              child: Text(
                "Add This Pack",
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }
}
