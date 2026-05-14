import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wallpaper_model.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _favoritesKey = 'favorite_wallpapers';

  final List<WallpaperModel> _favorites = <WallpaperModel>[];

  List<WallpaperModel> get favorites => List<WallpaperModel>.unmodifiable(_favorites);

  Future<void> loadFavorites() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> rawList = prefs.getStringList(_favoritesKey) ?? <String>[];

    final Map<int, WallpaperModel> deduped = <int, WallpaperModel>{};

    for (final String item in rawList) {
      try {
        final Map<String, dynamic> json = jsonDecode(item) as Map<String, dynamic>;
        final WallpaperModel model = WallpaperModel.fromJson(json);
        deduped[model.id] = model;
      } catch (_) {
        // Skip invalid persisted entries.
      }
    }

    _favorites
      ..clear()
      ..addAll(deduped.values);

    notifyListeners();
  }

  bool isFavorite(WallpaperModel wallpaper) {
    return _favorites.any((WallpaperModel item) => item.id == wallpaper.id);
  }

  Future<void> toggleFavorite(WallpaperModel wallpaper) async {
    if (isFavorite(wallpaper)) {
      _favorites.removeWhere((WallpaperModel item) => item.id == wallpaper.id);
    } else {
      _favorites.add(wallpaper);
    }

    notifyListeners();
    await _persist();
  }

  Future<void> clearFavorites() async {
    _favorites.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> data = _favorites
        .map((WallpaperModel item) => jsonEncode(item.toJson()))
        .toList(growable: false);
    await prefs.setStringList(_favoritesKey, data);
  }
}
