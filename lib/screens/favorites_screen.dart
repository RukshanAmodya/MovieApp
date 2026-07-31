import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';

class FavoritesScreen extends StatelessWidget {
  final ValueChanged<AppPage>? onNavigate;
  const FavoritesScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: RooflixTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 40,
              color: RooflixTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your Favorites',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: RooflixTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to save and view your favorite movies',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: RooflixTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => onNavigate?.call(AppPage.profile),
            icon: const Icon(Icons.login_rounded),
            label: Text(
              'Sign In',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: RooflixTheme.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
