import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/movies_screen.dart';
import 'screens/series_screen.dart';
import 'screens/search_screen.dart';
import 'widgets/tv_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RooflixApp());
}

class RooflixApp extends StatelessWidget {
  const RooflixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rooflix',
      debugShowCheckedModeBanner: false,
      theme: RooflixTheme.lightTheme,
      home: const RooflixShell(),
    );
  }
}

class RooflixShell extends StatefulWidget {
  const RooflixShell({super.key});

  @override
  State<RooflixShell> createState() => _RooflixShellState();
}

class _RooflixShellState extends State<RooflixShell> {
  NavTab _currentTab = NavTab.home;

  static const List<Widget> _screens = [
    HomeScreen(),
    MoviesScreen(),
    SeriesScreen(),
    SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooflixTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Apple TV-style centered pill nav at top
            TvNavBar(
              selectedTab: _currentTab,
              onTabSelected: (tab) => setState(() => _currentTab = tab),
            ),
            // Tab content — IndexedStack keeps state alive
            Expanded(
              child: IndexedStack(
                index: _currentTab.index,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
