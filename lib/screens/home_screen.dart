import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';
import '../core/focus_helper.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/app_shell.dart';
import 'movie_player_screen.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<AppPage>? onNavigate;
  final bool filterTrending;

  const HomeScreen({
    super.key,
    this.onNavigate,
    this.filterTrending = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Movie>>(
      stream: MovieService().moviesStream(),
      builder: (context, snapshot) {
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting;

        if (isLoading) {
          return const _LoadingView();
        }

        final movies = snapshot.data ?? [];

        if (movies.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.movie_filter_rounded,
                    size: 64, color: RooflixTheme.textMuted),
                const SizedBox(height: 16),
                Text(
                  'No movies available right now',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: RooflixTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final heroMovie = movies.first;
        final trendingMovies = movies.take(10).toList();
        final popularMovies = movies.skip(2).take(10).toList();
        final recentMovies = movies.reversed.take(10).toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Billboard Section
              _NetflixHeroBillboard(
                movie: heroMovie,
                onPlay: () {
                  Navigator.of(context).push(
                    _fadeRoute(MoviePlayerScreen(movie: heroMovie)),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Category Row 1: Trending Now
              _NetflixMovieRow(
                title: filterTrending ? 'Trending Now' : 'Trending Now',
                movies: trendingMovies.isEmpty ? movies : trendingMovies,
              ),

              const SizedBox(height: 24),

              // Category Row 2: Popular Movies
              _NetflixMovieRow(
                title: 'Popular on RooFlix',
                movies: popularMovies.isEmpty ? movies : popularMovies,
              ),

              const SizedBox(height: 24),

              // Category Row 3: New Releases
              _NetflixMovieRow(
                title: 'Recently Added',
                movies: recentMovies.isEmpty ? movies : recentMovies,
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, anim, secAnim) => page,
      transitionsBuilder: (context, anim, secAnim, child) {
        return FadeTransition(opacity: anim, child: child);
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Netflix Hero Billboard (Hero Section)
// ─────────────────────────────────────────────────────────────────────────────

class _NetflixHeroBillboard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onPlay;

  const _NetflixHeroBillboard({
    required this.movie,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.55;

    return SizedBox(
      height: height.clamp(360.0, 520.0),
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Backdrop Image
          if (movie.coverUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: movie.coverUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorWidget: (context, url, error) =>
                  Container(color: RooflixTheme.surfaceSecondary),
            )
          else
            Container(color: RooflixTheme.surfaceSecondary),

          // Left Gradient Vignette
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  RooflixTheme.background,
                  RooflixTheme.background.withValues(alpha: 0.85),
                  RooflixTheme.background.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),

          // Bottom Gradient Vignette
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  RooflixTheme.background,
                  RooflixTheme.background.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Content Info Overlay
          Positioned(
            left: 40,
            bottom: 30,
            right: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // N ORIGINAL Badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: RooflixTheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'R',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ROOFLIX ORIGINAL',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Movie Title
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Metadata Badges (4K, 5.1, Year)
                Row(
                  children: [
                    _MetaBadge('2026'),
                    const SizedBox(width: 8),
                    _MetaBadge('4K ULTRA HD'),
                    const SizedBox(width: 8),
                    _MetaBadge('5.1 AUDIO'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '16+',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Action Buttons (Play & Info)
                Row(
                  children: [
                    // Play Button
                    TvFocusDetector(
                      autofocus: true,
                      onSelect: onPlay,
                      builder: (context, isFocused) {
                        return GestureDetector(
                          onTap: onPlay,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 12),
                            decoration: BoxDecoration(
                              color: isFocused
                                  ? RooflixTheme.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isFocused
                                  ? [
                                      BoxShadow(
                                        color: RooflixTheme.primary
                                            .withValues(alpha: 0.6),
                                        blurRadius: 24,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: isFocused
                                      ? Colors.white
                                      : Colors.black,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Play',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isFocused
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 14),

                    // More Info Button
                    TvFocusDetector(
                      onSelect: onPlay,
                      builder: (context, isFocused) {
                        return GestureDetector(
                          onTap: onPlay,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: isFocused
                                  ? RooflixTheme.primary
                                  : Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isFocused
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'More Info',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 15,
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
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  const _MetaBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white.withValues(alpha: 0.8),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Netflix Horizontal Movie Row (Horizontal Scrollable Carousel for D-Pad)
// ─────────────────────────────────────────────────────────────────────────────

class _NetflixMovieRow extends StatelessWidget {
  final String title;
  final List<Movie> movies;

  const _NetflixMovieRow({
    required this.title,
    required this.movies,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ),
        SizedBox(
          height: 270,
          child: TvGridFocusGroup(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 40),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  child: MovieCard(
                    movie: movie,
                    width: 150,
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              MoviePlayerScreen(movie: movie),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                              FadeTransition(opacity: animation, child: child),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading View Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: RooflixTheme.primary,
      ),
    );
  }
}
