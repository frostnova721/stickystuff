import 'package:flutter/material.dart';
import 'package:stickystuff/core/stickers.dart';
import 'package:stickystuff/core/types.dart';
import 'package:stickystuff/modals/snackbar.dart';

class FinalPage extends StatefulWidget {
  final StickerSearchModal stickerPack;
  const FinalPage({super.key, required this.stickerPack});

  @override
  State<FinalPage> createState() => _FinalPageState();
}

class _FinalPageState extends State<FinalPage> {
  int selectedIconIndex = 0;

  TextEditingController packNameController = TextEditingController();

  TextEditingController authorNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[100],
      body: Container(
        padding:
            EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                        tooltip: "close",
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          size: 30,
                        ))
                  ],
                ),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "pack icon",
                    style: TextStyle(fontFamily: "PTSans", fontSize: 18),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    margin: EdgeInsets.only(top: 15),
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                          image: NetworkImage(widget.stickerPack.stickers[selectedIconIndex]), fit: BoxFit.cover),
                    ),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Material(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(15)),
                        clipBehavior: Clip.hardEdge,
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (context) => StatefulBuilder(
                                builder: (context, setChildState) {
                                  final itemWidth = MediaQuery.of(context).size.width / 5.2;
                                  return Container(
                                    padding: EdgeInsets.only(
                                        left: 25, right: 25, bottom: MediaQuery.of(context).padding.bottom),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Select Icon",
                                          style: TextStyle(fontFamily: "PTSans", fontSize: 22),
                                        ),
                                        Container(
                                          padding: EdgeInsets.only(top: 20),
                                          height: 400,
                                          child: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                //j represents column and i represents row
                                                for (int i = 0; i <= (widget.stickerPack.stickers.length / 4); i++)
                                                  Row(
                                                    children: [
                                                      for (int j = 0; j <= 3; j++)
                                                        if (i * 4 + j < widget.stickerPack.stickers.length)
                                                          GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                selectedIconIndex = i * 4 + j;
                                                              });
                                                              setChildState(() {});
                                                            },
                                                            child: Container(
                                                              margin: EdgeInsets.all(5),
                                                              height: itemWidth,
                                                              width: itemWidth,
                                                              child: Container(
                                                                decoration: BoxDecoration(
                                                                  border: selectedIconIndex == (i * 4 + j)
                                                                      ? Border.all(
                                                                          color: Colors.deepPurpleAccent,
                                                                          width: 5,
                                                                        )
                                                                      : null,
                                                                ),
                                                                child: Image.network(
                                                                  widget.stickerPack.stickers[(i * 4 + j)],
                                                                  width: 50,
                                                                  height: 50,
                                                                  fit: BoxFit.cover,
                                                                  frameBuilder:
                                                                      (context, child, frame, wasSynchronouslyLoaded) {
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
                                  );
                                },
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.8),
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(15))),
                            height: 30,
                            width: 30,
                            child: Icon(
                              Icons.edit_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                    margin: EdgeInsets.only(top: 30, right: 10, left: 10),
                    child: Text(
                      "Pack name",
                      style: TextStyle(fontFamily: "Ubuntu"),
                    )),
                Container(
                  margin: EdgeInsets.only(right: 20, left: 20),
                  child: TextField(
                    controller: packNameController,
                    decoration: InputDecoration(
                        hintText: widget.stickerPack.name,
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide())),
                  ),
                ),
                Container(
                    margin: EdgeInsets.only(top: 30, right: 10, left: 10),
                    child: Text(
                      "author",
                      style: TextStyle(fontFamily: "Ubuntu"),
                    )),
                Container(
                  margin: EdgeInsets.only(right: 20, left: 20),
                  child: TextField(
                    controller: authorNameController,
                    decoration: InputDecoration(
                        hintText: widget.stickerPack.author,
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide())),
                  ),
                ),
                if(widget.stickerPack.stickers.length > 30)
                Container(
                  padding: EdgeInsets.fromLTRB(15, 15, 15, 0),
                  child: Text("*This pack contains morethan 30 stickers. Only the first 30 will be selected for the pack", style: TextStyle(color: Colors.red[400]),),
                )
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                showSnackBar(context, "processing...");
                try {
                  await Stickers().addPackToWhatsApp(
                      widget.stickerPack.stickers,
                      packNameController.value.text.isNotEmpty
                          ? packNameController.value.text
                          : widget.stickerPack.name.toLowerCase(),
                      author:
                          authorNameController.value.text.isNotEmpty ? authorNameController.value.text : "stickystuff",
                      trayIconIndex: selectedIconIndex);
                } catch (err) {
                  print(err);
                  showSnackBar(context, "$err");
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[400],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text(
                "Add To WhatsApp",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
