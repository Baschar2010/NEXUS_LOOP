import 'dart:io';

class Playlist {
  final int? id;
  String name;
  List<VideoItem> videos;
  Playlist({this.id, required this.name, List<VideoItem>? videos})
      : videos = videos ?? [];

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
}

class VideoItem {
  int? id;
  int playlistId;
  String path;
  String name;
  int sizeBytes;
  int durationMs;
  int orderIndex;

  VideoItem({
    this.id,
    required this.playlistId,
    required this.path,
    required this.name,
    this.sizeBytes = 0,
    this.durationMs = 0,
    this.orderIndex = 0,
  });

  bool get exists => File(path).existsSync();
  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get durationLabel {
    final d = Duration(milliseconds: durationMs);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$m:$s';
    return '$m:$s';
  }
}