import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/navigation/app_page_transitions.dart';
import '../models/wallpaper_model.dart';
import '../providers/favorites_provider.dart';
import '../providers/wallpaper_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/shimmer_placeholders.dart';
import '../widgets/wallpaper_grid_card.dart';
import 'live_wallpaper_detail_screen.dart';

class LiveWallpaperScreen extends StatefulWidget {
  const LiveWallpaperScreen({super.key});

  @override
  State<LiveWallpaperScreen> createState() => _LiveWallpaperScreenState();
}

class _LiveWallpaperScreenState extends State<LiveWallpaperScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WallpaperProvider>().fetchLiveInitial();
    });
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 600) {
      context.read<WallpaperProvider>().loadMoreLive();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WallpaperProvider wallpaperProvider = context.watch<WallpaperProvider>();
    final FavoritesProvider favoritesProvider = context.watch<FavoritesProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: wallpaperProvider.refreshLive,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Chillax',
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'Live',
                          style: TextStyle(color: AppColors.primary),
                        ),
                        TextSpan(
                          text: ' Wallpapers',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (wallpaperProvider.isLoadingLive &&
                  wallpaperProvider.liveWallpapers.isEmpty)
                const SliverToBoxAdapter(
                  child: ShimmerWallpaperGrid(
                    itemCount: 6,
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 120),
                  ),
                )
              else if (wallpaperProvider.liveError != null &&
                  wallpaperProvider.liveWallpapers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    message: wallpaperProvider.liveError!,
                    onRetry: wallpaperProvider.retryLive,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final int wallpaperCount =
                            wallpaperProvider.liveWallpapers.length;
                        if (index >= wallpaperCount) {
                          if (wallpaperProvider.isLoadingMoreLive) {
                            return const _BottomLoaderTile();
                          }
                          if (wallpaperProvider.liveError != null &&
                              wallpaperProvider.hasMoreLive) {
                            return _LoadMoreRetryTile(
                              onRetry: wallpaperProvider.retryLive,
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final WallpaperModel item =
                            wallpaperProvider.liveWallpapers[index];
                        return WallpaperGridCard(
                          wallpaper: item,
                          isFavorite: favoritesProvider.isFavorite(item),
                          onFavoriteToggle: () =>
                              favoritesProvider.toggleFavorite(item),
                          onTap: () {
                            Navigator.of(context).push(
                              AppPageTransitions.fadeSlide(
                                LiveWallpaperDetailScreen(wallpaper: item),
                              ),
                            );
                          },
                        );
                      },
                      childCount: wallpaperProvider.liveWallpapers.length +
                          (wallpaperProvider.hasMoreLive ? 1 : 0),
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
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

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
            const Icon(Icons.cloud_off_rounded,
                size: 42, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
