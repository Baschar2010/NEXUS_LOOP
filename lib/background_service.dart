import 'package:flutter/services.dart';

class BackgroundPlayback {
  static const _channel = MethodChannel('nexus_loop/playback');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod('start');
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }
}