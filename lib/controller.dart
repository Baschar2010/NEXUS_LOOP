import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'db.dart';

class NexusController extends ChangeNotifier {
  List<Playlist> playlists = [];
  int activeIndex = 0;
  double volume = 1.0;
  bool loopEnabled = true;
  String searchQuery = '';
  bool dbOk = false;

  Playlist get active => playlists.isEmpty
      ? Playlist(name: 'Leer')
      : playlists[activeIndex.clamp(0, playlists.length - 1)];

  Future<void> init() async {
    try {
      playlists = await NexusDb.instance.loadPlaylists();
      if (playlists.isEmpty) {
        final id = await NexusDb.instance.createPlaylist('Meine Playlist');
        playlists = [Playlist(id: id, name: 'Meine Playlist')];
      }
      activeIndex = 0;
      dbOk = true;
    } catch (e) {
      dbOk = false;
    }
    notifyListeners();
  }

  Future<void> reload() async {
    playlists = await NexusDb.instance.loadPlaylists();
    if (activeIndex >= playlists.length) activeIndex = 0;
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    final id = await NexusDb.instance.createPlaylist(name);
    playlists.add(Playlist(id: id, name: name));
    notifyListeners();
  }

  Future<void> renamePlaylist(int index, String name) async {
    final pl = playlists[index];
    if (pl.id == null) return;
    await NexusDb.instance.renamePlaylist(pl.id!, name);
    pl.name = name;
    notifyListeners();
  }

  Future<void> deletePlaylist(int index) async {
    final pl = playlists[index];
    if (pl.id == null) return;
    await NexusDb.instance.deletePlaylist(pl.id!);
    playlists.removeAt(index);
    if (activeIndex >= playlists.length) activeIndex = (playlists.length - 1).clamp(0, 999);
    if (playlists.isEmpty) {
      final id = await NexusDb.instance.createPlaylist('Meine Playlist');
      playlists.add(Playlist(id: id, name: 'Meine Playlist'));
      activeIndex = 0;
    }
    notifyListeners();
  }

  Future<void> deleteAllInActive() async {
    final pl = active;
    if (pl.id == null) return;
    await NexusDb.instance.deleteAllVideos(pl.id!);
    pl.videos.clear();
    notifyListeners();
  }

  Future<void> pickVideos() async {
    final picker = ImagePicker();
    final files = await picker.pickMultipleMedia();
    if (files.isEmpty) return;
    final pl = active;
    if (pl.id == null) return;
    const videoExt = ['mp4', 'webm', 'mov', 'mkv', 'avi', '3gp', 'm4v', 'm4a'];
    for (final f in files) {
      final ext = f.path.split('.').last.toLowerCase();
      if (!videoExt.contains(ext)) continue;
      final file = File(f.path);
      int size = 0;
      try { size = await file.length(); } catch (_) {}
      final item = VideoItem(
        playlistId: pl.id!,
        path: f.path,
        name: p.basename(f.path),
        sizeBytes: size,
      );
      final id = await NexusDb.instance.addVideo(item);
      item.id = id;
      pl.videos.insert(0, item);
    }
    refresh();
  }

  Future<void> deleteVideo(VideoItem v) async {
    if (v.id == null) return;
    await NexusDb.instance.deleteVideo(v.id!);
    active.videos.removeWhere((x) => x.id == v.id);
    notifyListeners();
  }

  Future<void> moveVideo(VideoItem v, int targetPlaylistIndex) async {
    if (v.id == null) return;
    final target = playlists[targetPlaylistIndex];
    if (target.id == null) return;
    await NexusDb.instance.moveVideo(v.id!, target.id!);
    active.videos.removeWhere((x) => x.id == v.id);
    v.playlistId = target.id!;
    target.videos.insert(0, v);
    notifyListeners();
  }

  Future<void> reorderActive(int from, int to) async {
    final pl = active;
    if (pl.id == null) return;
    await NexusDb.instance.reorder(pl.id!, from, to);
    final moved = pl.videos.removeAt(from);
    pl.videos.insert(to, moved);
    notifyListeners();
  }

  void setActive(int i) {
    activeIndex = i.clamp(0, playlists.length - 1);
    notifyListeners();
  }

  void setVolume(double v) {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void toggleLoop() {
    loopEnabled = !loopEnabled;
    notifyListeners();
  }

  void refresh() => notifyListeners();

  Future<void> exportActive() async {
    // Copy files to downloads dir
    try {
      final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final out = Directory(p.join(dir.path, 'NexusLoop_Export'));
      if (!await out.exists()) await out.create(recursive: true);
      for (final v in active.videos) {
        final f = File(v.path);
        if (await f.exists()) {
          await f.copy(p.join(out.path, v.name));
        }
      }
    } catch (_) {}
  }

  List<VideoItem> get filteredVideos {
    if (searchQuery.trim().isEmpty) return active.videos;
    final q = searchQuery.toLowerCase();
    return active.videos.where((v) => v.name.toLowerCase().contains(q)).toList();
  }
}