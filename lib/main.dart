import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stickystuff/pages/home.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StickyStuff());
}

class StickyStuff extends StatefulWidget {
  const StickyStuff({super.key});

  @override
  State<StickyStuff> createState() => _StickyStuffState();
}

class _StickyStuffState extends State<StickyStuff> {
  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(systemNavigationBarColor: Colors.black.withOpacity(0.002)));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    checkAndRequestPermission();
    super.initState();
  }

  void checkAndRequestPermission() async {
    final info = await DeviceInfoPlugin();
    final sdkVersion = (await info.androidInfo).version.sdkInt;
    const manageStorage = Permission.manageExternalStorage;
    if (!(await manageStorage.isPermanentlyDenied) && await manageStorage.isDenied) {
      await manageStorage.request();
    }
    if (sdkVersion > 32) {
      const photos = Permission.photos;
      if (!(await photos.isPermanentlyDenied) && await photos.isDenied) {
        await photos.request();
      }
    } else {
      const storage = Permission.storage;
      if (!(await storage.isPermanentlyDenied) && await storage.isDenied) {
        await storage.request();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'stickystuff',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
