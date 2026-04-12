import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_update_service.dart';

enum UpdateStatus { idle, checking, updateAvailable, downloading, installed, error }

class AppUpdateState {
  final UpdateStatus status;
  final AppUpdateInfo? updateInfo;
  final double downloadProgress;
  final String? errorMessage;

  const AppUpdateState({
    this.status = UpdateStatus.idle,
    this.updateInfo,
    this.downloadProgress = 0.0,
    this.errorMessage,
  });

  AppUpdateState copyWith({
    UpdateStatus? status,
    AppUpdateInfo? updateInfo,
    double? downloadProgress,
    String? errorMessage,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      updateInfo: updateInfo ?? this.updateInfo,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage,
    );
  }
}

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier() : super(const AppUpdateState());

  CancelToken? _cancelToken;

  Future<void> checkForUpdate({bool force = false}) async {
    state = state.copyWith(status: UpdateStatus.checking);
    try {
      final info = await AppUpdateService.instance.checkForUpdate(force: force);
      if (info != null) {
        state = state.copyWith(status: UpdateStatus.updateAvailable, updateInfo: info);
      } else {
        state = state.copyWith(status: UpdateStatus.idle);
      }
    } catch (e) {
      debugPrint('AppUpdateNotifier: checkForUpdate failed: $e');
      state = state.copyWith(status: UpdateStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> downloadAndInstall() async {
    final url = state.updateInfo?.downloadUrl;
    if (url == null) return;

    _cancelToken = CancelToken();
    state = state.copyWith(status: UpdateStatus.downloading, downloadProgress: 0.0);

    try {
      await AppUpdateService.instance.downloadAndInstall(
        url: url,
        onProgress: (received, total) {
          if (total > 0) {
            state = state.copyWith(downloadProgress: received / total);
          }
        },
        cancelToken: _cancelToken,
      );
      state = state.copyWith(status: UpdateStatus.installed);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        state = state.copyWith(status: UpdateStatus.updateAvailable, downloadProgress: 0.0);
      } else {
        state = state.copyWith(status: UpdateStatus.error, errorMessage: e.message);
      }
    } catch (e) {
      state = state.copyWith(status: UpdateStatus.error, errorMessage: e.toString());
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel();
  }

  void dismiss() {
    _cancelToken?.cancel();
    state = const AppUpdateState();
  }
}

final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  return AppUpdateNotifier();
});
