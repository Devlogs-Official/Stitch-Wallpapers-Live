import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/external/external_links.dart';
import '../models/wallpaper_model.dart';
import '../providers/wallpaper_apply_provider.dart';
import '../services/wallpaper_service.dart';
import '../widgets/shimmer_placeholders.dart';
import '../widgets/wallpaper_apply_bottom_sheet.dart';

class StaticWallpaperDetailScreen extends StatefulWidget {
  const StaticWallpaperDetailScreen({super.key, required this.wallpaper});

  final WallpaperModel wallpaper;

  @override
  State<StaticWallpaperDetailScreen> createState() =>
      _StaticWallpaperDetailScreenState();
}

class _StaticWallpaperDetailScreenState
    extends State<StaticWallpaperDetailScreen> {
  bool _isSharing = false;

  Future<void> _showApplyBottomSheet() async {
    final WallpaperApplyProvider applyProvider =
        context.read<WallpaperApplyProvider>();
    final bool hasPermission =
        await applyProvider.ensurePermission(requestIfNeeded: true);
    if (!mounted) return;

    if (!hasPermission) {
      _showSnack('Permission is required to apply wallpaper.', false);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Consumer<WallpaperApplyProvider>(
          builder: (context, provider, _) => WallpaperApplyBottomSheet(
            isApplying: provider.isApplying,
            onSelect: (WallpaperTarget target) =>
                _applyWallpaper(sheetContext, target),
          ),
        );
      },
    );
  }

  Future<void> _applyWallpaper(
    BuildContext sheetContext,
    WallpaperTarget target,
  ) async {
    final WallpaperApplyProvider applyProvider =
        context.read<WallpaperApplyProvider>();
    if (applyProvider.isApplying) return;

    final NavigatorState sheetNavigator = Navigator.of(sheetContext);
    final WallpaperApplyResult result = await applyProvider.apply(
      imageUrl: widget.wallpaper.imageUrl,
      target: target,
    );

    if (!mounted) return;
    sheetNavigator.pop();
    _showSnack(result.message, result.success);
  }

  Future<void> _shareWallpaper() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await ExternalLinks.shareWallpaper(
        url: widget.wallpaper.imageUrl,
        title: 'Stitch Wallpaper',
        isVideo: false,
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Sharing is unavailable on this device.', false);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _showSnack(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            success ? const Color(0xFF1A7F44) : const Color(0xFFB23838),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Hero(
              tag: 'wallpaper-${widget.wallpaper.id}',
              child: CachedNetworkImage(
                imageUrl: widget.wallpaper.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const ShimmerBox(height: double.infinity, radius: 0),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 42,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: 8,
                  left: 12,
                  child: _CircleButton(
                    icon: Icons.cancel_outlined,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      color: Colors.black45,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 3,
                            child: _DetailActionButton(
                              onPressed: _showApplyBottomSheet,
                              icon: const Icon(Icons.wallpaper_outlined),
                              label: 'Apply',
                              isPrimary: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _DetailActionButton(
                              onPressed: _isSharing ? null : _shareWallpaper,
                              icon: _isSharing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.share_outlined),
                              label: _isSharing ? 'Sharing' : 'Share',
                              isPrimary: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  const _DetailActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final Color start = isPrimary ? Colors.cyan : const Color(0x33FFFFFF);
    final Color end = isPrimary ? const Color(0xFF8BC7FF) : const Color(0x1FFFFFFF);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: <Color>[start, end]),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (isPrimary ? const Color(0xFF2F80ED) : Colors.black)
                .withValues(alpha: isPrimary ? 0.34 : 0.18),
            blurRadius: isPrimary ? 22 : 16,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Opacity(
            opacity: onPressed == null ? 0.62 : 1,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isPrimary ? 18 : 14,
                vertical: isPrimary ? 15 : 13,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconTheme.merge(
                    data: const IconThemeData(color: Colors.white, size: 20),
                    child: icon,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'RobotoSlab',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.cyan, size: 30,),
        onPressed: onPressed,
      ),
    );
  }
}
