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

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.autofocus = false,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _shadow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _shadow = Tween<double>(begin: 0.0, end: 1.0).animate(
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
      autofocus: widget.autofocus,
      onSelect: widget.onTap,
      builder: (context, isFocused) {
        final active = isFocused || _hovering;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (active && _ctrl.status != AnimationStatus.forward &&
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
                    decoration: BoxDecoration(
                      color: RooflixTheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: active
                            ? RooflixTheme.primary
                            : Colors.white.withValues(alpha: 0.8),
                        width: active ? 3.0 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: 0.06 + 0.12 * _shadow.value),
                          blurRadius: 16 + 24 * _shadow.value,
                          offset: Offset(0, 4 + 10 * _shadow.value),
                        ),
                        if (active)
                          BoxShadow(
                            color: RooflixTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 28,
                            spreadRadius: 3,
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Poster image section
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _CoverImage(url: widget.movie.coverUrl),

                                // Subtle top gradient overlay
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.2),
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: active ? 0.7 : 0.4),
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ),
                                  ),
                                ),

                                // HD / 4K TV Badge on poster
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(6),
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

                                // Apple TV style play icon overlay on focus/hover
                                AnimatedOpacity(
                                  opacity: active ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 180),
                                  child: Center(
                                    child: Container(
                                      width: 48,
                                      height: 48,
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
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Title section below poster
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.white,
                            width: double.infinity,
                            child: Text(
                              widget.movie.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: active
                                    ? RooflixTheme.primary
                                    : RooflixTheme.textPrimary,
                                letterSpacing: -0.2,
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
      placeholder: (context, url) => Container(color: RooflixTheme.surfaceSecondary),
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
          size: 42,
          color: RooflixTheme.textMuted.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
