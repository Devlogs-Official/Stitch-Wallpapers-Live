import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The controls that sit above a fullscreen wallpaper preview.
///
/// The dock deliberately uses a dark, low-opacity material so the artwork
/// remains the focus while the actions are always readable on light images.
class WallpaperDetailActionDock extends StatelessWidget {
  const WallpaperDetailActionDock({
    super.key,
    required this.onApply,
    required this.applyIcon,
    required this.applyLabel,
    required this.onShare,
    required this.shareIcon,
    required this.shareLabel,
  });

  final VoidCallback? onApply;
  final Widget applyIcon;
  final String applyLabel;
  final VoidCallback? onShare;
  final Widget shareIcon;
  final String shareLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF10131D).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: _WallpaperActionButton(
                    onPressed: onApply,
                    icon: applyIcon,
                    label: applyLabel,
                    primary: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _WallpaperActionButton(
                    onPressed: onShare,
                    icon: shareIcon,
                    label: shareLabel,
                    primary: false,
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

class WallpaperDetailCloseButton extends StatelessWidget {
  const WallpaperDetailCloseButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: const Color(0xFF121621).withValues(alpha: 0.64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.close_rounded, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

class _WallpaperActionButton extends StatelessWidget {
  const _WallpaperActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.primary,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(20);

    return Opacity(
      opacity: onPressed == null ? 0.56 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: primary
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[AppColors.primary, Color(0xFF846CFF)],
                )
              : LinearGradient(
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.09),
                  ],
                ),
          border: Border.all(
            color: primary
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.2),
          ),
          boxShadow: primary
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconTheme.merge(
                      data: const IconThemeData(color: Colors.white, size: 21),
                      child: icon,
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
