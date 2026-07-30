import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';

enum NavTab { home, movies, series, search }

class TvNavBar extends StatelessWidget {
  final NavTab selectedTab;
  final ValueChanged<NavTab> onTabSelected;

  const TvNavBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  static const List<_TabItem> _tabs = [
    _TabItem(tab: NavTab.home, label: 'Home', icon: Icons.home_rounded),
    _TabItem(tab: NavTab.movies, label: 'Movies', icon: Icons.movie_rounded),
    _TabItem(tab: NavTab.series, label: 'Series', icon: Icons.tv_rounded),
    _TabItem(tab: NavTab.search, label: 'Search', icon: Icons.search_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RooflixTheme.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Centered pill tab bar
          Stack(
            children: [
              // Centered pill tab bar
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: RooflixTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _tabs.map((item) {
                        final isSelected = selectedTab == item.tab;
                        return _TabPill(
                          item: item,
                          isSelected: isSelected,
                          onTap: () => onTabSelected(item.tab),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              // Profile / Login button on top right
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: StreamBuilder(
                    stream: AuthService().authStateChanges,
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      return IconButton(
                        icon: Icon(
                          user != null
                              ? Icons.account_circle_rounded
                              : Icons.login_rounded,
                          color: user != null
                              ? RooflixTheme.primary
                              : RooflixTheme.textSecondary,
                        ),
                        tooltip: user != null ? 'Account (${user.email})' : 'Sign In',
                        onPressed: () {
                          if (user != null) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Account'),
                                content: Text('Signed in as:\n${user.email}'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Close'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await AuthService().signOut();
                                    },
                                    child: const Text('Sign Out'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AuthScreen(),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Separator line
          Container(
            height: 0.5,
            color: RooflixTheme.separator.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  final NavTab tab;
  final String label;
  final IconData icon;
  const _TabItem({required this.tab, required this.label, required this.icon});
}

class _TabPill extends StatefulWidget {
  final _TabItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabPill({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TabPill> createState() => _TabPillState();
}

class _TabPillState extends State<_TabPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? RooflixTheme.primary
                  : (_isFocused
                      ? RooflixTheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(50),
              border: _isFocused && !widget.isSelected
                  ? Border.all(color: RooflixTheme.primary, width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.item.icon,
                  size: 16,
                  color: widget.isSelected
                      ? Colors.white
                      : (_isFocused
                          ? RooflixTheme.primary
                          : RooflixTheme.textSecondary),
                ),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: widget.isSelected
                        ? Colors.white
                        : (_isFocused
                            ? RooflixTheme.primary
                            : RooflixTheme.textSecondary),
                  ),
                  child: Text(widget.item.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
