import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/focus_helper.dart';
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
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _firstCardFocusNode = FocusNode();

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
            .where((m) => m.title.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchFocusNode.dispose();
    _firstCardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 1600
        ? 6
        : (screenWidth >= 1200
            ? 5
            : (screenWidth >= 800 ? 4 : 2));

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header & Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 32, 40, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 18),

                // Search bar with full D-Pad key handling
                TvFocusDetector(
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  autoScroll: false,
                  onSelect: () => _searchFocusNode.requestFocus(),
                  builder: (context, isFocused) {
                    return KeyboardListener(
                      focusNode: FocusNode(skipTraversal: true),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent) {
                          final key = event.logicalKey;

                          // Left arrow → back to sidebar
                          if (key == LogicalKeyboardKey.arrowLeft) {
                            _searchFocusNode.unfocus();
                            sidebarScope.requestFocus();
                            return;
                          }

                          // Right arrow → unfocus search bar and go to first card
                          if (key == LogicalKeyboardKey.arrowRight) {
                            _searchFocusNode.unfocus();
                            // Focus first result card (if any)
                            if (_results.isNotEmpty) {
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) {
                                _firstCardFocusNode.requestFocus();
                              });
                            }
                            return;
                          }

                          // Down arrow → go to first card in grid
                          if (key == LogicalKeyboardKey.arrowDown) {
                            _searchFocusNode.unfocus();
                            if (_results.isNotEmpty) {
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) {
                                _firstCardFocusNode.requestFocus();
                              });
                            }
                            return;
                          }
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: RooflixTheme.surfaceSecondary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFocused
                                ? RooflixTheme.primary
                                : Colors.white.withValues(alpha: 0.12),
                            width: isFocused ? 2.5 : 1.0,
                          ),
                          boxShadow: isFocused
                              ? [
                                  BoxShadow(
                                    color: RooflixTheme.primary
                                        .withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _searchFocusNode,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search movies, titles, genres...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: RooflixTheme.textMuted,
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: RooflixTheme.primary,
                              size: 24,
                            ),
                            suffixIcon: _controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        color: Colors.white70),
                                    onPressed: () {
                                      _controller.clear();
                                      _onSearch();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Results count label
                if (!_loading)
                  Row(
                    children: [
                      Text(
                        _controller.text.isEmpty
                            ? 'Top Picks & All Titles'
                            : 'Search Results for ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: RooflixTheme.textSecondary,
                        ),
                      ),
                      if (_controller.text.isNotEmpty)
                        Text(
                          '"${_controller.text}"',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: RooflixTheme.primary,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // Grid
        if (_loading)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 24,
                crossAxisSpacing: 20,
                childAspectRatio: 0.66,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child:
                      Container(color: RooflixTheme.surfaceSecondary),
                ),
                childCount: 12,
              ),
            ),
          )
        else if (_results.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: RooflixTheme.surfaceSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 56,
                      color: RooflixTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No movies found matching "${_controller.text}"',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try searching with a different keyword or title',
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
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 24,
                crossAxisSpacing: 20,
                childAspectRatio: 0.66,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final movie = _results[index];
                  final isFirstInRow = (index % crossAxisCount) == 0;
                  final isFirst = index == 0;

                  return Focus(
                    // Only assign the tracked first-card node to index 0
                    focusNode: isFirst ? _firstCardFocusNode : null,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        final key = event.logicalKey;

                        // Left on first-in-row → sidebar
                        if (key == LogicalKeyboardKey.arrowLeft &&
                            isFirstInRow) {
                          sidebarScope.requestFocus();
                          return KeyEventResult.handled;
                        }

                        // Up on first row → back to search bar
                        if (key == LogicalKeyboardKey.arrowUp &&
                            index < crossAxisCount) {
                          _searchFocusNode.requestFocus();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: MovieCard(
                      movie: movie,
                      isFirstInRow: isFirstInRow,
                      focusNode: isFirst ? _firstCardFocusNode : null,
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, anim, secondaryAnim) =>
                                MoviePlayerScreen(movie: movie),
                            transitionsBuilder:
                                (context, anim, secondaryAnim, child) =>
                                    FadeTransition(
                                        opacity: anim, child: child),
                            transitionDuration:
                                const Duration(milliseconds: 250),
                          ),
                        );
                      },
                    ),
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
