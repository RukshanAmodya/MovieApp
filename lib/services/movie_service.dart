import '../models/movie.dart';
import '../services/api_service.dart';

class MovieService {
  static final MovieService _instance = MovieService._internal();
  factory MovieService() => _instance;
  MovieService._internal();

  /// Returns a stream of movies from Worker API (polls every 30s for updates)
  Stream<List<Movie>> moviesStream() async* {
    // Emit immediately
    yield await _fetchMovies();

    // Then poll every 30 seconds for fresh data
    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      yield await _fetchMovies();
    }
  }

  /// Fetch movies once from Worker
  Future<List<Movie>> fetchMoviesOnce() => _fetchMovies();

  Future<List<Movie>> _fetchMovies() async {
    try {
      final raw = await ApiService.fetchMovies();
      return raw
          .map((e) => Movie.fromMap(e['id']?.toString() ?? '', e))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
