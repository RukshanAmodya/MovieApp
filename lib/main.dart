import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'widgets/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const AppShell(),
    );
  }
}
