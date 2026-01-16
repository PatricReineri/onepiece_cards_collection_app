import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

/// Main entry point for One Piece TCG Collection app
/// Following brand guidelines: modern, card-based design with glassmorphism
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for immersive dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F172A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const OnePieceCollectorApp());
}

/// Root widget for the One Piece TCG Collection app
class OnePieceCollectorApp extends StatelessWidget {
  const OnePieceCollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'One Piece TCG Collection',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
