import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  bool get isUpdateAvailable => _compareVersions(latestVersion, currentVersion) > 0;

  /// Returns positive if a > b, negative if a < b, 0 if equal.
  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av != bv) return av - bv;
    }
    return 0;
  }
}

class AppUpdateService {
  AppUpdateService._();
  static final instance = AppUpdateService._();

  static const _repo = 'rajsth/babaal-patro';
  static const _cacheKey = 'last_update_check_ms';
  static const _cacheDuration = Duration(hours: 6);

  final _dio = Dio();

  /// Check GitHub releases for a newer version.
  /// Returns null if no update is available or on error.
  /// Set [force] to bypass the 6-hour cache (for manual checks).
  Future<AppUpdateInfo?> checkForUpdate({bool force = false}) async {
    try {
      if (!force && await _isCacheValid()) return null;

      final response = await _dio.get(
        'https://api.github.com/repos/$_repo/releases/latest',
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      await _updateCacheTimestamp();

      final data = response.data as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final body = data['body'] as String? ?? '';
      final assets = data['assets'] as List<dynamic>? ?? [];

      // Find the APK asset
      String? downloadUrl;
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String?;
          break;
        }
      }
      if (downloadUrl == null) return null;

      // Strip leading 'v' from tag
      final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;

      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final updateInfo = AppUpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseNotes: body,
        downloadUrl: downloadUrl,
      );

      return updateInfo.isUpdateAvailable ? updateInfo : null;
    } catch (e) {
      debugPrint('AppUpdateService: checkForUpdate failed: $e');
      return null;
    }
  }

  /// Downloads the APK and triggers the Android package installer.
  /// [onProgress] receives (received bytes, total bytes).
  Future<void> downloadAndInstall({
    required String url,
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/babaal-patro-update.apk';

    // Clean up any previous download
    final file = File(filePath);
    if (await file.exists()) await file.delete();

    await _dio.download(
      url,
      filePath,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
      options: Options(receiveTimeout: const Duration(minutes: 10)),
    );

    await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
  }

  Future<bool> _isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_cacheKey) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastCheck;
    return elapsed < _cacheDuration.inMilliseconds;
  }

  Future<void> _updateCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheKey, DateTime.now().millisecondsSinceEpoch);
  }
}
