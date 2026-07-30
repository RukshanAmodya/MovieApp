import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme.dart';
import '../core/focus_helper.dart';
import '../models/movie.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final bool autofocus;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.autofocus = false,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onFocusChange(bool focused) {
    if (focused) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TvFocusDetector(
      autofocus: widget.autofocus,
      onSelect: widget.onTap,
      builder: (context, isFocused) {
        // Trigger scale animation on focus change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onFocusChange(isFocused);
        });

        return ScaleTransition(
          scale: _scaleAnim,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: RooflixTheme.cardDecoration(focused: isFocused),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isFocused ? 16 : 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover image
                    Expanded(
                      child: _CoverImage(
                        url: widget.movie.coverUrl,
                        isFocused: isFocused,
                      ),
                    ),
                    // Title section
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Text(
                        widget.movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isFocused
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isFocused
                              ? RooflixTheme.primary
                              : RooflixTheme.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String url;
  final bool isFocused;

  const _CoverImage({required this.url, required this.isFocused});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _PlaceholderCover(isFocused: isFocused);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: RooflixTheme.surfaceSecondary,
        highlightColor: Colors.white,
        child: Container(
          color: RooflixTheme.surfaceSecondary,
        ),
      ),
      errorWidget: (context, url, error) =>
          _PlaceholderCover(isFocused: isFocused),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  final bool isFocused;
  const _PlaceholderCover({required this.isFocused});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RooflixTheme.surfaceSecondary,
      child: Center(
        child: Icon(
          Icons.movie_rounded,
          size: 48,
          color: isFocused
              ? RooflixTheme.primary
              : RooflixTheme.textTertiary,
        ),
      ),
    );
  }
}
