import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Owns the audio that keeps playing while the app is minimized or the screen
/// is off. audio_service keeps a foreground service + partial wake lock alive
/// for as long as [play] has been requested.
class NexusAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  NexusAudioHandler() {
    _player.playbackEventStream.listen(
      (event) {
        playbackState.add(
          playbackState.value.copyWith(
            controls: [
              if (_player.playing) MediaControl.pause else MediaControl.play,
            ],
            systemActions: const {
              MediaAction.seek,
              MediaAction.seekForward,
              MediaAction.seekBackward,
            },
            androidCompactActionIndices: const [0],
            processingState: _mapProcessingState(_player.processingState),
            playing: _player.playing,
            updatePosition: _player.position,
            bufferedPosition: _player.bufferedPosition,
            speed: _player.speed,
          ),
        );
      },
      onError: (Object error, StackTrace stack) {},
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() async {
    // just_audio's play() future only completes when playback stops again.
    // Never await it, otherwise callers would hang until pause.
    _player.play().catchError((Object _) {});
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    mediaItem.add(null);
    await super.stop();
  }

  Future<void> loadFile(String path, {String? title}) async {
    final duration = await _player.setFilePath(path);
    await _player.setLoopMode(LoopMode.one);
    mediaItem.add(
      MediaItem(
        id: path,
        title: title ?? 'NEXUS LOOP',
        album: 'NEXUS LOOP',
        duration: duration,
      ),
    );
  }

  void setVolume(double volume) {
    _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Duration get position => _player.position;

  bool get isPlaying => _player.playing;

  String? get currentPath => mediaItem.value?.id;

  AudioPlayer get player => _player;

  /// Keep playing when the user swipes the app away from the recent apps list.
  @override
  Future<void> onTaskRemoved() async {}
}
