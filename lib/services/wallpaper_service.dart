import 'dart:io';

import '../core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';

enum WallpaperTarget {
  home,
  lock,
  both,
}

class WallpaperApplyResult {
  const WallpaperApplyResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

class WallpaperService {
  WallpaperService({
    Dio? dio,
    MethodChannel? channel,
  })  : _dio = dio ?? Dio(),
        _channel = channel ??
            const MethodChannel(AppConstants.androidLiveWallpaperMethodChannel);

  final Dio _dio;
  final MethodChannel _channel;

  Future<bool> ensureApplyPermission({
    bool requestIfNeeded = true,
  }) async {
    if (requestIfNeeded) {
      return _requestPermission();
    }
    return _hasPermissionOnly();
  }

  Future<WallpaperApplyResult> applyWallpaper({
    required String imageUrl,
    required WallpaperTarget target,
  }) async {
    File? tempFile;
    try {
      final bool permissionGranted = await _requestPermission();
      if (!permissionGranted) {
        return const WallpaperApplyResult(
          success: false,
          message: 'Photos permission is required to save the wallpaper.',
        );
      }

      tempFile = await _prepareImageFile(imageUrl);

      if (Platform.isAndroid) {
        final WallpaperManagerPlus manager = WallpaperManagerPlus();
        await manager.setWallpaper(tempFile, _androidLocation(target));
        return const WallpaperApplyResult(
          success: true,
          message: 'Wallpaper applied successfully.',
        );
      }

      if (Platform.isIOS) {
        await Gal.putImage(tempFile.path);
        return const WallpaperApplyResult(
          success: true,
          message: 'Wallpaper saved. Please set it manually from Photos.',
        );
      }

      return const WallpaperApplyResult(
        success: false,
        message: 'Wallpaper applying is not supported on this platform.',
      );
    } catch (e) {
      debugPrint('Wallpaper apply error: $e');
      return const WallpaperApplyResult(
        success: false,
        message: 'Failed to apply wallpaper. Please try again.',
      );
    } finally {
      await _deleteTempFile(tempFile);
    }
  }

  Future<WallpaperApplyResult> applyLiveWallpaper({
    required String videoUrl,
    required String id,
  }) async {
    if (videoUrl.isEmpty) {
      return const WallpaperApplyResult(
        success: false,
        message: 'Live wallpaper URL is missing.',
      );
    }

    if (!Platform.isAndroid) {
      return const WallpaperApplyResult(
        success: false,
        message: 'Live wallpapers are only supported on Android.',
      );
    }

    try {
      await _channel.invokeMethod<void>('applyLive', <String, String>{
        'url': videoUrl,
        'id': id,
      });
      return const WallpaperApplyResult(
        success: true,
        message: 'Pick "Stitch Wallpapers" to set it.',
      );
    } on PlatformException catch (e) {
      debugPrint('Live wallpaper apply error: ${e.code} ${e.message}');
      switch (e.code) {
        case 'PERMISSION_DENIED':
          return const WallpaperApplyResult(
            success: false,
            message: 'Permission denied while applying live wallpaper.',
          );
        case 'DOWNLOAD_FAILED':
          return const WallpaperApplyResult(
            success: false,
            message: 'Failed to download live wallpaper. Check your connection.',
          );
        case 'UNSUPPORTED':
          return const WallpaperApplyResult(
            success: false,
            message: 'Live wallpapers are not supported on this device.',
          );
        default:
          return const WallpaperApplyResult(
            success: false,
            message: 'Failed to apply live wallpaper. Please try again.',
          );
      }
    } on MissingPluginException {
      return const WallpaperApplyResult(
        success: false,
        message: 'Live wallpaper service is unavailable.',
      );
    } catch (e) {
      debugPrint('Live wallpaper apply error: $e');
      return const WallpaperApplyResult(
        success: false,
        message: 'Failed to apply live wallpaper. Please try again.',
      );
    }
  }

  Future<File> _prepareImageFile(String imageUrl) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = '${tempDir.path}/wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _dio.download(imageUrl, filePath);
    return File(filePath);
  }

  Future<bool> _requestPermission() async {
    // Android applies wallpapers via WallpaperManager + app-private files,
    // so no runtime permissions are needed.
    if (Platform.isAndroid) {
      return true;
    }

    // iOS saves the image to the user's Photos library, which requires the
    // photos add-only permission.
    if (Platform.isIOS) {
      final PermissionStatus photosStatus = await Permission.photosAddOnly.request();
      return photosStatus.isGranted || photosStatus.isLimited;
    }

    return false;
  }

  Future<bool> _hasPermissionOnly() async {
    if (Platform.isAndroid) {
      return true;
    }

    if (Platform.isIOS) {
      final PermissionStatus photosStatus = await Permission.photosAddOnly.status;
      return photosStatus.isGranted || photosStatus.isLimited;
    }

    return false;
  }

  int _androidLocation(WallpaperTarget target) {
    switch (target) {
      case WallpaperTarget.home:
        return WallpaperManagerPlus.homeScreen;
      case WallpaperTarget.lock:
        return WallpaperManagerPlus.lockScreen;
      case WallpaperTarget.both:
        return WallpaperManagerPlus.bothScreens;
    }
  }

  Future<void> _deleteTempFile(File? file) async {
    if (file == null) {
      return;
    }
    try {
      final Directory tempDir = await getTemporaryDirectory();
      if (file.path.startsWith(tempDir.path) && await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort cleanup.
    }
  }
}
