import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/home/home_screen.dart';
import 'services/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initFirebase();

  // Supabase powers the Xendit checkout. A failure here must never stop the
  // store from opening; the checkout screen shows a readable error instead.
  await AppBootstrap.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const FirstGearGymApp(),
    ),
  );
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    // Desktop targets are not configured in firebase_options.dart. The product
    // service falls back to its bundled demo catalogue, so the app still runs.
    developer.log(
      'Firebase initialisation failed; using the demo catalogue.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class FirstGearGymApp extends StatelessWidget {
  const FirstGearGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    const charcoal = Color(0xFF121212);
    const accentRed = Color(0xFFE50914);

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: charcoal,
        colorScheme: const ColorScheme.dark(
          primary: accentRed,
          secondary: accentRed,
          surface: Color(0xFF1E1E1E),
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: charcoal,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: AppConfig.isConfigured ? const HomeScreen() : const ConfigScreen(),
    );
  }
}

/// Shown only when both the `.env` file and the built-in defaults are missing.
class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration Required')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supabase not configured',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Create a `.env` file in the project root with your Supabase '
              'credentials (copy `.env.example` to `.env` and fill in the '
              'values):',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade900,
              child: const Text(
                'SUPABASE_URL=https://your-project.supabase.co\n'
                'SUPABASE_ANON_KEY=your-anon-public-key',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Then restart the app. The `.env` file is local-only and must '
              'never be committed to Git.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
