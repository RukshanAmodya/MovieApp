import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/focus_helper.dart';
import '../models/movie.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final bool autofocus;
  final double width;
  final bool isFirstInRow;

  /// Optional external FocusNode — used by _NetflixMovieRow to control focus.
  /// When provided, the card does NOT dispose it.
  final FocusNode? focusNode;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.autofocus = false,
    this.width = 160,
    this.isFirstInRow = false,
    this.focusNode,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onActive(bool active) {
    if (active) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
    setState(() => _hovering = active);
  }

  @override
  Widget build(BuildContext context) {
    return TvFocusDetector(
      // Use external focusNode if provided (owned by parent row)
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      autoScroll: false, // row handles scrolling itself
      onSelect: widget.onTap,
      builder: (context, isFocused) {
        final active = isFocused || _hovering;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (active &&
              _ctrl.status != AnimationStatus.forward &&
              _ctrl.status != AnimationStatus.completed) {
            _ctrl.forward();
          } else if (!active &&
              _ctrl.status != AnimationStatus.reverse &&
              _ctrl.status != AnimationStatus.dismissed) {
            _ctrl.reverse();
          }
        });

        return MouseRegion(
          onEnter: (_) => _onActive(true),
          onExit: (_) => _onActive(isFocused),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    width: widget.width,
                    decoration: BoxDecoration(
                      color: RooflixTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? RooflixTheme.primary
                            : Colors.white.withValues(alpha: 0.08),
                        width: active ? 3.0 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: 0.5 + 0.3 * _glow.value),
                          blurRadius: 10 + 15 * _glow.value,
                          offset: const Offset(0, 4),
                        ),
                        if (active)
                          BoxShadow(
                            color:
                                RooflixTheme.primary.withValues(alpha: 0.5),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Poster image (2:3 aspect ratio)
                          AspectRatio(
                            aspectRatio: 2 / 3,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _CoverImage(url: widget.movie.coverUrl),

                                // Vignette gradient
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(
                                            alpha: active ? 0.85 : 0.5),
                                      ],
                                      stops: const [0.5, 1.0],
                                    ),
                                  ),
                                ),

                                // HD badge
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black
                                          .withValues(alpha: 0.75),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.2),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      'HD',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ),

                                // Play overlay on focus
                                AnimatedOpacity(
                                  opacity: active ? 1.0 : 0.0,
                                  duration:
                                      const Duration(milliseconds: 180),
                                  child: Center(
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: RooflixTheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: RooflixTheme.primary
                                                .withValues(alpha: 0.6),
                                            blurRadius: 18,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Title
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            color: RooflixTheme.surface,
                            width: double.infinity,
                            child: Text(
                              widget.movie.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : RooflixTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String url;
  const _CoverImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _PlaceholderCover();
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) =>
          Container(color: RooflixTheme.surfaceSecondary),
      errorWidget: (context, url, error) => const _PlaceholderCover(),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RooflixTheme.surfaceSecondary,
      child: Center(
        child: Icon(
          Icons.movie_rounded,
          size: 38,
          color: RooflixTheme.textMuted.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
