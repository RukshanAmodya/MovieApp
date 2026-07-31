import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/focus_helper.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/favorites_screen.dart';

/// Pages in the app
enum AppPage { home, trending, favorites, profile, search }

/// Root shell with sidebar + content area (matches index.html layout)
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppPage _currentPage = AppPage.home;

  void _navigate(AppPage page) {
    setState(() => _currentPage = page);
  }

  Widget _buildContent() {
    switch (_currentPage) {
      case AppPage.home:
        return HomeScreen(onNavigate: _navigate);
      case AppPage.trending:
        return HomeScreen(onNavigate: _navigate, filterTrending: true);
      case AppPage.favorites:
        return FavoritesScreen(onNavigate: _navigate);
      case AppPage.profile:
        return const AuthScreen();
      case AppPage.search:
        return SearchScreen(onNavigate: _navigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 768;

    return Scaffold(
      backgroundColor: RooflixTheme.background,
      body: TvKeyboardShortcuts(
        onBack: () {
          // Allow Navigator to pop if there's a route to pop
          final nav = Navigator.of(context, rootNavigator: false);
          if (nav.canPop()) nav.pop();
        },
        child: isWide
          ? Row(
              children: [
                // --- Left Sidebar ---
                _Sidebar(currentPage: _currentPage, onNavigate: _navigate),
                // --- Main content ---
                Expanded(
                  child: Column(
                    children: [
                      _TopHeader(onNavigate: _navigate),
                      Expanded(child: _buildContent()),
                    ],
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                Column(
                  children: [
                    _TopHeader(onNavigate: _navigate),
                    Expanded(child: _buildContent()),
                    const SizedBox(height: 80),
                  ],
                ),
                // Mobile bottom nav
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 16,
                  child: _MobileBottomNav(
                    currentPage: _currentPage,
                    onNavigate: _navigate,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Left Sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onNavigate;
  const _Sidebar({required this.currentPage, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        border: Border(right: BorderSide(color: RooflixTheme.separator, width: 1)),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                        child: Text(
                          'RooFlix',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: RooflixTheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),

                      // Explore section
                      _SectionLabel('Explore'),
                      _SidebarItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        isActive: currentPage == AppPage.home,
                        onTap: () => onNavigate(AppPage.home),
                      ),
                      _SidebarItem(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Trending',
                        isActive: currentPage == AppPage.trending,
                        onTap: () => onNavigate(AppPage.trending),
                      ),
                      _SidebarItem(
                        icon: Icons.favorite_rounded,
                        label: 'Favorites',
                        isActive: currentPage == AppPage.favorites,
                        onTap: () => onNavigate(AppPage.favorites),
                      ),

                      const SizedBox(height: 24),

                      // Account section
                      _SectionLabel('Account'),
                      _SidebarItem(
                        icon: Icons.account_circle_rounded,
                        label: 'Profile',
                        isActive: currentPage == AppPage.profile,
                        onTap: () => onNavigate(AppPage.profile),
                      ),

                      const Spacer(),

                      // User footer
                      StreamBuilder(
                        stream: AuthService().authStateChanges,
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          if (user == null) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: RooflixTheme.surfaceSecondary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: RooflixTheme.separator),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: RooflixTheme.primaryLight,
                                  child: Text(
                                    (user.email?.isNotEmpty == true
                                            ? user.email![0].toUpperCase()
                                            : 'U'),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: RooflixTheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        user.displayName ?? 'User',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: RooflixTheme.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        user.email ?? '',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: RooflixTheme.textMuted,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // Sign out button
                      StreamBuilder(
                        stream: AuthService().authStateChanges,
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          if (user == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            child: TextButton.icon(
                              onPressed: () async => await AuthService().signOut(),
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: Text('Log Out',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700)),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade400,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: RooflixTheme.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    // TvFocusDetector gives us D-pad Select/Enter + isFocused state
    return TvFocusDetector(
      onSelect: widget.onTap,
      builder: (context, isFocused) {
        final highlighted = active || _hovering || isFocused;
        return MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: active
                    ? RooflixTheme.primary.withValues(alpha: 0.08)
                    : (highlighted
                        ? RooflixTheme.primary.withValues(alpha: 0.05)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(14),
                border: isFocused && !active
                    ? Border.all(
                        color: RooflixTheme.focusRing.withValues(alpha: 0.4),
                        width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color: highlighted
                        ? RooflixTheme.primary
                        : RooflixTheme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: highlighted
                          ? RooflixTheme.primary
                          : RooflixTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Header
// ─────────────────────────────────────────────────────────────────────────────

class _TopHeader extends StatefulWidget {
  final ValueChanged<AppPage> onNavigate;
  const _TopHeader({required this.onNavigate});

  @override
  State<_TopHeader> createState() => _TopHeaderState();
}

class _TopHeaderState extends State<_TopHeader> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(color: RooflixTheme.separator, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Search bar
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (v) {
                    if (v.isNotEmpty) {
                      widget.onNavigate(AppPage.search);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search movies, series...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: RooflixTheme.textMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: RooflixTheme.textMuted,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: RooflixTheme.surfaceSecondary,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: RooflixTheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),

            // Auth buttons
            StreamBuilder(
              stream: AuthService().authStateChanges,
              builder: (context, snapshot) {
                final user = snapshot.data;
                if (user != null) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.email ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: RooflixTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => widget.onNavigate(AppPage.profile),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: RooflixTheme.primaryLight,
                          child: Text(
                            user.email?.isNotEmpty == true
                                ? user.email![0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.plusJakartaSans(
                              color: RooflixTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => widget.onNavigate(AppPage.profile),
                      style: TextButton.styleFrom(
                        foregroundColor: RooflixTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => widget.onNavigate(AppPage.profile),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RooflixTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        shadowColor:
                            RooflixTheme.primary.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        'Join',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Bottom Nav
// ─────────────────────────────────────────────────────────────────────────────

class _MobileBottomNav extends StatelessWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onNavigate;
  const _MobileBottomNav(
      {required this.currentPage, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: RooflixTheme.separator),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MobileNavItem(
            icon: Icons.home_rounded,
            page: AppPage.home,
            currentPage: currentPage,
            onTap: onNavigate,
          ),
          _MobileNavItem(
            icon: Icons.local_fire_department_rounded,
            page: AppPage.trending,
            currentPage: currentPage,
            onTap: onNavigate,
          ),
          _MobileNavItem(
            icon: Icons.search_rounded,
            page: AppPage.search,
            currentPage: currentPage,
            onTap: onNavigate,
          ),
          _MobileNavItem(
            icon: Icons.favorite_rounded,
            page: AppPage.favorites,
            currentPage: currentPage,
            onTap: onNavigate,
          ),
          _MobileNavItem(
            icon: Icons.account_circle_rounded,
            page: AppPage.profile,
            currentPage: currentPage,
            onTap: onNavigate,
          ),
        ],
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final IconData icon;
  final AppPage page;
  final AppPage currentPage;
  final ValueChanged<AppPage> onTap;

  const _MobileNavItem({
    required this.icon,
    required this.page,
    required this.currentPage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentPage == page;
    return IconButton(
      onPressed: () => onTap(page),
      icon: Icon(
        icon,
        color: isActive ? RooflixTheme.primary : RooflixTheme.textMuted,
        size: 26,
      ),
    );
  }
}
