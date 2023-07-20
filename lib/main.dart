import 'dart:async';

import 'package:blind_assistant_app/services/camera_service.dart';
import 'package:blind_assistant_app/services/permission_service.dart';
import 'package:blind_assistant_app/services/shake_service.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:blind_assistant_app/pages/home/home_page.dart';
import 'package:blind_assistant_app/services/background_service.dart';
import 'package:blind_assistant_app/services/speak_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PermissionService.initializeService();
  await SpeakService.initializeService();
  await BackgroundService.initializeService();
  // await ShakeService.initShakeListen();
  await CameraService.initializeService();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
