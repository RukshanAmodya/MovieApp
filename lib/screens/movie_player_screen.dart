import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../core/theme.dart';
import '../core/focus_helper.dart';

class MoviePlayerScreen extends StatefulWidget {
  final Movie movie;

  const MoviePlayerScreen({super.key, required this.movie});

  @override
  State<MoviePlayerScreen> createState() => _MoviePlayerScreenState();
}

class _MoviePlayerScreenState extends State<MoviePlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  double _playbackSpeed = 1.0;
  bool _isMuted = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.movie.streamUrl),
      );
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
      _startHideTimer();
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    // Only auto hide controls if the video is currently playing
    if (_isInitialized && _controller.value.isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _controller.value.isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _userInteracted() {
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
    }
    _startHideTimer();
  }

  void _togglePlayPause() {
    if (!_isInitialized || _hasError) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _hideTimer?.cancel();
        _showControls = true;
      } else {
        _controller.play();
        _showControls = true;
        _startHideTimer();
      }
    });
  }

  void _toggleMute() {
    _userInteracted();
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _cycleSpeed() {
    _userInteracted();
    final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
    final nextIndex = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    setState(() {
      _playbackSpeed = speeds[nextIndex];
      _controller.setPlaybackSpeed(_playbackSpeed);
    });
  }

  void _seekRelative(Duration duration) {
    if (!_isInitialized || _hasError) return;
    _userInteracted();
    final currentPos = _controller.value.position;
    final newPos = currentPos + duration;
    _controller.seekTo(newPos);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: TvKeyboardShortcuts(
        onBack: () => Navigator.of(context).pop(),
        onPlayPause: _togglePlayPause,
        onSeekLeft: () => _seekRelative(const Duration(seconds: -10)),
        onSeekRight: () => _seekRelative(const Duration(seconds: 10)),
        child: MouseRegion(
          onHover: (_) => _userInteracted(),
          child: GestureDetector(
            onTap: _toggleControlsVisibility,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Video Player Area
                Center(
                  child: _hasError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.error_outline_rounded,
                                  color: Colors.white70, size: 54),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Playback Error',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Unable to load video stream from source server.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : _isInitialized
                          ? AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: VideoPlayer(_controller),
                            )
                          : const CircularProgressIndicator(
                              color: RooflixTheme.primary,
                              strokeWidth: 3,
                            ),
                ),

                // 2. Animated Overlay Player Controls (Auto-hides after 4s YouTube style)
                IgnorePointer(
                  ignoring: !_showControls,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Stack(
                      children: [
                        // Top Header Bar with Back Button & Movie Title
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(24, 36, 24, 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.85),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Back Circle Button
                                TvFocusDetector(
                                  onSelect: () => Navigator.of(context).pop(),
                                  builder: (context, isFocused) {
                                    return InkWell(
                                      onTap: () => Navigator.of(context).pop(),
                                      borderRadius: BorderRadius.circular(30),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isFocused
                                              ? RooflixTheme.primary
                                              : Colors.white.withValues(alpha: 0.18),
                                          shape: BoxShape.circle,
                                          boxShadow: isFocused
                                              ? [
                                                  BoxShadow(
                                                    color: RooflixTheme.primary
                                                        .withValues(alpha: 0.5),
                                                    blurRadius: 16,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: const Icon(Icons.arrow_back_rounded,
                                            color: Colors.white, size: 24),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 16),
                                // Movie Title Header
                                Expanded(
                                  child: Text(
                                    widget.movie.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Center Floating Glass Playback Capsule
                        if (_isInitialized && !_hasError)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 28,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // -10s Rewind
                                  TvFocusDetector(
                                    onSelect: () =>
                                        _seekRelative(const Duration(seconds: -10)),
                                    builder: (context, isFocused) {
                                      return IconButton(
                                        iconSize: 28,
                                        icon: Icon(
                                          Icons.replay_10_rounded,
                                          color: isFocused
                                              ? RooflixTheme.primary
                                              : Colors.white,
                                        ),
                                        onPressed: () =>
                                            _seekRelative(const Duration(seconds: -10)),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),

                                  // Main Play / Pause Button
                                  TvFocusDetector(
                                    onSelect: _togglePlayPause,
                                    builder: (context, isFocused) {
                                      return GestureDetector(
                                        onTap: _togglePlayPause,
                                        child: Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            color: RooflixTheme.primary,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: RooflixTheme.primary
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 20,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                            border: isFocused
                                                ? Border.all(
                                                    color: Colors.white, width: 2.5)
                                                : null,
                                          ),
                                          child: Icon(
                                            _controller.value.isPlaying
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),

                                  // +10s Fast Forward
                                  TvFocusDetector(
                                    onSelect: () =>
                                        _seekRelative(const Duration(seconds: 10)),
                                    builder: (context, isFocused) {
                                      return IconButton(
                                        iconSize: 28,
                                        icon: Icon(
                                          Icons.forward_10_rounded,
                                          color: isFocused
                                              ? RooflixTheme.primary
                                              : Colors.white,
                                        ),
                                        onPressed: () =>
                                            _seekRelative(const Duration(seconds: 10)),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Bottom Timeline & Options Toolbar
                        if (_isInitialized && !_hasError)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.92),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 1. D-Pad Navigable Progress Scrub Bar
                                  TvFocusDetector(
                                    onSelect: _togglePlayPause,
                                    builder: (context, isFocused) {
                                      return Focus(
                                        onKeyEvent: (node, event) {
                                          if (event is KeyDownEvent) {
                                            final key = event.logicalKey;
                                            if (key == LogicalKeyboardKey.arrowLeft) {
                                              _seekRelative(const Duration(seconds: -10));
                                              return KeyEventResult.handled;
                                            }
                                            if (key == LogicalKeyboardKey.arrowRight) {
                                              _seekRelative(const Duration(seconds: 10));
                                              return KeyEventResult.handled;
                                            }
                                          }
                                          return KeyEventResult.ignored;
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isFocused
                                                ? RooflixTheme.primary.withValues(alpha: 0.15)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isFocused
                                                  ? RooflixTheme.primary
                                                  : Colors.transparent,
                                              width: isFocused ? 2.0 : 0.0,
                                            ),
                                            boxShadow: isFocused
                                                ? [
                                                    BoxShadow(
                                                      color: RooflixTheme.primary
                                                          .withValues(alpha: 0.5),
                                                      blurRadius: 16,
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ValueListenableBuilder(
                                                valueListenable: _controller,
                                                builder: (context, VideoPlayerValue value, child) {
                                                  return VideoProgressIndicator(
                                                    _controller,
                                                    allowScrubbing: true,
                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                    colors: VideoProgressColors(
                                                      playedColor: RooflixTheme.primary,
                                                      bufferedColor: Colors.white30,
                                                      backgroundColor:
                                                          isFocused ? Colors.white24 : Colors.white12,
                                                    ),
                                                  );
                                                },
                                              ),
                                              if (isFocused)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(
                                                    '◄ Use Left / Right D-Pad to Seek 10s ►',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),

                                  // 2. Time Labels & Control Pills Row
                                  ValueListenableBuilder(
                                    valueListenable: _controller,
                                    builder: (context, VideoPlayerValue value, child) {
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Elapsed Time
                                          Text(
                                            _formatDuration(value.position),
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),

                                          // Action Pills (Mute, Speed) & Total Duration
                                          Row(
                                            children: [
                                              // Mute/Unmute Option Pill
                                              TvFocusDetector(
                                                onSelect: _toggleMute,
                                                builder: (context, isFocused) {
                                                  return InkWell(
                                                    onTap: _toggleMute,
                                                    borderRadius:
                                                        BorderRadius.circular(16),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: isFocused
                                                            ? RooflixTheme.primary
                                                            : Colors.white
                                                                .withValues(alpha: 0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(16),
                                                        border: Border.all(
                                                          color: Colors.white
                                                              .withValues(alpha: 0.2),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            _isMuted
                                                                ? Icons.volume_off_rounded
                                                                : Icons.volume_up_rounded,
                                                            color: Colors.white,
                                                            size: 16,
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            _isMuted
                                                                ? 'Muted'
                                                                : 'Sound On',
                                                            style: GoogleFonts
                                                                .plusJakartaSans(
                                                              color: Colors.white,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight.w700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 10),

                                              // Playback Speed Option Pill
                                              TvFocusDetector(
                                                onSelect: _cycleSpeed,
                                                builder: (context, isFocused) {
                                                  return InkWell(
                                                    onTap: _cycleSpeed,
                                                    borderRadius:
                                                        BorderRadius.circular(16),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: isFocused
                                                            ? RooflixTheme.primary
                                                            : Colors.white
                                                                .withValues(alpha: 0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(16),
                                                        border: Border.all(
                                                          color: Colors.white
                                                              .withValues(alpha: 0.2),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons.speed_rounded,
                                                              color: Colors.white,
                                                              size: 16),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            '${_playbackSpeed}x',
                                                            style: GoogleFonts
                                                                .plusJakartaSans(
                                                              color: Colors.white,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight.w700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 16),

                                              // Total Duration
                                              Text(
                                                _formatDuration(value.duration),
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
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
        ),
      ),
    );
  }
}
