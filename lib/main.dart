import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/services/auth_service.dart';
import 'package:habit_tracker/services/habit_service.dart';
import 'package:habit_tracker/services/theme_service.dart';
import 'package:habit_tracker/screens/auth/login_screen.dart';
import 'package:habit_tracker/screens/home/home_screen.dart';
import 'package:habit_tracker/firebase_options.dart';
import 'package:habit_tracker/config/theme.dart';
import 'package:habit_tracker/services/notification_service.dart';
import 'package:habit_tracker/services/reward_service.dart';
import 'package:habit_tracker/services/journal_service.dart';
import 'package:habit_tracker/services/partnership_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only once
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: 'habittracker',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  // Initialize SharedPreferences
  await SharedPreferences.getInstance();

  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProxyProvider<AuthService, HabitService?>(
          create: (_) => null,
          update: (_, auth, __) =>
              auth.currentUser != null ? HabitService(auth.currentUser!.uid) : null,
        ),
        ChangeNotifierProxyProvider<AuthService, RewardService?>(
          create: (_) => null,
          update: (_, auth, __) =>
              auth.currentUser != null ? RewardService(auth.currentUser!.uid) : null,
        ),
        ChangeNotifierProxyProvider<AuthService, JournalService?>(
          create: (_) => null,
          update: (_, auth, __) =>
              auth.currentUser != null ? JournalService(auth.currentUser!.uid) : null,
        ),
        ChangeNotifierProxyProvider<AuthService, PartnershipService?>(
          create: (_) => null,
          update: (_, auth, __) =>
              auth.currentUser != null ? PartnershipService(auth.currentUser!.uid) : null,
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Daily Habit Tracker',
            debugShowCheckedModeBanner: false,
            themeMode: themeService.themeMode,
            theme: AppTheme.lightTheme(themeService.primaryColor),
            darkTheme: AppTheme.darkTheme(themeService.primaryColor),
            home: Consumer<AuthService>(
              builder: (context, authService, _) {
                return authService.currentUser != null
                    ? const HomeScreen()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
