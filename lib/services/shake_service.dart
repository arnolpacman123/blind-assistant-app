import 'package:shake/shake.dart';

import 'package:blind_assistant_app/services/speak_service.dart';

class ShakeService {
  static ShakeDetector detector = ShakeDetector.waitForStart(
    onPhoneShake: () async {
      await SpeakService.initializeService();
      await SpeakService.listen();
    },
  );

  static Future<void> initShakeListen() async {
    detector = ShakeDetector.waitForStart(
      onPhoneShake: () async {
        await SpeakService.initializeService();
        await SpeakService.listen();
      },
    );
  }

  static void startListening() {
    detector.startListening();
  }

  static void stopListening() {
    detector.stopListening();
  }
}