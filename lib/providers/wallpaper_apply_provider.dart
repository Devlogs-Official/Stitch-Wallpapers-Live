import 'package:flutter/foundation.dart';

import '../services/wallpaper_service.dart';

class WallpaperApplyProvider extends ChangeNotifier {
  WallpaperApplyProvider(this._wallpaperService);

  final WallpaperService _wallpaperService;

  bool _isApplying = false;
  bool get isApplying => _isApplying;

  Future<bool> ensurePermission({
    bool requestIfNeeded = true,
  }) {
    return _wallpaperService.ensureApplyPermission(
      requestIfNeeded: requestIfNeeded,
    );
  }

  Future<WallpaperApplyResult> apply({
    required String imageUrl,
    required WallpaperTarget target,
  }) async {
    if (_isApplying) {
      return const WallpaperApplyResult(
        success: false,
        message: 'Wallpaper is already being applied.',
      );
    }

    _isApplying = true;
    notifyListeners();

    try {
      return await _wallpaperService.applyWallpaper(
        imageUrl: imageUrl,
        target: target,
      );
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }

  Future<WallpaperApplyResult> applyLive({
    required String videoUrl,
    required String id,
  }) async {
    if (_isApplying) {
      return const WallpaperApplyResult(
        success: false,
        message: 'Wallpaper is already being applied.',
      );
    }

    _isApplying = true;
    notifyListeners();

    try {
      return await _wallpaperService.applyLiveWallpaper(
        videoUrl: videoUrl,
        id: id,
      );
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }
}
