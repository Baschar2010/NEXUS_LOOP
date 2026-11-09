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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final c = context.read<NexusController>();
    _index = widget.startIndex.clamp(0, c.active.videos.length - 1);
    _loadCurrent();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final pos = audioHandler?.position;
      if (pos != null && _vc != null && _vc!.value.isInitialized) {
        _vc!.seekTo(pos);
      }
      if (audioHandler?.player.playing ?? false) {
        _vc?.play();
      }
    } else {
      // App left the foreground: audio keeps playing via audio_service.
      _vc?.pause();
    }
  }

  Future<void> _loadCurrent() async {
    final c = context.read<NexusController>();
    final vids = c.active.videos;
    if (vids.isEmpty) return;
    _vc?.dispose();
    final v = vids[_index];
    _vc = VideoPlayerController.file(File(v.path));
    await _vc!.initialize();
    _vc!.setVolume(0); // audio handled by audio_service
    if (c.loopEnabled) {
      _vc!.setLooping(false);
    }
    _vc!.addListener(_onTick);
    _vc!.play();
    try {
      await audioHandler?.pause();
      await audioHandler?.loadFile(v.path, title: v.name);
      await audioHandler?.play();
      audioHandler?.setVolume(c.volume);
    } catch (_) {}
    setState(() {});
  }

  void _onTick() {
    final vc = _vc;
    if (vc == null) return;
    if (vc.value.isInitialized && vc.value.position >= vc.value.duration && vc.value.duration > Duration.zero) {
      _next();
    }
    if (mounted) setState(() {});
  }

  void _next() {
    final c = context.read<NexusController>();
    final vids = c.active.videos;
    if (vids.isEmpty) return;
    _index = (_index + 1) % vids.length;
    _loadCurrent();
  }

  void _prev() {
    final c = context.read<NexusController>();
    final vids = c.active.videos;
    if (vids.isEmpty) return;
    _index = (_index - 1 + vids.length) % vids.length;
    _loadCurrent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vc?.removeListener(_onTick);
    _vc?.dispose();
    audioHandler?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NexusController>();
    final vids = c.active.videos;
    if (vids.isEmpty) {
      return Scaffold(backgroundColor: Colors.black, body: Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Schließen'))));
    }
    final v = vids[_index];

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
                Expanded(child: GestureDetector(onTap: _prev, child: Container(color: Colors.transparent))),
                Expanded(child: GestureDetector(onTap: _next, child: Container(color: Colors.transparent))),
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
                    Text(v.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (_vc != null && _vc!.value.isInitialized)
                      VideoProgressIndicator(_vc!, allowScrubbing: true, colors: const VideoProgressColors(playedColor: NexusColors.green)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: _prev),
                        IconButton(
                          icon: Icon(_vc != null && _vc!.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36),
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
                        IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: _next),
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
