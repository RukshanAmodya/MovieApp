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

  /// Returns a live stream of all movies from Firebase Realtime DB.
  Stream<List<Movie>> moviesStream() {
    return _moviesRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Movie>[];

      final List<Movie> movies = [];
      if (data is Map) {
        data.forEach((key, value) {
          movies.add(Movie.fromMap(key.toString(), value));
        });
      } else if (data is List) {
        for (int i = 0; i < data.length; i++) {
          if (data[i] != null) {
            movies.add(Movie.fromMap(i.toString(), data[i]));
          }
        }
      }

      // Sort alphabetically by title
      movies.sort((a, b) => a.title.compareTo(b.title));
      return movies;
    });
  }

  /// Fetch movies once (no live updates).
  Future<List<Movie>> fetchMoviesOnce() async {
    final snapshot = await _moviesRef.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = snapshot.value;
    final List<Movie> movies = [];
    if (data is Map) {
      data.forEach((key, value) {
        movies.add(Movie.fromMap(key.toString(), value));
      });
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        if (data[i] != null) {
          movies.add(Movie.fromMap(i.toString(), data[i]));
        }
      }
    }
    movies.sort((a, b) => a.title.compareTo(b.title));
    return movies;
  }
}
