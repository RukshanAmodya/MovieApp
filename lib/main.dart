import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'widgets/app_shell.dart';

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
      home: const AppShell(),
    );
  }
}
