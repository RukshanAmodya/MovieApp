import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'services/api_service.dart';
import 'widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
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
