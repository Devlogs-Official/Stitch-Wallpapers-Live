import 'package:flutter/foundation.dart';
import '../models/wallpaper_model.dart';
import '../services/wallpaper_api_service.dart';

class WallpaperProvider extends ChangeNotifier {
  WallpaperProvider(this._apiService);

  static const int _pageSize = 20;

  final WallpaperApiService _apiService;

  final List<WallpaperModel> _staticWallpapers = <WallpaperModel>[];
  final List<WallpaperModel> _liveWallpapers = <WallpaperModel>[];
  final Set<int> _seenStaticIds = <int>{};
  final Set<int> _seenLiveIds = <int>{};

  bool _isLoadingStatic = false;
  bool _isLoadingLive = false;
  bool _isLoadingMoreStatic = false;
  bool _isLoadingMoreLive = false;
  bool _hasMoreStatic = true;
  bool _hasMoreLive = true;

  String? _staticError;
  String? _liveError;

  int _staticPage = 0;
  int _livePage = 0;
  int _staticTotalPages = 0;
  int _liveTotalPages = 0;

  List<WallpaperModel> get staticWallpapers =>
      List<WallpaperModel>.unmodifiable(_staticWallpapers);
  List<WallpaperModel> get liveWallpapers =>
      List<WallpaperModel>.unmodifiable(_liveWallpapers);

  bool get isLoadingStatic => _isLoadingStatic;
  bool get isLoadingLive => _isLoadingLive;
  bool get isLoadingMoreStatic => _isLoadingMoreStatic;
  bool get isLoadingMoreLive => _isLoadingMoreLive;
  bool get hasMoreStatic => _hasMoreStatic;
  bool get hasMoreLive => _hasMoreLive;
  String? get staticError => _staticError;
  String? get liveError => _liveError;
  int get staticTotalPages => _staticTotalPages;
  int get liveTotalPages => _liveTotalPages;

  Future<void> fetchStaticInitial() => _fetch(isLive: false, reset: true);
  Future<void> fetchLiveInitial() => _fetch(isLive: true, reset: true);
  Future<void> refreshStatic() => _fetch(isLive: false, reset: true);
  Future<void> refreshLive() => _fetch(isLive: true, reset: true);
  Future<void> loadMoreStatic() => _fetch(isLive: false, reset: false);
  Future<void> loadMoreLive() => _fetch(isLive: true, reset: false);

  Future<void> retryStatic() =>
      _staticWallpapers.isEmpty ? fetchStaticInitial() : loadMoreStatic();
  Future<void> retryLive() =>
      _liveWallpapers.isEmpty ? fetchLiveInitial() : loadMoreLive();

  Future<void> _fetch({
    required bool isLive,
    required bool reset,
  }) async {
    if (isLive) {
      if (reset) {
        if (_isLoadingLive) return;
        _isLoadingLive = true;
        _liveError = null;
        _livePage = 0;
        _liveTotalPages = 0;
        _hasMoreLive = true;
        _seenLiveIds.clear();
        _liveWallpapers.clear();
      } else {
        if (_isLoadingLive || _isLoadingMoreLive || !_hasMoreLive) return;
        _isLoadingMoreLive = true;
        _liveError = null;
      }
    } else {
      if (reset) {
        if (_isLoadingStatic) return;
        _isLoadingStatic = true;
        _staticError = null;
        _staticPage = 0;
        _staticTotalPages = 0;
        _hasMoreStatic = true;
        _seenStaticIds.clear();
        _staticWallpapers.clear();
      } else {
        if (_isLoadingStatic || _isLoadingMoreStatic || !_hasMoreStatic) {
          return;
        }
        _isLoadingMoreStatic = true;
        _staticError = null;
      }
    }

    notifyListeners();

    final int requestPage = reset ? 1 : (isLive ? _livePage : _staticPage) + 1;

    try {
      final response = await _apiService.getWallpapers(
        isLive: isLive,
        pageNumber: requestPage,
        pageSize: _pageSize,
      );

      final Set<int> seenIds = isLive ? _seenLiveIds : _seenStaticIds;
      final List<WallpaperModel> pageItems = response.items
          .where((WallpaperModel item) => item.isLive == isLive)
          .where((WallpaperModel item) => item.imageUrl.isNotEmpty)
          .where((WallpaperModel item) => seenIds.add(item.id))
          .toList(growable: false);

      if (isLive) {
        _liveWallpapers.addAll(pageItems);
        _livePage = response.currentPage;
        _liveTotalPages = response.totalPages;
        _hasMoreLive = response.hasMore;
      } else {
        _staticWallpapers.addAll(pageItems);
        _staticPage = response.currentPage;
        _staticTotalPages = response.totalPages;
        _hasMoreStatic = response.hasMore;
      }
    } catch (e) {
      debugPrint('Wallpaper fetch error: $e');
      if (isLive) {
        _liveError = 'Failed to load live wallpapers.';
      } else {
        _staticError = 'Failed to load wallpapers.';
      }
    } finally {
      if (isLive) {
        _isLoadingLive = false;
        _isLoadingMoreLive = false;
      } else {
        _isLoadingStatic = false;
        _isLoadingMoreStatic = false;
      }
      notifyListeners();
    }
  }
}
