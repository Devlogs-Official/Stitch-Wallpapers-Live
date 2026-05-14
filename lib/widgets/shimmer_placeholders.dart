import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Light pastel palette used for shimmer skeletons. Each entry is a
/// (base, highlight) pair so cards in a grid look slightly varied while still
/// reading as a unified loading state.
const List<List<Color>> _shimmerPalette = <List<Color>>[
  <Color>[Color(0xFFFCE4EC), Color(0xFFFFF1F5)], // pink
  <Color>[Color(0xFFE3F2FD), Color(0xFFF3F9FF)], // blue
  <Color>[Color(0xFFE8F5E9), Color(0xFFF4FBF4)], // mint
  <Color>[Color(0xFFFFF3E0), Color(0xFFFFFAEF)], // peach
  <Color>[Color(0xFFEDE7F6), Color(0xFFF6F2FB)], // lavender
  <Color>[Color(0xFFE0F7FA), Color(0xFFF1FBFC)], // aqua
];

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 16,
    this.baseColor,
    this.highlightColor,
  });

  final double height;
  final double? width;
  final double radius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final Color base = baseColor ?? const Color(0xFFE5E7EB);
    final Color highlight = highlightColor ?? const Color(0xFFF1F3F5);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ShimmerWallpaperGrid extends StatelessWidget {
  const ShimmerWallpaperGrid({super.key, this.itemCount = 6, this.padding});

  final int itemCount;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: padding ?? const EdgeInsets.fromLTRB(16, 0, 16, 28),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (BuildContext context, int index) {
        final List<Color> pair = _shimmerPalette[index % _shimmerPalette.length];
        return ShimmerBox(
          height: double.infinity,
          radius: 24,
          baseColor: pair[0],
          highlightColor: pair[1],
        );
      },
    );
  }
}

