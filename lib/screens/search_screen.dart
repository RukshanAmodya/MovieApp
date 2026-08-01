import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/app_shell.dart';
import 'movie_player_screen.dart';

class SearchScreen extends StatefulWidget {
  final ValueChanged<AppPage>? onNavigate;
  const SearchScreen({super.key, this.onNavigate});

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
                m.title.toLowerCase().contains(query))
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
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: RooflixTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search movies, titles...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: RooflixTheme.textMuted,
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: RooflixTheme.textMuted,
                      size: 22,
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                color: RooflixTheme.textMuted),
                            onPressed: () => _controller.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: RooflixTheme.surfaceSecondary,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide:
                          BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                          color: RooflixTheme.primary, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Results count / status
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: _loading
                ? Text(
                    'Loading...',
                    style: GoogleFonts.plusJakartaSans(
                      color: RooflixTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Row(
                    children: [
                      Text(
                        '${_results.length} result${_results.length != 1 ? 's' : ''}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: RooflixTheme.textPrimary,
                        ),
                      ),
                      if (_controller.text.isNotEmpty) ...[
                        Text(
                          '  for  ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: RooflixTheme.textMuted,
                          ),
                        ),
                        Text(
                          '"${_controller.text}"',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: RooflixTheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),

        // Grid
        if (_loading)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: MediaQuery.of(context).size.width >= 1600
                    ? 260
                    : (MediaQuery.of(context).size.width >= 960 ? 220 : 180),
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.66,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(color: RooflixTheme.surfaceSecondary),
                ),
                childCount: 8,
              ),
            ),
          )
        else if (_results.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 64, color: RooflixTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No results found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: RooflixTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different search term',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: RooflixTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: MediaQuery.of(context).size.width >= 1600
                    ? 260
                    : (MediaQuery.of(context).size.width >= 960 ? 220 : 180),
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.66,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final movie = _results[index];
                  return MovieCard(
                    movie: movie,
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, anim, secondaryAnim) =>
                              MoviePlayerScreen(movie: movie),
                          transitionsBuilder: (context, anim, secondaryAnim, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration:
                              const Duration(milliseconds: 300),
                        ),
                      );
                    },
                  );
                },
                childCount: _results.length,
              ),
            ),
          ),
      ],
    );
  }
}
