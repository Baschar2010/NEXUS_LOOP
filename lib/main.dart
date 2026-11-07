import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:nexus_loop/app.dart';
import 'audio_handler.dart';

NexusAudioHandler? audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  audioHandler = await AudioService.init(
    builder: () => NexusAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.nexusloop.nexus_loop_app.audio',
      androidNotificationChannelName: 'NEXUS LOOP Audio',
      androidNotificationOngoing: true,
    ),
  );
  runApp(const NexusLoopApp());
}