import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_info.dart';

const githubOwner = 'Baschar2010';
const githubRepo = 'NEXUS_LOOP';
const githubLatestReleaseApi =
    'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';
const githubReleasesPage =
    'https://github.com/$githubOwner/$githubRepo/releases';

class ReleaseInfo {
  const ReleaseInfo({
    required this.version,
    required this.tag,
    required this.apkUrl,
    required this.pageUrl,
    this.notes = '',
  });
  final String version;
  final String tag;
  final String apkUrl;
  final String pageUrl;
  final String notes;

  static ReleaseInfo? fromGitHub(Object? json) {
    if (json is! Map) return null;
    final tag = (json['tag_name'] as String?)?.trim();
    if (tag == null || tag.isEmpty) return null;
    final version = normalizeVersion(tag);
    if (version == null) return null;

    String? apk;
    final assets = json['assets'];
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map) continue;
        final name = (asset['name'] as String?)?.toLowerCase() ?? '';
        final url = asset['browser_download_url'];
        if (name.endsWith('.apk') && url is String && url.isNotEmpty) {
          apk = url;
          break;
        }
      }
    }

    final page = switch (json['html_url']) {
      final String url when url.isNotEmpty => url,
      _ => githubReleasesPage,
    };

    return ReleaseInfo(
      version: version,
      tag: tag,
      apkUrl: apk ?? page,
      pageUrl: page,
      notes: switch (json['body']) {
        final String body => body.trim(),
        _ => '',
      },
    );
  }
}

String? normalizeVersion(String tag) {
  final cleaned = tag
      .trim()
      .replaceFirst(RegExp(r'^[vV]'), '')
      .split('+')
      .first
      .split('-')
      .first;
  if (cleaned.isEmpty || !RegExp(r'^\d+(\.\d+)*$').hasMatch(cleaned)) {
    return null;
  }
  return cleaned;
}

int compareVersions(String a, String b) {
  List<int> parts(String value) => value
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList(growable: false);
  final left = parts(normalizeVersion(a) ?? a);
  final right = parts(normalizeVersion(b) ?? b);
  final length = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < length; i++) {
    final x = i < left.length ? left[i] : 0;
    final y = i < right.length ? right[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

typedef ReleaseFetcher = Future<ReleaseInfo?> Function();

class UpdateService {
  UpdateService({
    ReleaseFetcher? fetchLatest,
    String currentVersion = appVersion,
  })  : _fetchLatest = fetchLatest ?? fetchLatestRelease,
        currentVersion = normalizeVersion(currentVersion) ?? currentVersion;

  final ReleaseFetcher _fetchLatest;
  final String currentVersion;

  Future<ReleaseInfo?> check() async {
    try {
      final release = await _fetchLatest().timeout(const Duration(seconds: 8));
      if (release == null) return null;
      if (compareVersions(release.version, currentVersion) <= 0) return null;
      return release;
    } catch (_) {
      return null;
    }
  }

  static Future<String> installedVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return appVersion;
    }
  }

  static Future<bool> downloadAndInstallUpdate(
    ReleaseInfo release, {
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.tryParse(release.apkUrl);
    if (uri == null) return false;
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', uri));
      if (response.statusCode != 200) return false;
      final file = File('${Directory.systemTemp.path}/NEXUS_LOOP_update.apk');
      if (await file.exists()) {
        await file.delete();
      }
      final sink = file.openWrite();
      final total = response.contentLength ?? 0;
      var received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress?.call(received / total);
        }
      }
      await sink.flush();
      await sink.close();
      final result = await OpenFilex.open(file.path);
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  static Future<ReleaseInfo?> fetchLatestRelease() async {
    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.parse(githubLatestReleaseApi),
            headers: const {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'NEXUS-LOOP/$appVersion',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      return ReleaseInfo.fromGitHub(jsonDecode(body));
    } finally {
      client.close();
    }
  }
}