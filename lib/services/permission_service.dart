import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> initializeService() async {
    await Permission.camera.request();
    await Permission.microphone.request();
    await Permission.location.request();
    await Permission.storage.request();
    await Permission.activityRecognition.request();
    await Permission.sensors.request();
  }
}
