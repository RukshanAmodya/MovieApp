import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/movie.dart';

class MovieService {
  static final MovieService _instance = MovieService._internal();
  factory MovieService() => _instance;
  MovieService._internal();

  final DatabaseReference _moviesRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://rooflix-app-default-rtdb.firebaseio.com',
  ).ref('movies');

  /// Returns a live stream of movies from Firebase Realtime DB.
  /// Preserves exact Firebase push key insertion order (oldest -> newest / top -> bottom).
  Stream<List<Movie>> moviesStream() {
    return _moviesRef.orderByKey().onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Movie>[];

      final List<Movie> movies = [];
      if (data is Map) {
        // Firebase orderByKey() preserves exact database key order (push() order)
        final entries = data.entries.toList();
        for (final entry in entries) {
          movies.add(Movie.fromMap(entry.key.toString(), entry.value));
        }
      }
      return movies;
    });
  }

  /// Fetch movies once in exact Firebase order.
  Future<List<Movie>> fetchMoviesOnce() async {
    final snapshot = await _moviesRef.orderByKey().get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = snapshot.value;
    final List<Movie> movies = [];
    if (data is Map) {
      final entries = data.entries.toList();
      for (final entry in entries) {
        movies.add(Movie.fromMap(entry.key.toString(), entry.value));
      }
    }
    return movies;
  }
}
