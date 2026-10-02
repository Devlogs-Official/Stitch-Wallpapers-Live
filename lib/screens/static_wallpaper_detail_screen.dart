import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/external/external_links.dart';
import '../models/wallpaper_model.dart';
import '../providers/wallpaper_apply_provider.dart';
import '../services/wallpaper_service.dart';
import '../widgets/shimmer_placeholders.dart';
import '../widgets/wallpaper_apply_bottom_sheet.dart';
import '../widgets/wallpaper_detail_actions.dart';

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
    final WallpaperApplyProvider applyProvider = context
        .read<WallpaperApplyProvider>();
    final bool hasPermission = await applyProvider.ensurePermission(
      requestIfNeeded: true,
    );
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
    final WallpaperApplyProvider applyProvider = context
        .read<WallpaperApplyProvider>();
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
        backgroundColor: success
            ? const Color(0xFF1A7F44)
            : const Color(0xFFB23838),
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
                  child: WallpaperDetailCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: WallpaperDetailActionDock(
                    onApply: _showApplyBottomSheet,
                    applyIcon: const Icon(Icons.wallpaper_rounded),
                    applyLabel: 'Apply',
                    onShare: _isSharing ? null : _shareWallpaper,
                    shareIcon: _isSharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.ios_share_rounded),
                    shareLabel: _isSharing ? 'Sharing' : 'Share',
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
