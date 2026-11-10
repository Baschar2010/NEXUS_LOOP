import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:nexus_loop/app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_handler.dart';

NexusAudioHandler? audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android 13+: the media notification needs the notification permission.
  try {
    await Permission.notification.request();
  } catch (_) {}

  audioHandler = await AudioService.init(
    builder: () => NexusAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.nexusloop.nexus_loop_app.audio',
      androidNotificationChannelName: 'NEXUS LOOP Wiedergabe',
      androidNotificationChannelDescription:
          'Steuerung der Wiedergabe im Hintergrund',
      androidNotificationIcon: 'drawable/ic_stat_nexus',
      notificationColor: Color(0xFF1DB954),
      // Keep the foreground service + wake lock alive even if playback is
      // paused. This prevents Android 12+ from refusing to restart the
      // service later while the app is in the background.
      androidStopForegroundOnPause: false,
      androidNotificationOngoing: false,
      androidShowNotificationBadge: false,
      androidResumeOnClick: true,
      androidNotificationClickStartsActivity: true,
    ),
  );

  runApp(const NexusLoopApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_askBatteryOptimizationExemption());
  });
}

/// Some manufacturers (Xiaomi, Huawei, Samsung, …) kill background audio even
/// with a foreground service. Asking for the battery optimization exemption
/// once makes playback much more reliable with the screen off.
Future<void> _askBatteryOptimizationExemption() async {
  try {
    if (await Permission.ignoreBatteryOptimizations.isGranted) return;
    final prefs = await SharedPreferences.getInstance();
    const key = 'asked_battery_optimization_v201';
    if (prefs.getBool(key) ?? false) return;
    await prefs.setBool(key, true);
    await Permission.ignoreBatteryOptimizations.request();
  } catch (_) {}
}
