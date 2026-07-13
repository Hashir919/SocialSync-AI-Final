import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
    try {
      await Supabase.initialize(
        url: 'https://urkhxwbrcypgmgkzluto.supabase.co',
        anonKey: 'sb_publishable_bgUp9-NHt4VOSVPtqwu1mQ_doA_O1UW',
      );
    } catch (e) {
      // In test environments or when Supabase cannot be reached, ignore the error.
      debugPrint('Supabase initialization failed: $e');
    }

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SocialSyncApp(),
    ),
  );
}

class SocialSyncApp extends ConsumerWidget {
  const SocialSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'SocialSync AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}


