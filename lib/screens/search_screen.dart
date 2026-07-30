import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import '../widgets/movie_grid.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Movie> _allMovies = [];
  List<Movie> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    MovieService().fetchMoviesOnce().then((movies) {
      if (mounted) {
        setState(() {
          _allMovies = movies;
          _results = movies;
          _loading = false;
        });
      }
    });
    _controller.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _controller.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _results = _allMovies;
      } else {
        _results = _allMovies
            .where((m) =>
                m.title.toLowerCase().contains(query) ||
                m.slug.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: TextField(
            controller: _controller,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search movies...',
              hintStyle: TextStyle(color: RooflixTheme.textTertiary),
              prefixIcon: Icon(Icons.search_rounded,
                  color: RooflixTheme.textSecondary),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded,
                          color: RooflixTheme.textSecondary),
                      onPressed: () {
                        _controller.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: RooflixTheme.primary,
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        // Results count
        if (!_loading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_results.length} result${_results.length != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        // Grid
        Expanded(
          child: _loading
              ? const MovieGridShimmer()
              : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 56, color: RooflixTheme.textTertiary),
                          const SizedBox(height: 12),
                          Text(
                            'No results found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : MovieGrid(movies: _results),
        ),
      ],
    );
  }
}
