import 'package:flutter/material.dart';
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
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _cycleSpeed() {
    final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
    final nextIndex = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    setState(() {
      _playbackSpeed = speeds[nextIndex];
      _controller.setPlaybackSpeed(_playbackSpeed);
    });
  }

  void _seekRelative(Duration duration) {
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
        child: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Video Display Layer
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

              // 2. Glassmorphism OS Controls Overlay
              if (_showControls) ...[
                // Top Header Bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(28, 44, 28, 24),
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
                                      : Colors.white.withValues(alpha: 0.15),
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
                              fontSize: 20,
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

                // Center Glass Floating Playback Controls Bar
                if (_isInitialized && !_hasError)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
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
                                iconSize: 32,
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
                          const SizedBox(width: 16),

                          // Main Play / Pause Button
                          TvFocusDetector(
                            onSelect: _togglePlayPause,
                            builder: (context, isFocused) {
                              return GestureDetector(
                                onTap: _togglePlayPause,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: RooflixTheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: RooflixTheme.primary
                                            .withValues(alpha: 0.5),
                                        blurRadius: 24,
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
                                    size: 36,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),

                          // +10s Fast Forward
                          TvFocusDetector(
                            onSelect: () =>
                                _seekRelative(const Duration(seconds: 10)),
                            builder: (context, isFocused) {
                              return IconButton(
                                iconSize: 32,
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
                      padding: const EdgeInsets.fromLTRB(36, 24, 36, 36),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.9),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Progress Bar & Duration Labels
                          ValueListenableBuilder(
                            valueListenable: _controller,
                            builder: (context, VideoPlayerValue value, child) {
                              return Column(
                                children: [
                                  VideoProgressIndicator(
                                    _controller,
                                    allowScrubbing: true,
                                    colors: const VideoProgressColors(
                                      playedColor: RooflixTheme.primary,
                                      bufferedColor: Colors.white24,
                                      backgroundColor: Colors.white12,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(value.position),
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
                          const SizedBox(height: 16),

                          // Quick Action Pill Toolbar (Speed, Mute/Unmute)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Mute/Unmute Option Pill
                              TvFocusDetector(
                                onSelect: _toggleMute,
                                builder: (context, isFocused) {
                                  return InkWell(
                                    onTap: _toggleMute,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isFocused
                                            ? RooflixTheme.primary
                                            : Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
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
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _isMuted ? 'Muted' : 'Sound On',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),

                              // Playback Speed Option Pill
                              TvFocusDetector(
                                onSelect: _cycleSpeed,
                                builder: (context, isFocused) {
                                  return InkWell(
                                    onTap: _cycleSpeed,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isFocused
                                            ? RooflixTheme.primary
                                            : Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.speed_rounded,
                                              color: Colors.white, size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${_playbackSpeed}x',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
