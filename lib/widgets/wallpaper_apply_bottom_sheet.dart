import 'package:flutter/material.dart';

import '../services/wallpaper_service.dart';

class WallpaperApplyBottomSheet extends StatelessWidget {
  const WallpaperApplyBottomSheet({
    super.key,
    required this.isApplying,
    required this.onSelect,
  });

  final bool isApplying;
  final Future<void> Function(WallpaperTarget target) onSelect;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFDFDFE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4D8DF),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Apply Wallpaper',
                  style: TextStyle(
                    fontFamily: 'Chillax',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF101114),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose where you want to set this wallpaper.',
                  style: TextStyle(
                    fontFamily: 'Chillax',
                    fontSize: 14,
                    color: Color(0xFF616775),
                  ),
                ),
                const SizedBox(height: 14),
                _ApplyTile(
                  icon: Icons.home_rounded,
                  label: 'Home Screen',
                  enabled: !isApplying,
                  onTap: () => onSelect(WallpaperTarget.home),
                ),
                const SizedBox(height: 10),
                _ApplyTile(
                  icon: Icons.lock_rounded,
                  label: 'Lock Screen',
                  enabled: !isApplying,
                  onTap: () => onSelect(WallpaperTarget.lock),
                ),
                const SizedBox(height: 10),
                _ApplyTile(
                  icon: Icons.smartphone_rounded,
                  label: 'Both Screens',
                  enabled: !isApplying,
                  onTap: () => onSelect(WallpaperTarget.both),
                ),
                if (isApplying) ...<Widget>[
                  const SizedBox(height: 14),
                  const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplyTile extends StatelessWidget {
  const _ApplyTile({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F4F8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF222A36)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'RobotoSlab',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF11151C),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF7E8698)),
            ],
          ),
        ),
      ),
    );
  }
}
