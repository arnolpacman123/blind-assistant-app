import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:pedometer/pedometer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:blind_assistant_app/pages/object_detector/object_detector_page.dart';

class SpeakService {
  static stt.SpeechToText _speechToText = stt.SpeechToText();
  static FlutterTts _fluttertts = FlutterTts();
  static bool isListening = false;
  static Battery _battery = Battery();

  static late Stream<StepCount> _stepCountStream;
  static late Stream<PedestrianStatus> _pedestrianStatusStream;
  static String steps = "?";
  static String status = "?";

  static Future<void> listen() async {
    if (!isListening) {
      await speak("Micrófono activado.");
      await Future.delayed(const Duration(seconds: 2));
      bool available = await _speechToText.initialize(
        onStatus: (status) {},
        onError: (errorNotification) => {},
      );
      if (available) {
        isListening = true;
        await _speechToText.listen(
          onResult: (result) async {
            if (result.finalResult) {
              await analyzeMessage(result.recognizedWords);
              isListening = false;
              _speechToText.stop();
            }
          },
          listenFor: const Duration(seconds: 5),
          pauseFor: const Duration(seconds: 5),
          partialResults: false,
          cancelOnError: true,
        );
      }
    } else {
      isListening = false;
      await speak("Micrófono desactivado.");
      _speechToText.stop();
    }
  }

  static Future<void> speak(String text) async {
    await _fluttertts.setLanguage("es-ES");
    await _fluttertts.setPitch(1);
    await _fluttertts.speak(text);
  }

  static Future<void> analyzeMessage(String recognizedWords) async {
    recognizedWords = recognizedWords.toLowerCase();

    if (recognizedWords.contains("batería") ||
        recognizedWords.contains("bateria")) {
      await speakBatteryLevel();
    } else if (recognizedWords.contains("hora")) {
      await speakTime();
    } else if (recognizedWords.contains("fecha")) {
      await speakDate();
    } else if (recognizedWords.contains("día") ||
        recognizedWords.contains("dia")) {
      await speakDay();
    } else if (recognizedWords.contains("mes")) {
      await speakMonth();
    } else if (recognizedWords.contains("año")) {
      await speakYear();
    } else if (recognizedWords.contains("mi información") ||
        recognizedWords.contains("mi informacion") ||
        recognizedWords.contains("mi ubicación") ||
        recognizedWords.contains("mi ubicacion")) {
      await speakMyInformation();
    } else if (recognizedWords.contains("cámara") ||
        recognizedWords.contains("camara")) {
      await speak("Abriendo cámara.");
      Get.to(const ObjectDetectorPage());
    } else if (recognizedWords.contains("volver")) {
      await speak("Volviendo a la pantalla principal.");
      Get.back();
    }
  }

  static Future<void> speakBatteryLevel() async {
    int batteryLevel = await _battery.batteryLevel;
    await speak("La batería está al $batteryLevel por ciento.");
  }

  static Future<void> speakTime() async {
    DateTime now = DateTime.now();
    String hour = now.hour.toString();
    String minute = now.minute.toString();
    await speak("Son las $hour horas con $minute minutos.");
  }

  static Future<void> speakDate() async {
    DateTime now = DateTime.now();
    String day = now.day.toString();
    String month = now.month.toString();
    String year = now.year.toString();
    await speak("Hoy es $day de $month de $year.");
  }

  static Future<void> speakDay() async {
    DateTime now = DateTime.now();
    // Devolver el día de la semana en español
    int day = now.weekday;
    // Devolver la fecha en español
    String date = now.day.toString();
    // Devolver el mes en español
    int month = now.month;
    String year = now.year.toString();
    final days = {
      0: "domingo",
      1: "lunes",
      2: "martes",
      3: "miércoles",
      4: "jueves",
      5: "viernes",
      6: "sábado",
    };
    final months = {
      1: "enero",
      2: "febrero",
      3: "marzo",
      4: "abril",
      5: "mayo",
      6: "junio",
      7: "julio",
      8: "agosto",
      9: "septiembre",
      10: "octubre",
      11: "noviembre",
      12: "diciembre",
    };
    await speak("Hoy es ${days[day]}, $date de ${months[month]} de $year.");
  }

  static Future<void> speakMonth() async {
    DateTime now = DateTime.now();
    String month = now.month.toString();
    await speak("Estamos en $month.");
  }

  static Future<void> speakYear() async {
    DateTime now = DateTime.now();
    String year = now.year.toString();
    await speak("Estamos en el año $year.");
  }

  static Future<void> initializeService() async {
    _speechToText = stt.SpeechToText();
    _fluttertts = FlutterTts();
    isListening = false;
    _battery = Battery();
    initPlatformState();
  }

  static Future<void> speakMyInformation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    String steps1 = "pasos: $steps";
    String latitude = "latitud: ${position.latitude.toStringAsFixed(2)}";
    String longitude = "longitud: ${position.longitude.toStringAsFixed(2)}";
    String speed =
        "velocidad: ${position.speed.toStringAsFixed(2)} kilómetros por hora";
    String address = "dirección: ${placemarks.first.street}";
    String street = "calle: ${placemarks.first.thoroughfare}";
    String locality = "localidad: ${placemarks.first.locality}";
    String subAdministrativeArea =
        "provincia: ${placemarks.first.subAdministrativeArea}";
    String streetNumber =
        "número: ${placemarks.isNotEmpty ? placemarks.first.subThoroughfare : "desconocido"}";
    String message =
        "Su información de ubicación es la siguiente: $steps1, $latitude, $longitude, $speed, $address, "
        "$street, $locality, $subAdministrativeArea, $streetNumber.";
    await speak(message);
  }

  static void initPlatformState() {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream.listen(
      (event) {
        status = event.status;
      },
    ).onError(
      (error) {
        status = "Pedómetro no disponible";
      },
    );

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(
      (event) {
        steps = event.steps.toString();
      },
    ).onError(
      (error) {
        steps = 'Contador no disponible';
      },
    );
  }
}
