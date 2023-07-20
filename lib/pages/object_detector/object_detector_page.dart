import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:blind_assistant_app/services/shake_service.dart';
import 'package:blind_assistant_app/services/speak_service.dart';
import 'camera_view.dart';
import 'painters/object_detector_painter.dart';

class ObjectDetectorPage extends StatefulWidget {
  const ObjectDetectorPage({super.key});

  @override
  State<ObjectDetectorPage> createState() => _ObjectDetectorPage();
}

class _ObjectDetectorPage extends State<ObjectDetectorPage>
    with WidgetsBindingObserver {
  late ObjectDetector _objectDetector;
  bool _canProcess = false;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;

  final _sourceLanguage = TranslateLanguage.english;
  final _targetLanguage = TranslateLanguage.spanish;
  late final _onDeviceTranslator = OnDeviceTranslator(
    sourceLanguage: _sourceLanguage,
    targetLanguage: _targetLanguage,
  );

  Future<String> translateText(String text) async {
    final inputText = text;
    final translatedText = await _onDeviceTranslator.translateText(inputText);
    return translatedText;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDetector(DetectionMode.stream);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ShakeService.stopListening();
      ShakeService.startListening();
    }

    if (state == AppLifecycleState.resumed) {
      ShakeService.stopListening();
      ShakeService.startListening();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    _canProcess = false;
    _objectDetector.close();
    _onDeviceTranslator.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'Reconocimiento de Objetos',
      customPaint: _customPaint,
      text: _text,
      onImage: (inputImage) {
        processImage(inputImage);
      },
      onScreenModeChanged: _onScreenModeChanged,
      initialDirection: CameraLensDirection.back,
    );
  }

  void _onScreenModeChanged(ScreenMode mode) {
    switch (mode) {
      case ScreenMode.gallery:
        _initializeDetector(DetectionMode.single);
        return;

      case ScreenMode.liveFeed:
        _initializeDetector(DetectionMode.stream);
        return;
    }
  }

  void _initializeDetector(DetectionMode mode) async {
    print('Set detector in mode: $mode');

    // uncomment next lines if you want to use the default model
    // final options = ObjectDetectorOptions(
    //     mode: mode,
    //     classifyObjects: true,
    //     multipleObjects: true);
    // _objectDetector = ObjectDetector(options: options);

    // uncomment next lines if you want to use a local model
    // make sure to add tflite model to assets/ml
    const path = 'assets/ml/object_labeler.tflite';
    final modelPath = await _getModel(path);
    final options = LocalObjectDetectorOptions(
      mode: mode,
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);

    // uncomment next lines if you want to use a remote model
    // make sure to add model to firebase
    // final modelName = 'bird-classifier';
    // final response =
    //     await FirebaseObjectDetectorModelManager().downloadModel(modelName);
    // print('Downloaded: $response');
    // final options = FirebaseObjectDetectorOptions(
    //   mode: mode,
    //   modelName: modelName,
    //   classifyObjects: true,
    //   multipleObjects: true,
    // );
    // _objectDetector = ObjectDetector(options: options);

    _canProcess = true;
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final objects = await _objectDetector.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = ObjectDetectorPainter(
        objects,
        inputImage.metadata!.rotation,
        inputImage.metadata!.size,
      );
      _customPaint = CustomPaint(painter: painter);
      for (final object in objects) {
        for (final label in object.labels) {
          String textSpanish = await translateText(label.text);
          await SpeakService.speak(textSpanish);
          await Future.delayed(
            const Duration(seconds: 2),
          );
          break;
        }
      }
    } else {
      String text = 'Objects found: ${objects.length}\n\n';
      for (final object in objects) {
        text +=
            'Object:  trackingId: ${object.trackingId} - ${object.labels.map((e) => e.text)}\n\n';
      }
      _text = text;
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<String> _getModel(String assetPath) async {
    if (io.Platform.isAndroid) {
      return 'flutter_assets/$assetPath';
    }
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await io.Directory(dirname(path)).create(recursive: true);
    final file = io.File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }
}
