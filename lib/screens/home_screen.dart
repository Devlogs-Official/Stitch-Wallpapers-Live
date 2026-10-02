import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/navigation/app_page_transitions.dart';
import '../core/external/external_links.dart';
import '../models/wallpaper_model.dart';
import '../providers/favorites_provider.dart';
import '../providers/wallpaper_provider.dart';
import '../theme/app_colors.dart';
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
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await Future.wait(<Future<void>>[
              wallpaperProvider.refreshStatic(),
              wallpaperProvider.refreshLive(),
            ]);
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _GalleryHeader(onOpenLiveTab: widget.onOpenLiveTab),
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
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 128),
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
                              onRetry: () => wallpaperProvider.retryStatic(),
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
                                StaticWallpaperDetailScreen(wallpaper: item),
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
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.69,
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

class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({this.onOpenLiveTab});

  final VoidCallback? onOpenLiveTab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Builder(
            builder: (BuildContext context) => Row(
              children: <Widget>[
                InkWell(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Stitch Wallpapers',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: onOpenLiveTab,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 138,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage('assets/images/live_wallpapers_hero.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: <Color>[Color(0x88091741), Color(0x00091741)],
                          stops: <double>[0, 0.7],
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 18,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        'Explore the best\nlive wallpapers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.22,
                          fontWeight: FontWeight.w900,
                          shadows: <Shadow>[
                            Shadow(color: Color(0x99000000), blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'HD Wallpapers',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: Colors.transparent,

      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, Color(0xFF7C64ED), Color(0xFF4E3CB5)],
          ),
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),

            child: Column(
              children: [
                /// HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),

                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),

                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 25,
                        spreadRadius: 1,
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      /// IMAGE
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),

                        child: Image.asset(
                          "assets/icons/drawer.jpg",
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// TITLE
                      const Text(
                        "Stitch Wallpapers",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Cute • Live • HD Wallpapers",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                /// MENU ITEMS
                _drawerTile(
                  icon: Icons.home_rounded,
                  title: "Home",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 14),

                _drawerTile(
                  icon: Icons.share_rounded,
                  title: "Share App",
                  onTap: () async {
                    Navigator.pop(context);

                    try {
                      await ExternalLinks.shareApp();
                    } catch (_) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Sharing unavailable")),
                      );
                    }
                  },
                ),

                const SizedBox(height: 14),

                _drawerTile(
                  icon: Icons.privacy_tip_outlined,
                  title: "Privacy Policy",
                  onTap: () async {
                    Navigator.pop(context);
                    final bool opened = await ExternalLinks.openExternalBrowser(
                      AppConstants.privacyPolicyUrl,
                    );
                    if (!opened && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open Privacy Policy'),
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 14),

                _drawerTile(
                  icon: Icons.description_outlined,
                  title: "Terms & Conditions",
                  onTap: () async {
                    Navigator.pop(context);
                    final bool opened = await ExternalLinks.openInAppBrowser(
                      AppConstants.termsAndConditionsUrl,
                    );
                    if (!opened && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open Terms & Conditions'),
                        ),
                      );
                    }
                  },
                ),

                const Spacer(),

                /// VERSION
                Text(
                  "Version 1.0.0",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,

        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),

            color: Colors.white.withValues(alpha: 0.05),

            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),

          child: Row(
            children: [
              /// ICON BOX
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),

                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.8),
                      AppColors.accent.withValues(alpha: 0.55),
                    ],
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),

                child: Icon(icon, color: Colors.white, size: 22),
              ),

              const SizedBox(width: 16),

              /// TITLE
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 16,
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
