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
      duration: const Duration(milliseconds: 250),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
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
    // TvFocusDetector handles D-pad Select/Enter/Space + focus state
    return TvFocusDetector(
      autofocus: widget.autofocus,
      onSelect: widget.onTap,
      builder: (context, isFocused) {
        // Sync animation with focus/hover state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final shouldBeActive = isFocused || _hovering;
          if (shouldBeActive && _ctrl.status != AnimationStatus.forward &&
              _ctrl.status != AnimationStatus.completed) {
            _ctrl.forward();
          } else if (!shouldBeActive &&
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
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFocused
                            ? RooflixTheme.focusRing
                            : Colors.transparent,
                        width: isFocused ? 2.5 : 0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: 0.06 + 0.08 * _shadow.value),
                          blurRadius: 12 + 18 * _shadow.value,
                          offset: Offset(0, 2 + 6 * _shadow.value),
                        ),
                        if (isFocused)
                          BoxShadow(
                            color: RooflixTheme.focusRing.withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cover image — ~75% of card
                          Expanded(
                            flex: 3,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _CoverImage(url: widget.movie.coverUrl),
                                // Play overlay on focus/hover
                                AnimatedOpacity(
                                  opacity: (isFocused || _hovering) ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.5),
                                        ],
                                      ),
                                    ),
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
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 16,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Title
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 10, 12, 10),
                              child: Text(
                                widget.movie.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isFocused || _hovering
                                      ? RooflixTheme.primary
                                      : RooflixTheme.textPrimary,
                                  height: 1.3,
                                ),
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
      placeholder: (context, url) => const _ShimmerPlaceholder(),
      errorWidget: (context, url, error) => const _PlaceholderCover(),
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder();

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        color: RooflixTheme.surfaceSecondary.withValues(alpha: _anim.value),
      ),
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
          size: 48,
          color: RooflixTheme.textMuted.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
