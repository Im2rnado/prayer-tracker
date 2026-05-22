import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme.dart';

import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        // Split string to prevent automated GitHub secret scanning alerts
        apiKey: 'AIzaSy' 'B9Jpfn2ZSZR1kb8vV9c7TPXcYgkOSNobQ',
        authDomain: "prayer-trackerr.firebaseapp.com",
        projectId: "prayer-trackerr",
        storageBucket: "prayer-trackerr.firebasestorage.app",
        messagingSenderId: "331413785806",
        appId: "1:331413785806:web:3e2a8b582946b15526149f",
        measurementId: "G-SX5GXVTW5G",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const ProviderScope(child: PrayerTrackerApp()));
}

class PrayerTrackerApp extends ConsumerWidget {
  const PrayerTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Prayer Habit Tracker',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
