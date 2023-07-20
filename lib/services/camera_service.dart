import 'package:camera/camera.dart';

class CameraService {
  static List<CameraDescription> cameras = [];

  static Future<void> initializeService() async {
    cameras = await availableCameras();
  }
}
