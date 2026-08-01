import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/movie.dart';

class MovieService {
  static final MovieService _instance = MovieService._internal();
  factory MovieService() => _instance;
  MovieService._internal();

  static const String _rtdbUrl =
      'https://rooflix-app-default-rtdb.firebaseio.com';

  final DatabaseReference _moviesRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: _rtdbUrl,
  ).ref('movies');

  /// Direct HTTPS REST API fetch (Bypasses WebSocket ISP & DNS blocks on SLT Wi-Fi)
  Future<List<Movie>> fetchMoviesViaHttp() async {
    try {
      final response = await http
          .get(Uri.parse('$_rtdbUrl/movies.json'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data == null) return <Movie>[];

        final List<Movie> movies = [];
        if (data is Map) {
          final entries = data.entries.toList().reversed;
          for (final entry in entries) {
            movies.add(Movie.fromMap(entry.key.toString(), entry.value));
          }
        }
        return movies;
      }
    } catch (e) {
      debugPrint('MovieService REST API fallback error: $e');
    }
    return [];
  }

  /// Returns a live stream of movies with automatic HTTP REST fallback for restricted Wi-Fi networks.
  Stream<List<Movie>> moviesStream() {
    late StreamController<List<Movie>> controller;
    StreamSubscription? dbSub;
    Timer? periodicTimer;

    controller = StreamController<List<Movie>>.broadcast(
      onListen: () {
        bool hasEmittedFromDb = false;

        // Try standard Firebase WebSocket listener
        try {
          dbSub = _moviesRef.orderByKey().onValue.listen(
            (event) {
              final data = event.snapshot.value;
              if (data == null) {
                controller.add(<Movie>[]);
                return;
              }

              final List<Movie> movies = [];
              if (data is Map) {
                final entries = data.entries.toList().reversed;
                for (final entry in entries) {
                  movies.add(Movie.fromMap(entry.key.toString(), entry.value));
                }
              }
              hasEmittedFromDb = true;
              controller.add(movies);
            },
            onError: (err) async {
              debugPrint('Firebase Realtime DB stream error, switching to HTTP REST: $err');
              final httpMovies = await fetchMoviesViaHttp();
              controller.add(httpMovies);
            },
          );
        } catch (e) {
          debugPrint('Firebase Stream listen error: $e');
        }

        // Fast fallback check after 2.5s if WebSocket hasn't responded (e.g. SLT Wi-Fi on Android Projector)
        Future.delayed(const Duration(milliseconds: 2500), () async {
          if (!hasEmittedFromDb && !controller.isClosed) {
            final httpMovies = await fetchMoviesViaHttp();
            if (httpMovies.isNotEmpty && !controller.isClosed) {
              controller.add(httpMovies);
            }
          }
        });

        // Periodic background poll every 15 seconds to ensure fresh data over HTTP REST
        periodicTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
          if (!controller.isClosed) {
            final httpMovies = await fetchMoviesViaHttp();
            if (httpMovies.isNotEmpty && !controller.isClosed) {
              controller.add(httpMovies);
            }
          }
        });
      },
      onCancel: () {
        dbSub?.cancel();
        periodicTimer?.cancel();
      },
    );

    return controller.stream;
  }

  /// Fetch movies once with automatic HTTP REST fallback
  Future<List<Movie>> fetchMoviesOnce() async {
    try {
      final snapshot = await _moviesRef
          .orderByKey()
          .get()
          .timeout(const Duration(seconds: 3));

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        final List<Movie> movies = [];
        if (data is Map) {
          final entries = data.entries.toList().reversed;
          for (final entry in entries) {
            movies.add(Movie.fromMap(entry.key.toString(), entry.value));
          }
        }
        return movies;
      }
    } catch (e) {
      debugPrint('MovieService fetchOnce error/timeout, using HTTPS REST: $e');
    }

    // Fallback to HTTPS REST API
    return await fetchMoviesViaHttp();
  }
}
