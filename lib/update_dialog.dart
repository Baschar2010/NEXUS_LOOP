import 'package:flutter/material.dart';
import 'update_service.dart';

Future<void> showUpdateDialog(BuildContext context, ReleaseInfo release) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateDialog(release: release),
  );
}

class _UpdateDialog extends StatefulWidget {
  final ReleaseInfo release;
  const _UpdateDialog({required this.release});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double _progress = 0;
  bool _downloading = false;
  bool _failed = false;

  Future<void> _update() async {
    setState(() { _downloading = true; _failed = false; _progress = 0; });
    final ok = await UpdateService.downloadAndInstallUpdate(
      widget.release,
      onProgress: (p) { if (mounted) setState(() => _progress = p); },
    );
    if (!mounted) return;
    if (!ok) {
      setState(() { _downloading = false; _failed = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF181818),
      title: const Text('Update verfügbar', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Version ${widget.release.version} ist verfügbar.',
              style: const TextStyle(color: Colors.white70)),
          if (widget.release.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.release.notes, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
          if (_downloading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress > 0 ? _progress : null, color: const Color(0xFF1DB954)),
            const SizedBox(height: 4),
            Text('${(_progress * 100).round()} %', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
          if (_failed) ...[
            const SizedBox(height: 8),
            const Text('Download fehlgeschlagen.', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        if (!_downloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Später', style: TextStyle(color: Colors.white54)),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954), foregroundColor: Colors.black),
          onPressed: _downloading ? null : _update,
          child: Text(_downloading ? 'Lädt…' : 'Aktualisieren'),
        ),
      ],
    );
  }
}