import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import '../update_service.dart';
import '../update_dialog.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool gridView = true;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  Future<void> _checkUpdate() async {
    final service = UpdateService();
    final release = await service.check();
    if (!mounted || release == null) return;
    await showUpdateDialog(context, release);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NexusController>();
    final videos = c.filteredVideos;

    return Scaffold(
      backgroundColor: NexusColors.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: NexusColors.green,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.loop, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('NEXUS LOOP'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(gridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => gridView = !gridView),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context, c),
          ),
        ],
      ),
      body: Column(
        children: [
          // DB OK badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.dbOk ? NexusColors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.dbOk ? NexusColors.green : Colors.red),
                  ),
                  child: Text(
                    c.dbOk ? 'DB OK' : 'DB ERROR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: c.dbOk ? NexusColors.green : Colors.red,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${c.active.videos.length} Videos',
                  style: const TextStyle(color: NexusColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          // Playlist tabs
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: c.playlists.length + 1,
              itemBuilder: (_, i) {
                if (i == c.playlists.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: ActionChip(
                      avatar: const Icon(Icons.add, size: 16, color: NexusColors.text),
                      label: const Text('NEU'),
                      backgroundColor: NexusColors.surface2,
                      side: BorderSide.none,
                      onPressed: () => _newPlaylist(context, c),
                    ),
                  );
                }
                final selected = i == c.activeIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text(c.playlists[i].name),
                    selected: selected,
                    selectedColor: NexusColors.green,
                    backgroundColor: NexusColors.surface2,
                    labelStyle: TextStyle(
                      color: selected ? Colors.black : NexusColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide.none,
                    onSelected: (_) => c.setActive(i),
                  ),
                );
              },
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) { c.searchQuery = v; c.refresh(); },
              style: const TextStyle(color: NexusColors.text),
              decoration: InputDecoration(
                hintText: 'Suche nach Namen…',
                hintStyle: const TextStyle(color: NexusColors.muted),
                prefixIcon: const Icon(Icons.search, color: NexusColors.muted),
                filled: true,
                fillColor: NexusColors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // Video list/grid
          Expanded(
            child: videos.isEmpty
                ? const Center(
                    child: Text('Keine Videos. Tippe + VIDEOS.',
                        style: TextStyle(color: NexusColors.muted)),
                  )
                : gridView
                    ? GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: videos.length,
                        itemBuilder: (_, i) => _VideoCard(video: videos[i], index: i),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: videos.length,
                        itemBuilder: (_, i) => _VideoListTile(video: videos[i], index: i),
                      ),
          ),
          // Bottom action bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const BoxDecoration(
              color: NexusColors.surface,
              border: Border(top: BorderSide(color: NexusColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NexusColors.green,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: const Icon(Icons.video_library, size: 22),
                    label: const Text('VIDEOS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    onPressed: () => c.pickVideos(),
                  ),
                ),
                const SizedBox(width: 6),
                _BigIconBtn(icon: Icons.volume_up, onTap: () => _showVolume(context, c)),
                _BigIconBtn(
                  icon: c.loopEnabled ? Icons.repeat_one : Icons.repeat,
                  color: c.loopEnabled ? NexusColors.green : NexusColors.muted,
                  onTap: () => c.toggleLoop(),
                ),
                _BigIconBtn(icon: Icons.download, onTap: () => c.exportActive()),
                _BigIconBtn(icon: Icons.delete_sweep, color: Colors.redAccent, onTap: () => _confirmDeleteAll(context, c)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _newPlaylist(BuildContext context, NexusController c) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: NexusColors.surface,
        title: const Text('Neue Playlist'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: NexusColors.text),
          decoration: const InputDecoration(hintText: 'Name (z. B. Quran)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: NexusColors.green, foregroundColor: Colors.black),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) c.createPlaylist(ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Anlegen'),
          ),
        ],
      ),
    );
  }

  void _showVolume(BuildContext context, NexusController c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NexusColors.surface,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lautstärke', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Slider(
              value: c.volume,
              onChanged: (v) => c.setVolume(v),
            ),
            Text('${(c.volume * 100).round()} %', style: const TextStyle(color: NexusColors.muted)),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, NexusController c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: NexusColors.surface,
        title: const Text('Alle löschen?'),
        content: const Text('Alle Videos der aktiven Playlist werden entfernt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () { c.deleteAllInActive(); Navigator.pop(context); },
            child: const Text('LÖSCHEN'),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context, NexusController c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NexusColors.surface,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Einstellungen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.loop),
              title: const Text('Endlosschleife'),
              trailing: Switch(value: c.loopEnabled, onChanged: (_) => c.toggleLoop(), activeThumbColor: NexusColors.green),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('Playlist löschen'),
              onTap: () {
                Navigator.pop(context);
                if (c.playlists.length <= 1) return;
                c.deletePlaylist(c.activeIndex);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final VideoItem video;
  final int index;
  const _VideoCard({required this.video, required this.index});

  @override
  Widget build(BuildContext context) {
    final c = context.read<NexusController>();
    return GestureDetector(
      onLongPress: () => _showMoveSheet(context, c, video),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(startIndex: index))),
      child: Container(
        decoration: BoxDecoration(
          color: NexusColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: NexusColors.surface2,
                child: const Center(child: Icon(Icons.play_circle_fill, size: 48, color: NexusColors.green)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${video.durationLabel} · ${video.sizeLabel}',
                      style: const TextStyle(color: NexusColors.muted, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoListTile extends StatelessWidget {
  final VideoItem video;
  final int index;
  const _VideoListTile({required this.video, required this.index});

  @override
  Widget build(BuildContext context) {
    final c = context.read<NexusController>();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: NexusColors.surface2, borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.play_arrow, color: NexusColors.green),
        ),
        title: Text(video.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${video.durationLabel} · ${video.sizeLabel}', style: const TextStyle(color: NexusColors.muted, fontSize: 11)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => c.deleteVideo(video),
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(startIndex: index))),
        onLongPress: () => _showMoveSheet(context, c, video),
      ),
    );
  }
}

class _BigIconBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _BigIconBtn({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: NexusColors.surface2,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: color ?? NexusColors.text, size: 24),
          ),
        ),
      ),
    );
  }
}

void _showMoveSheet(BuildContext context, NexusController c, VideoItem v) {
  showModalBottomSheet(
    context: context,
    backgroundColor: NexusColors.surface,
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('In Playlist verschieben', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        ...c.playlists.asMap().entries.map((e) => ListTile(
              leading: const Icon(Icons.playlist_play),
              title: Text(e.value.name),
              onTap: () {
                Navigator.pop(context);
                if (e.key != c.activeIndex) c.moveVideo(v, e.key);
              },
            )),
      ],
    ),
  );
}