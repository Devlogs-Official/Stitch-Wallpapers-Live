import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'shimmer_placeholders.dart';

class LiveWallpaperCard extends StatefulWidget {
  const LiveWallpaperCard({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  State<LiveWallpaperCard> createState() => _LiveWallpaperCardState();
}

class _LiveWallpaperCardState extends State<LiveWallpaperCard>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _isReady = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    _controller = VideoPlayerController.asset('assets/hero.mp4')
      ..initialize().then((_) async {
        if (!mounted) return;

        await _controller!.setLooping(true);
        await _controller!.setVolume(0);

        if (!_controller!.value.isPlaying) {
          await _controller!.play();
        }

        if (!mounted) return;

        setState(() => _isReady = true);
      }).catchError((_) {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: widget.onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 210,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  /// SHIMMER WHILE VIDEO LOADS
                  if (!_isReady)
                    const ShimmerBox(
                      height: double.infinity,
                      radius: 0,
                    ),

                  /// VIDEO
                  if (_isReady &&
                      _controller != null &&
                      _controller!.value.isInitialized)
                    AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                    ),

                  /// DARK OVERLAY
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),

                  /// TEXT CONTENT
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Live Eid Wallpapers',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Chillax',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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