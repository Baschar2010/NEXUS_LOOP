import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../controller.dart';
import '../main.dart';
import '../theme.dart';

class PlayerScreen extends StatefulWidget {
  final int startIndex;
  const PlayerScreen({super.key, required this.startIndex});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  late int _index;
  VideoPlayerController? _vc;
  bool _showControls = true;
  bool _inForeground = true;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final c = context.read<NexusController>();
    final vids = c.active.videos;
    _index = vids.isEmpty ? 0 : widget.startIndex.clamp(0, vids.length - 1);
    if (vids.isNotEmpty) unawaited(_loadCurrent());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _inForeground = true;
      final vc = _vc;
      final handler = audioHandler;
      if (vc != null && vc.value.isInitialized && handler != null) {
        final pos = handler.position;
        if (pos > Duration.zero) {
          unawaited(vc.seekTo(pos));
        }
        if (handler.isPlaying) {
          unawaited(vc.play());
        }
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      // Only the muted video is paused. The sound is owned by audio_service,
      // which keeps running with a foreground service + wake lock, so the
      // music continues while the app is minimized or the screen is off.
      _inForeground = false;
      _vc?.pause();
    }
  }

  Future<void> _loadCurrent() async {
    final c = context.read<NexusController>();
    final vids = c.active.videos;
    if (vids.isEmpty) return;

    final token = ++_loadToken;
    final v = vids[_index.clamp(0, vids.length - 1)];

    final previous = _vc;
    _vc = null;
    previous?.removeListener(_onTick);
    await previous?.dispose();
    if (!mounted || token != _loadToken) return;

    final vc = VideoPlayerController.file(
      File(v.path),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _vc = vc;
    try {
      await vc.initialize();
    } catch (_) {
      return;
    }
    if (!mounted || token != _loadToken) {
      await vc.dispose();
      return;
    }

    await vc.setVolume(0); // the audible sound comes from audio_service
    await vc.setLooping(false);
    vc.addListener(_onTick);

    final handler = audioHandler;
    if (handler != null) {
      final sameTrack = handler.currentPath == v.path;
      if (!sameTrack) {
        try {
          await handler.loadFile(v.path, title: v.name);
        } catch (_) {}
        handler.setVolume(c.volume);
        unawaited(handler.play());
      } else {
        handler.setVolume(c.volume);
        if (!handler.isPlaying) unawaited(handler.play());
      }
      final pos = handler.position;
      if (pos > Duration.zero) {
        try {
          await vc.seekTo(pos);
        } catch (_) {}
      }
    }

    if (_inForeground) unawaited(vc.play());
    if (mounted) setState(() {});
  }

  void _onTick() {
    final vc = _vc;
    if (vc == null) return;
    if (_inForeground &&
        vc.value.isInitialized &&
        vc.value.duration > Duration.zero &&
        vc.value.position >= vc.value.duration) {
      _next();
      return;
    }
    if (mounted) setState(() {});
  }

  void _next() {
    final c = context.read<NexusController>();
    final vids = c.active.videos;
    if (vids.isEmpty) return;
    _index = (_index + 1) % vids.length;
    unawaited(_loadCurrent());
  }

  void _prev() {
    final c = context.read<NexusController>();
    final vids = c.active.videos;
    if (vids.isEmpty) return;
    _index = (_index - 1 + vids.length) % vids.length;
    unawaited(_loadCurrent());
  }

  @override
  void dispose() {
    _loadToken++;
    WidgetsBinding.instance.removeObserver(this);
    final vc = _vc;
    _vc = null;
    vc?.removeListener(_onTick);
    vc?.dispose();
    // Playback is intentionally NOT stopped here. Leaving the player screen
    // must keep the music running (Spotify behaviour). The user stops it from
    // the media notification or the mini player on the home screen.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NexusController>();
    final vids = c.active.videos;
    if (vids.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ),
      );
    }
    final v = vids[_index.clamp(0, vids.length - 1)];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        onHorizontalDragEnd: (d) {
          if (d.primaryVelocity == null) return;
          if (d.primaryVelocity! < 0) {
            _next();
          } else {
            _prev();
          }
        },
        child: Stack(
          children: [
            Center(
              child: _vc != null && _vc!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _vc!.value.aspectRatio,
                      child: VideoPlayer(_vc!),
                    )
                  : const CircularProgressIndicator(color: NexusColors.green),
            ),
            // left/right tap zones
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _prev,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _next,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
            if (_showControls) ...[
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      v.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_vc != null && _vc!.value.isInitialized)
                      VideoProgressIndicator(
                        _vc!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: NexusColors.green,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.skip_previous,
                            color: Colors.white,
                          ),
                          onPressed: _prev,
                        ),
                        IconButton(
                          icon: Icon(
                            _vc != null && _vc!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 36,
                          ),
                          onPressed: () {
                            if (_vc == null) return;
                            if (_vc!.value.isPlaying) {
                              _vc!.pause();
                              audioHandler?.pause();
                            } else {
                              _vc!.play();
                              audioHandler?.play();
                            }
                            setState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next,
                            color: Colors.white,
                          ),
                          onPressed: _next,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
