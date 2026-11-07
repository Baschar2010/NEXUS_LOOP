import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class NexusAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  NexusAudioHandler() {
    _player.playbackEventStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  Future<void> loadFile(String path, {String? title}) async {
    final mediaItem = MediaItem(id: path, title: title ?? 'NEXUS LOOP', album: 'NEXUS LOOP');
    this.mediaItem.add(mediaItem);
    await _player.setFilePath(path);
  }

  AudioPlayer get player => _player;
}