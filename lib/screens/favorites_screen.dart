import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/focus_helper.dart';
import '../widgets/app_shell.dart';

class FavoritesScreen extends StatelessWidget {
  final ValueChanged<AppPage>? onNavigate;
  const FavoritesScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: RooflixTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: RooflixTheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 44,
                color: RooflixTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Favorites List',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sign in to save and sync your favorite movies across all your TV devices',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: RooflixTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TvFocusDetector(
              autofocus: true,
              onSelect: () => onNavigate?.call(AppPage.profile),
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    FocusScope.of(context)
                        .focusInDirection(TraversalDirection.left);
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              builder: (context, isFocused) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: RooflixTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFocused ? Colors.white : Colors.transparent,
                      width: isFocused ? 2.5 : 0.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: RooflixTheme.primary
                            .withValues(alpha: isFocused ? 0.6 : 0.3),
                        blurRadius: isFocused ? 24 : 12,
                        spreadRadius: isFocused ? 2 : 0,
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => onNavigate?.call(AppPage.profile),
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: Text(
                      'Sign In Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
