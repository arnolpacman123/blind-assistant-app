import 'package:flutter/material.dart';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:blind_assistant_app/services/shake_service.dart';
import 'package:blind_assistant_app/services/speak_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String text = "Stop Service";

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ShakeService.detector.stopListening();
      ShakeService.detector.startListening();
    }

    if (state == AppLifecycleState.resumed) {
      ShakeService.detector.stopListening();
      ShakeService.detector.startListening();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido al Asistente'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Center(
            child: Text(text),
          ),
        ],
      ),
      floatingActionButton: const AvatarGlow(
        animate: true,
        repeat: true,
        endRadius: 80,
        glowColor: Colors.red,
        duration: Duration(days: 1),
        child: FloatingActionButton(
          onPressed: SpeakService.listen,
          child: Icon(Icons.mic),
        ),
      ),
    );
  }
}
