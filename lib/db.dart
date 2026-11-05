import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'models.dart';

class NexusDb {
  static final NexusDb instance = NexusDb._();
  NexusDb._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'nexus_loop.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE videos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            playlist_id INTEGER NOT NULL,
            path TEXT NOT NULL,
            name TEXT NOT NULL,
            size_bytes INTEGER NOT NULL DEFAULT 0,
            duration_ms INTEGER NOT NULL DEFAULT 0,
            order_index INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY(playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
          )
        ''');
        // Default playlist
        await db.insert('playlists', {'name': 'Meine Playlist'});
      },
    );
    return _db!;
  }

  // Playlists
  Future<List<Playlist>> loadPlaylists() async {
    final db = await database;
    final pls = await db.query('playlists', orderBy: 'id ASC');
    final result = <Playlist>[];
    for (final r in pls) {
      final vids = await db.query('videos',
          where: 'playlist_id = ?', whereArgs: [r['id']], orderBy: 'order_index ASC');
      result.add(Playlist(
        id: r['id'] as int,
        name: r['name'] as String,
        videos: vids.map((v) => VideoItem(
              id: v['id'] as int,
              playlistId: v['playlist_id'] as int,
              path: v['path'] as String,
              name: v['name'] as String,
              sizeBytes: v['size_bytes'] as int,
              durationMs: v['duration_ms'] as int,
              orderIndex: v['order_index'] as int,
            )).toList(),
      ));
    }
    return result;
  }

  Future<int> createPlaylist(String name) async {
    final db = await database;
    return db.insert('playlists', {'name': name});
  }

  Future<void> renamePlaylist(int id, String name) async {
    final db = await database;
    await db.update('playlists', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePlaylist(int id) async {
    final db = await database;
    await db.delete('videos', where: 'playlist_id = ?', whereArgs: [id]);
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllVideos(int playlistId) async {
    final db = await database;
    await db.delete('videos', where: 'playlist_id = ?', whereArgs: [playlistId]);
  }

  Future<int> addVideo(VideoItem v) async {
    final db = await database;
    // new videos on top: shift existing
    await db.rawUpdate(
        'UPDATE videos SET order_index = order_index + 1 WHERE playlist_id = ?',
        [v.playlistId]);
    return db.insert('videos', {
      'playlist_id': v.playlistId,
      'path': v.path,
      'name': v.name,
      'size_bytes': v.sizeBytes,
      'duration_ms': v.durationMs,
      'order_index': 0,
    });
  }

  Future<void> deleteVideo(int id) async {
    final db = await database;
    await db.delete('videos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> moveVideo(int videoId, int targetPlaylistId) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE videos SET order_index = order_index + 1 WHERE playlist_id = ?',
        [targetPlaylistId]);
    await db.update('videos', {'playlist_id': targetPlaylistId, 'order_index': 0},
        where: 'id = ?', whereArgs: [videoId]);
  }

  Future<void> reorder(int playlistId, int fromIndex, int toIndex) async {
    final db = await database;
    final vids = await db.query('videos',
        where: 'playlist_id = ?', whereArgs: [playlistId], orderBy: 'order_index ASC');
    final list = vids.map((v) => v['id'] as int).toList();
    if (fromIndex < 0 || fromIndex >= list.length) return;
    if (toIndex < 0 || toIndex >= list.length) return;
    final moved = list.removeAt(fromIndex);
    list.insert(toIndex, moved);
    for (int i = 0; i < list.length; i++) {
      await db.update('videos', {'order_index': i}, where: 'id = ?', whereArgs: [list[i]]);
    }
  }
}