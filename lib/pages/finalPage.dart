import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:stickystuff/core/sort.dart';
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

  List<int> selectedStickersIndices = [];

  bool addOnProgress = false;
  bool addAsSeperatePacks = false;
  bool selectAll = false;

  int downloadedStickers = 0;
  int totalStickers = 0;
  int currentPack = 0;

  @override
  void initState() {
    selectedStickersIndices = List.generate(widget.stickerPack.stickers.length > 30 ? 30 : widget.stickerPack.stickers.length, (index) => index);
    super.initState();
  }

  void updateDownloadProgress(int downloadedItems, int totalItems) {
    if (mounted)
      setState(() {
        downloadedStickers = downloadedItems;
        totalStickers = totalItems;
      });
  }

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
                              builder: (context) => _iconSelect(),
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
                if (widget.stickerPack.stickers.length > 30)
                  Container(
                    padding: EdgeInsets.fromLTRB(15, 15, 15, 0),
                    child: Text(
                      "*This pack contains morethan 30 stickers.\nEnable \"seperate packs\" to add more as another pack",
                      style: TextStyle(color: Colors.red[400]),
                    ),
                  ),
                Container(
                  padding: EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.stickerPack.stickers.length > 30)
                        SizedBox(
                          height: 20,
                          width: 25,
                          child: Checkbox(
                            value: addAsSeperatePacks,
                            onChanged: (val) => setState(() {
                              if (selectedStickersIndices.length > 30 && !val!)
                                selectedStickersIndices = selectedStickersIndices.sublist(0, 30);
                              addAsSeperatePacks = val ?? false;
                            }),
                          ),
                        ),
                      if (widget.stickerPack.stickers.length > 30)
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Text(
                            "seperate packs",
                            style: TextStyle(fontFamily: "Ubuntu"),
                          ),
                        ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple[400],
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            showDragHandle: true,
                            context: context,
                            builder: (context) => _cherryPick(),
                          );
                        },
                        child: Text(
                          "cherry pick",
                          style: TextStyle(color: Colors.white, fontFamily: "PTSans"),
                        ),
                      ),
                    ],
                  ),
                ),
                if (addOnProgress && totalStickers != downloadedStickers)
                  Container(
                    margin: EdgeInsets.only(top: 35, left: 25, right: 25),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            LoadingAnimationWidget.halfTriangleDot(color: Colors.deepPurple[500]!, size: 30),
                            Padding(
                              padding: const EdgeInsets.only(left: 15),
                              child: Text(
                                "Downloading Stickers...",
                                style: TextStyle(fontFamily: "PTSans", fontSize: 18),
                              ),
                            )
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 15),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            tween: Tween<double>(
                              begin: 0,
                              end: (downloadedStickers / totalStickers).clamp(0, 1),
                            ),
                            builder: (context, value, _) => LinearProgressIndicator(
                              value: value,
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        Container(
                            margin: EdgeInsets.only(top: 10),
                            child: Text(
                              "pack ${currentPack} ($downloadedStickers / $totalStickers)",
                              style:
                                  TextStyle(fontFamily: "Ubuntu", color: Colors.grey[600], fontWeight: FontWeight.bold),
                            ))
                      ],
                    ),
                  ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                if (addOnProgress) {
                  showSnackBar(context, "This pack is already being added!");
                  return;
                }

                showSnackBar(context, "processing...");

                if (selectedStickersIndices.length == 0) {
                  return showSnackBar(context, "No stickers are selected", removePrevious: true);
                }

                try {
                  selectedStickersIndices =
                      QuickSort().sort(selectedStickersIndices, 0, selectedStickersIndices.length - 1);
                  for (int packNumber = 0; packNumber < selectedStickersIndices.length / 30.ceil(); packNumber++) {
                    setState(() {
                      addOnProgress = true;
                    });
                    currentPack = packNumber + 1;
                    final endIndex = (packNumber + 1) * 30;
                    final pack = selectedStickersIndices
                        .sublist(packNumber * 30,
                            endIndex > selectedStickersIndices.length ? selectedStickersIndices.length : endIndex)
                        .map((e) => widget.stickerPack.stickers[e])
                        .toList();
                    await Stickers().addPackToWhatsApp(
                        pack,
                        packNameController.value.text.isNotEmpty
                            ? "${packNameController.value.text}${currentPack == 1 ? "" : "-$currentPack"}"
                            : "${widget.stickerPack.name.toLowerCase()}${currentPack == 1 ? "" : "-$currentPack"}",
                        (completedDownloads, totalItems) => updateDownloadProgress(completedDownloads, totalItems),
                        author: authorNameController.value.text.isNotEmpty
                            ? authorNameController.value.text
                            : widget.stickerPack.author,
                        trayIconIndex: selectedIconIndex > pack.length ? 0 : selectedIconIndex );
                    setState(() {
                      addOnProgress = false;
                    });
                  }
                } catch (err) {
                  print(err);
                  showSnackBar(context, err.toString());
                  addOnProgress = false;
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

  StatefulBuilder _cherryPick() {
    return StatefulBuilder(
      builder: ((context, setChildState) => Container(
            padding: EdgeInsets.only(left: 25, right: 25, bottom: MediaQuery.of(context).padding.bottom),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Selected ${selectedStickersIndices.length} stickers",
                        style: TextStyle(
                          fontFamily: "PTSans",
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(
                        height: 35,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon:
                              Icon(Icons.select_all_rounded, color: selectAll ? Colors.deepPurple[600] : Colors.black),
                          tooltip: "Select all",
                          onPressed: () {
                            if (selectAll) {
                              selectedStickersIndices = [];
                            } else {
                              for (int i = 0; i < widget.stickerPack.stickers.length; i++) {
                                if (!selectedStickersIndices.contains(i)) {
                                  selectedStickersIndices.add(i);
                                }
                              }
                            }
                            setChildState(() {
                              selectAll = !selectAll;
                            });
                          },
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  height: 350,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10
                    ),
                    itemCount: widget.stickerPack.stickers.length,
                    itemBuilder: (context, index) {
                      bool checked = selectedStickersIndices.contains(index);
                      return GestureDetector(
                        onTap: () {
                          //add stickers to selection if length < 30
                          checked
                              ? selectedStickersIndices.remove(index)
                              : selectedStickersIndices.length < 30
                                  ? selectedStickersIndices.add(index)
                                  : addAsSeperatePacks
                                      ? selectedStickersIndices.add(index)
                                      : null;
                          setChildState(() {});
                        },
                        child: Stack(
                          children: [
                            Container(
                              child: Image.network(
                                widget.stickerPack.stickers[index],
                                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                  if (wasSynchronouslyLoaded) return child;
                                  return AnimatedOpacity(
                                    opacity: frame == null ? 0 : 1,
                                    duration: Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                    child: child,
                                  );
                                },
                                fit: BoxFit.cover,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: checked,
                                    onChanged: (val) {
                                      checked
                                          ? selectedStickersIndices.remove(index)
                                          : selectedStickersIndices.add(index);
                                      setChildState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )),
    );
  }

  StatefulBuilder _iconSelect() {
    return StatefulBuilder(
      builder: (context, setChildState) {
        final itemWidth = MediaQuery.of(context).size.width / 5.2;
        return Container(
          padding: EdgeInsets.only(left: 25, right: 25, bottom: MediaQuery.of(context).padding.bottom),
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
                                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
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
    );
  }
}
