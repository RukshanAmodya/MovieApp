import 'package:flutter/material.dart';
import '../core/focus_helper.dart';
import '../models/movie.dart';
import 'movie_card.dart';

class MovieGrid extends StatelessWidget {
  final List<Movie> movies;
  final void Function(Movie movie)? onMovieTap;

  const MovieGrid({
    super.key,
    required this.movies,
    this.onMovieTap,
  });

  /// Returns column count based on screen width for responsive layout.
  int _columnCount(double width) {
    if (width >= 1440) return 5;
    if (width >= 1024) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  /// Card aspect ratio: poster format (2:3 — width:height)
  static const double _cardAspectRatio = 2 / 3.4;

  @override
  Widget build(BuildContext context) {
    return TvGridFocusGroup(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = _columnCount(constraints.maxWidth);
          return GridView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth > 1024 ? 40 : 16,
              vertical: 20,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 18,
              childAspectRatio: _cardAspectRatio,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return MovieCard(
                key: ValueKey(movie.id),
                movie: movie,
                autofocus: index == 0,
                onTap: () => onMovieTap?.call(movie),
              );
            },
          );
        },
      ),
    );
  }
}

/// Shimmer loading grid shown while Firebase data is loading.
class MovieGridShimmer extends StatelessWidget {
  const MovieGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1440
            ? 5
            : constraints.maxWidth >= 1024
                ? 4
                : constraints.maxWidth >= 600
                    ? 3
                    : 2;
        return GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth > 1024 ? 40 : 16,
            vertical: 20,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 18,
            childAspectRatio: MovieGrid._cardAspectRatio,
          ),
          itemCount: 12,
          itemBuilder: (context, index) => const _ShimmerCard(),
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade200,
                      Colors.grey.shade100,
                      Colors.grey.shade200,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 11,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 11,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
