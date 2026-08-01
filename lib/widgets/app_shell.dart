import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/focus_helper.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/favorites_screen.dart';

/// Pages in the app
enum AppPage { home, trending, favorites, profile, search }

// ─────────────────────────────────────────────────────────────────────────────
// Global focus nodes so app_shell can hand focus to main content
// ─────────────────────────────────────────────────────────────────────────────

/// Call this from the sidebar to move focus into the main content area.
final FocusScopeNode mainContentScope = FocusScopeNode(debugLabel: 'MainContentScope');

/// Call this from main content to move focus back into the sidebar.
final FocusScopeNode sidebarScope = FocusScopeNode(debugLabel: 'SidebarScope');

// ─────────────────────────────────────────────────────────────────────────────
// AppShell
// ─────────────────────────────────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppPage _currentPage = AppPage.home;

  void _navigate(AppPage page) {
    setState(() => _currentPage = page);
    // After navigation, ensure main content gets focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mainContentScope.requestFocus();
    });
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
          final nav = Navigator.of(context, rootNavigator: false);
          if (nav.canPop()) nav.pop();
        },
        child: isWide
            ? Row(
                children: [
                  // Left Sidebar
                  _NetflixTvRail(
                    currentPage: _currentPage,
                    onNavigate: _navigate,
                  ),

                  // Main Content Area
                  Expanded(
                    child: FocusScope(
                      node: mainContentScope,
                      child: Stack(
                        children: [
                          _buildContent(),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _TopUserBadge(onNavigate: _navigate),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Column(
                    children: [
                      _MobileTopHeader(onNavigate: _navigate),
                      Expanded(child: _buildContent()),
                      const SizedBox(height: 70),
                    ],
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
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
// Netflix TV Collapsible Navigation Rail — fully D-Pad aware
// ─────────────────────────────────────────────────────────────────────────────

class _NetflixTvRail extends StatefulWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onNavigate;

  const _NetflixTvRail({
    required this.currentPage,
    required this.onNavigate,
  });

  @override
  State<_NetflixTvRail> createState() => _NetflixTvRailState();
}

class _NetflixTvRailState extends State<_NetflixTvRail> {
  bool _isExpanded = false;

  void _setExpanded(bool expanded) {
    if (_isExpanded != expanded) {
      setState(() => _isExpanded = expanded);
    }
  }

  /// Move focus from the rail into the main content area
  void _exitToMain() {
    _setExpanded(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mainContentScope.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: sidebarScope,
      onFocusChange: (focused) => _setExpanded(focused),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: _isExpanded ? 240 : 72,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F).withValues(alpha: 0.95),
          border: const Border(
            right: BorderSide(color: Color(0x1AFFFFFF), width: 1),
          ),
          boxShadow: _isExpanded
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ]
              : [],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: RooflixTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: RooflixTheme.primary.withValues(alpha: 0.5),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'R',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ROOFLIX',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: RooflixTheme.primary,
                            letterSpacing: 1.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Nav Items — each handles Right arrow to exit sidebar
              _RailItem(
                icon: Icons.search_rounded,
                label: 'Search',
                isExpanded: _isExpanded,
                isActive: widget.currentPage == AppPage.search,
                onTap: () => widget.onNavigate(AppPage.search),
                onExitRight: _exitToMain,
              ),
              _RailItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isExpanded: _isExpanded,
                isActive: widget.currentPage == AppPage.home,
                onTap: () => widget.onNavigate(AppPage.home),
                onExitRight: _exitToMain,
              ),
              _RailItem(
                icon: Icons.local_fire_department_rounded,
                label: 'Trending',
                isExpanded: _isExpanded,
                isActive: widget.currentPage == AppPage.trending,
                onTap: () => widget.onNavigate(AppPage.trending),
                onExitRight: _exitToMain,
              ),
              _RailItem(
                icon: Icons.favorite_rounded,
                label: 'Favorites',
                isExpanded: _isExpanded,
                isActive: widget.currentPage == AppPage.favorites,
                onTap: () => widget.onNavigate(AppPage.favorites),
                onExitRight: _exitToMain,
              ),
              _RailItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isExpanded: _isExpanded,
                isActive: widget.currentPage == AppPage.profile,
                onTap: () => widget.onNavigate(AppPage.profile),
                onExitRight: _exitToMain,
              ),

              const Spacer(),

              // User info footer
              StreamBuilder<AuthUser?>(
                stream: AuthService().authStateChanges,
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: RooflixTheme.primary,
                          child: Text(
                            user.email.isNotEmpty
                                ? user.email[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_isExpanded) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user.email,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RailItem — individual sidebar nav button with full D-Pad handling
// ─────────────────────────────────────────────────────────────────────────────

class _RailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onExitRight; // called when Right arrow pressed

  const _RailItem({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.isActive,
    required this.onTap,
    required this.onExitRight,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;

          // Select / Enter / OK — activate item
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.gameButtonA) {
            onTap();
            return KeyEventResult.handled;
          }

          // Right arrow — exit sidebar, enter main canvas
          if (key == LogicalKeyboardKey.arrowRight) {
            onExitRight();
            return KeyEventResult.handled;
          }

          // Up/Down — navigate within sidebar using Flutter's spatial policy
          if (key == LogicalKeyboardKey.arrowUp) {
            node.focusInDirection(TraversalDirection.up);
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowDown) {
            node.focusInDirection(TraversalDirection.down);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TvFocusDetector(
        autoScroll: false,
        onSelect: onTap,
        builder: (context, isFocused) {
          final highlighted = isActive || isFocused;

          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isFocused
                    ? RooflixTheme.primary
                    : (isActive
                        ? RooflixTheme.primary.withValues(alpha: 0.15)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(10),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: RooflixTheme.primary.withValues(alpha: 0.5),
                          blurRadius: 16,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isFocused
                        ? Colors.white
                        : (isActive
                            ? RooflixTheme.primary
                            : RooflixTheme.textSecondary),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight:
                              highlighted ? FontWeight.w700 : FontWeight.w500,
                          color: isFocused
                              ? Colors.white
                              : (isActive
                                  ? RooflixTheme.primary
                                  : RooflixTheme.textSecondary),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Right User Badge
// ─────────────────────────────────────────────────────────────────────────────

class _TopUserBadge extends StatelessWidget {
  final ValueChanged<AppPage> onNavigate;
  const _TopUserBadge({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthUser?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: TvFocusDetector(
            onSelect: () => onNavigate(AppPage.profile),
            builder: (context, isFocused) {
              return GestureDetector(
                onTap: () => onNavigate(AppPage.profile),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFocused
                        ? RooflixTheme.primary
                        : Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isFocused
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user != null
                            ? Icons.account_circle_rounded
                            : Icons.login_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user != null
                            ? (user.email.split('@').first)
                            : 'Sign In',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Header & Nav
// ─────────────────────────────────────────────────────────────────────────────

class _MobileTopHeader extends StatelessWidget {
  final ValueChanged<AppPage> onNavigate;
  const _MobileTopHeader({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
      color: RooflixTheme.background,
      child: Row(
        children: [
          Text(
            'ROOFLIX',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: RooflixTheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => onNavigate(AppPage.search),
            icon: const Icon(Icons.search_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onNavigate;
  const _MobileBottomNav(
      {required this.currentPage, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
            icon: Icons.person_rounded,
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
        size: 24,
      ),
    );
  }
}
