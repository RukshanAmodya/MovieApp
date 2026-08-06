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
  final FocusNode? focusNode;
  final KeyEventResult Function(FocusNode node, KeyEvent event)? onKeyEvent;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.autofocus = false,
    this.width = 160,
    this.isFirstInRow = false,
    this.focusNode,
    this.onKeyEvent,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return TvFocusDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      autoScroll: false,
      onSelect: widget.onTap,
      onKeyEvent: widget.onKeyEvent,
      builder: (context, isFocused) {
        final active = isFocused || _hovering;

        return MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: active ? 1.10 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
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
                      color: Colors.black.withValues(alpha: active ? 0.8 : 0.5),
                      blurRadius: active ? 25 : 10,
                      offset: const Offset(0, 4),
                    ),
                    if (active)
                      BoxShadow(
                        color: RooflixTheme.primary.withValues(alpha: 0.5),
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
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
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
                              duration: const Duration(milliseconds: 180),
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
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w600,
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

