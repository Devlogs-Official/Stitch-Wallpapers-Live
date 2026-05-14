import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/navigation/app_page_transitions.dart';
import '../models/wallpaper_model.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/wallpaper_grid_card.dart';
import 'live_wallpaper_detail_screen.dart';
import 'static_wallpaper_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FavoritesProvider favoritesProvider = context.watch<FavoritesProvider>();
    final List<WallpaperModel> staticFavorites =
        favoritesProvider.favorites.where((WallpaperModel item) => !item.isLive).toList(growable: false);
    final List<WallpaperModel> liveFavorites =
        favoritesProvider.favorites.where((WallpaperModel item) => item.isLive).toList(growable: false);

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF1B1F27) : Colors.white;
    final Color borderColor =
        isDark ? const Color(0xFF272C36) : AppColors.border;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color tabIndicatorColor =
        isDark ? const Color(0xFF2A3550) : const Color(0xFFEEF3FF);
    final Color tabUnselected =
        isDark ? const Color(0xFF8A93A6) : AppColors.textSecondary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Favorite Wallpapers',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: isDark
                            ? const Color(0x33000000)
                            : const Color(0x14000000),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.favorite_rounded, color: Color(0xFFE15B77)),
                      const SizedBox(width: 8),
                      Text(
                        '${favoritesProvider.favorites.length} saved wallpapers',
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.zero,
                  indicator: BoxDecoration(
                    color: tabIndicatorColor,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  labelColor: titleColor,
                  unselectedLabelColor: tabUnselected,
                  dividerColor: Colors.transparent,
                  tabs: const <Tab>[
                    Tab(text: 'Static'),
                    Tab(text: 'Live'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _FavoritesGrid(
                      items: staticFavorites,
                      emptyTitle: 'No static favorites yet',
                      emptySubtitle: 'Save regular wallpapers to see them here.',
                    ),
                    _FavoritesGrid(
                      items: liveFavorites,
                      emptyTitle: 'No live favorites yet',
                      emptySubtitle: 'Save live wallpapers to see them here.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritesGrid extends StatelessWidget {
  const _FavoritesGrid({
    required this.items,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final List<WallpaperModel> items;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final FavoritesProvider favoritesProvider = context.read<FavoritesProvider>();

    if (items.isEmpty) {
      return _FavoritesEmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (_, int index) {
        final WallpaperModel item = items[index];
        return WallpaperGridCard(
          wallpaper: item,
          isFavorite: true,
          onFavoriteToggle: () => favoritesProvider.toggleFavorite(item),
          onTap: () {
            if (item.isLive) {
              Navigator.of(context).push(AppPageTransitions.fadeSlide(LiveWallpaperDetailScreen(wallpaper: item)));
              return;
            }
            Navigator.of(context).push(AppPageTransitions.fadeSlide(StaticWallpaperDetailScreen(wallpaper: item)));
          },
        );
      },
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color subtitleColor = isDark
        ? const Color(0xFFB1B8C7)
        : AppColors.textSecondary;
    final Color iconBg = isDark
        ? const Color(0xFF3A1F2A)
        : const Color(0xFFFFEEF2);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 42,
                color: Color(0xFFE15B77),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
