import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/navigation/app_page_transitions.dart';
import '../core/external/external_links.dart';
import '../models/wallpaper_model.dart';
import '../providers/favorites_provider.dart';
import '../providers/wallpaper_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/live_wallpaper_card.dart';
import '../widgets/shimmer_placeholders.dart';
import '../widgets/wallpaper_grid_card.dart';
import 'static_wallpaper_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenLiveTab});

  final VoidCallback? onOpenLiveTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<WallpaperProvider>().fetchLiveInitial();
      if (!mounted) return;
      await context.read<WallpaperProvider>().fetchStaticInitial();
    });
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 600) {
      context.read<WallpaperProvider>().loadMoreStatic();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WallpaperProvider wallpaperProvider = context
        .watch<WallpaperProvider>();
    final FavoritesProvider favoritesProvider = context
        .watch<FavoritesProvider>();

    return Scaffold(
      drawer: const _HomeDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        centerTitle: true,
        title: Text(
          "Stitch Wallpapers",
        ),
        leading: InkWell(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Image.asset(
            "assets/icons/menu-button.png",
            height: 24,
            width: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            //   child: Row(
            //     children: <Widget>[
            //       Builder(
            //         builder: (context) => IconButton(
            //           onPressed: () => Scaffold.of(context).openDrawer(),
            //           icon: const Icon(Icons.menu_rounded),
            //         ),
            //       ),
            //       const SizedBox(width: 4),
            //       Expanded(
            //         child: Text(
            //           'Eid Wallpapers',
            //           style: TextStyle(
            //             fontSize: 30,
            //             fontWeight: FontWeight.w800,
            //             color: Theme.of(context).colorScheme.onSurface,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait(<Future<void>>[
                    wallpaperProvider.refreshStatic(),
                    wallpaperProvider.refreshLive(),
                  ]);
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: LiveWallpaperCard(
                        onTap: () {
                          widget.onOpenLiveTab?.call();
                        },
                      ),
                    ),
                    if (wallpaperProvider.isLoadingStatic &&
                        wallpaperProvider.staticWallpapers.isEmpty)
                      const SliverToBoxAdapter(
                        child: ShimmerWallpaperGrid(
                          itemCount: 6,
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 120),
                        ),
                      )
                    else if (wallpaperProvider.staticError != null &&
                        wallpaperProvider.staticWallpapers.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ErrorState(
                          message: wallpaperProvider.staticError!,
                          onRetry: () => wallpaperProvider.retryStatic(),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              final int wallpaperCount =
                                  wallpaperProvider.staticWallpapers.length;
                              if (index >= wallpaperCount) {
                                if (wallpaperProvider.isLoadingMoreStatic) {
                                  return const _BottomLoaderTile();
                                }
                                if (wallpaperProvider.staticError != null &&
                                    wallpaperProvider.hasMoreStatic) {
                                  return _LoadMoreRetryTile(
                                    onRetry: () =>
                                        wallpaperProvider.retryStatic(),
                                  );
                                }
                                return const SizedBox.shrink();
                              }

                              final WallpaperModel item =
                                  wallpaperProvider.staticWallpapers[index];
                              return WallpaperGridCard(
                                wallpaper: item,
                                isFavorite: favoritesProvider.isFavorite(item),
                                onFavoriteToggle: () =>
                                    favoritesProvider.toggleFavorite(item),
                                onTap: () {
                                  Navigator.of(context).push(
                                    AppPageTransitions.fadeSlide(
                                      StaticWallpaperDetailScreen(
                                        wallpaper: item,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount:
                                wallpaperProvider.staticWallpapers.length +
                                (wallpaperProvider.hasMoreStatic ? 1 : 0),
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color topColor = isDark ? const Color(0xFF0E1117) : AppColors.primary;
    final Color bottomColor = isDark
        ? const Color(0xFF182230)
        : const Color(0xFF111827);
    final Color borderColor = Colors.white.withValues(alpha: 0.12);
    final Color tileColor = Colors.white.withValues(alpha: 0.08);
    final Color titleColor = Colors.white.withValues(alpha: 0.96);
    final Color subtitleColor = Colors.white.withValues(alpha: 0.68);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[topColor, bottomColor],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              children: <Widget>[
                _DrawerHeader(
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 22),
                Material(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      Navigator.of(context).pop();
                      try {
                        await ExternalLinks.shareApp();
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Sharing is unavailable on this device.',
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: const Icon(
                              Icons.share_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Share App',
                            style: TextStyle(
                              color: titleColor,
                              fontFamily: 'Chillax',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Version ${AppConstants.appVersion}',
                  style: TextStyle(
                    color: subtitleColor,
                    fontFamily: 'Chillax',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.titleColor,
    required this.subtitleColor,
    required this.borderColor,
  });

  final Color titleColor;
  final Color subtitleColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.primary.withValues(alpha: 0.95),
                  const Color(0xFF8BC7FF),
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.34),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Eid Wallpapers',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontFamily: 'Chillax',
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Celebrate Eid Beautifully',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtitleColor,
              fontFamily: 'Chillax',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomLoaderTile extends StatelessWidget {
  const _BottomLoaderTile();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2.6),
      ),
    );
  }
}

class _LoadMoreRetryTile extends StatelessWidget {
  const _LoadMoreRetryTile({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry'),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
