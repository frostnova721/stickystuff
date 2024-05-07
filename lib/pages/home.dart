import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stickystuff/core/stickers.dart';
import 'package:stickystuff/modals/ModalSheet.dart';
import 'package:stickystuff/modals/snackbar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future<void> getStickers(String stickerPackUrl) async {
    setState(() {
      _searchError = false;
      _searching = true;
    });
    try {
      final res = await Stickers().fetchStickers(stickerPackUrl);
      if (res == null) {
        _searching = false;
        return;
      }
      if (mounted) {
        setState(() {
          _searching = false;
        });
        showModalBottomSheet(
            context: context,
            showDragHandle: true,
            // backgroundColor: ,
            builder: (context) {
              return ModalSheet(
                searchModal: res,
              );
            });
      }
    } catch (err) {
      print(err);
      if (mounted) {
        setState(() {
          _searching = false;
          _searchError = true;
        });
        showSnackBar(context, "Couldnt fetch the sticker pack! ${err.toString()}");
      }
    }
  }

  bool _searching = false;
  int currentIndex = 0;
  bool _searchError = false;
  late TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[200],
        title: Text(
          "stickystuff",
          style: TextStyle(fontFamily: "PTSans", fontSize: 24),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        unselectedItemColor: Colors.grey[700],
        onTap: (value) => setState(() {
          currentIndex = value;
        }),
        items: [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: "home"),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.info_circle), label: "info"),
        ],
      ),
      backgroundColor: Colors.deepPurple[100],
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: currentIndex == 0 ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 300,
                  margin: EdgeInsets.only(right: 10),
                  child: TextField(
                    onSubmitted: (val) => getStickers(val),
                    controller: textEditingController,
                    autocorrect: false,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(right: 10, left: 10),
                      labelText: "pack link",
                      hintText: "Telegram Pack Link",
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                              color: _searchError
                                  ? Colors.red
                                  : Colors.deepPurple[900]!)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: _searchError
                              ? Colors.red
                              : Colors.deepPurple[400]!,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_searching)
                  Container(
                    height: 25,
                    width: 25,
                    child: CircularProgressIndicator(),
                  )
              ],
            ),
            Container(
              margin: EdgeInsets.only(top: 15),
              child: ElevatedButton(
                onPressed: () {
                  getStickers(textEditingController.text);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[500],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                child: Text(
                  "search",
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),
            ),
          ],
        ) : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: Text("app: stickystuff \nversion: 1.0.0 \nhacked: true", style: TextStyle(fontFamily: "Ubuntu", fontSize: 17),),),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text("PS: dont use animated stickers. it sucks"),
            ),
          ],
        )
      ),
    );
  }
}
