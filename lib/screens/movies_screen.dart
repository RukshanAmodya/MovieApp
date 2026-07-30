import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import '../widgets/movie_grid.dart';

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Movie>>(
      stream: MovieService().moviesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MovieGridShimmer();
        }

        if (snapshot.hasError) {
          return _ErrorView(error: snapshot.error.toString());
        }

        final movies = snapshot.data ?? [];

        if (movies.isEmpty) {
          return const _EmptyView();
        }

        return MovieGrid(
          movies: movies,
          onMovieTap: (movie) {
            // TODO: Navigate to player screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Playing: ${movie.title}'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: RooflixTheme.primary,
              ),
            );
          },
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 64, color: RooflixTheme.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Connection Error',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.movie_creation_outlined,
              size: 64, color: RooflixTheme.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No Movies Yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add movies to Firebase to see them here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
