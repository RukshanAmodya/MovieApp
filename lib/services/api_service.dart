// =============================================================
// Central API Service for Rooflix
// All requests go through Cloudflare Worker backend
// =============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl =
      'https://movieapp.rukshan-amodaya-e.workers.dev';

  static const Duration _timeout = Duration(seconds: 12);

  // ---- Auth Session State ----
  static String? _idToken;
  static String? _email;
  static String? _uid;

  static final StreamController<AuthUser?> _authController =
      StreamController<AuthUser?>.broadcast();

  /// Stream that emits when auth state changes (null = signed out)
  static Stream<AuthUser?> get authStateChanges => _authController.stream;

  /// Current signed-in user (null if not signed in)
  static AuthUser? get currentUser =>
      _idToken != null ? AuthUser(email: _email!, uid: _uid!) : null;

  // ---- Helper for Safe JSON Parsing ----
  static dynamic _parseResponseBody(http.Response res) {
    final body = res.body.trim();
    if (body.isEmpty) {
      throw Exception('Server returned empty response (Status ${res.statusCode})');
    }
    try {
      return json.decode(body);
    } catch (_) {
      throw Exception('Invalid response format (Status ${res.statusCode})');
    }
  }

  // ---- Auth Methods ----

  static Future<AuthUser> signIn(
      {required String email, required String password}) async {
    final res = await http
        .post(
          Uri.parse('$_baseUrl/auth/signin'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': email, 'password': password}),
        )
        .timeout(_timeout);

    final data = _parseResponseBody(res);
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Sign in failed');
    }

    _idToken = data['idToken'];
    _email = data['email'];
    _uid = data['uid'];
    final user = AuthUser(email: _email!, uid: _uid!);
    _authController.add(user);
    return user;
  }

  static Future<AuthUser> signUp(
      {required String email, required String password}) async {
    final res = await http
        .post(
          Uri.parse('$_baseUrl/auth/signup'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': email, 'password': password}),
        )
        .timeout(_timeout);

    final data = _parseResponseBody(res);
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Sign up failed');
    }

    _idToken = data['idToken'];
    _email = data['email'];
    _uid = data['uid'];
    final user = AuthUser(email: _email!, uid: _uid!);
    _authController.add(user);
    return user;
  }

  static Future<void> signOut() async {
    _idToken = null;
    _email = null;
    _uid = null;
    _authController.add(null);
  }

  // ---- Movies ----

  static Future<List<dynamic>> fetchMovies() async {
    if (_idToken == null) {
      throw Exception('Not authenticated');
    }

    final res = await http
        .get(
          Uri.parse('$_baseUrl/movies'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_idToken',
          },
        )
        .timeout(_timeout);

    if (res.statusCode == 401) {
      await signOut();
      throw Exception('Session expired. Please sign in again.');
    }

    final data = _parseResponseBody(res);
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to fetch movies');
    }

    return data as List<dynamic>;
  }

  // ---- Health Check ----

  static Future<bool> isWorkerReachable() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Worker unreachable: $e');
      return false;
    }
  }
}

// ---- Data Models ----

class AuthUser {
  final String email;
  final String uid;
  final String? displayName;

  const AuthUser({required this.email, required this.uid, this.displayName});
}
