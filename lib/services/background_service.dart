import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:blind_assistant_app/services/shake_service.dart';
import 'package:blind_assistant_app/services/speak_service.dart';

class BackgroundService {
  static Future<void> initializeService() async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    final service = FlutterBackgroundService();
    await ShakeService.initShakeListen();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isIOS || Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          iOS: DarwinInitializationSettings(),
          android: AndroidInitializationSettings('ic_bg_service_small'),
        ),
      );
    }

    // await service.configure(
    //   androidConfiguration: AndroidConfiguration(
    //     // this will be executed when app is in foreground or background in separated isolate
    //     onStart: onStart,

    //     // auto start service
    //     autoStart: true,
    //     isForegroundMode: true,

    //     notificationChannelId: 'my_foreground',
    //     initialNotificationTitle: 'AWESOME SERVICE',
    //     initialNotificationContent: 'Initializing',
    //     foregroundServiceNotificationId: 888,
    //   ),
    //   iosConfiguration: IosConfiguration(
    //     // auto start service
    //     autoStart: true,

    //     // this will be executed when app is in foreground in separated isolate
    //     onForeground: onStart,

    //     // you have to enable background fetch capability on xcode project
    //     onBackground: onIosBackground,
    //   ),
    // );

    // service.startService();
  }

 

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Only available for flutter 3.0.0 and later
    DartPluginRegistrant.ensureInitialized();

    // For flutter prior to version 3.0.0
    // We have to register the plugin manually

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    await SpeakService.speak(
      "Bienvenido a tu aplicación asistente. Agita el teléfono para comunicarte conmigo.",
    );

    // bring to foreground
    Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            // if you don't using custom notification, uncomment this
            service.setForegroundNotificationInfo(
              title: "My App Service",
              content: "Updated at ${DateTime.now()}",
            );
          }
        }
      },
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    return true;
  }
}
