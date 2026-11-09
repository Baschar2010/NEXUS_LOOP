import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:nexus_loop/app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'audio_handler.dart';

NexusAudioHandler? audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Permission.notification.request();
  } catch (_) {}
  audioHandler = await AudioService.init(
    builder: () => NexusAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.nexusloop.nexus_loop_app.audio',
      androidNotificationChannelName: 'NEXUS LOOP Wiedergabe',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidShowNotificationBadge: false,
    ),
  );
  runApp(const NexusLoopApp());
}
