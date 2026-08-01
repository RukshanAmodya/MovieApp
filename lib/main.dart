import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'widgets/app_shell.dart';

import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable offline persistence so data stays cached and readable on WiFi
  try {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  } catch (e) {
    debugPrint('FirebaseDatabase setPersistenceEnabled error: $e');
  }

  // App Check for private/internal APKs (not published on Play Store)
  try {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('6Lco1m8tAAAAALc_X891iPRHZRAG3kn12y74A4D2'),
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.appAttest,
    );
  } catch (e) {
    debugPrint('Firebase App Check initialization error: $e');
  }

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
