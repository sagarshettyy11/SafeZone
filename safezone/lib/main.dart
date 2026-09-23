import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:safezone/constants/app_colors.dart';
import 'package:safezone/auth/login_page.dart';
import 'package:safezone/auth/register_page.dart';
import 'package:safezone/auth/reset_password.dart';
import 'package:safezone/screens/admin/admin_dashboard.dart';
import 'package:safezone/screens/users/dashboard.dart';
import 'package:safezone/screens/users/user_details.dart';
import 'package:safezone/splash_screen.dart';
import 'package:safezone/landing_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: "flutter.env");
  } catch (e) {
    debugPrint("Notice: could not load flutter.env: $e");
  }

  String rawUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  rawUrl = rawUrl.replaceAll("'", "").replaceAll('"', '').trim();
  if (rawUrl.isEmpty) {
    rawUrl = 'https://xepdkartwvspleadwkxy.supabase.co';
  }

  String rawKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  rawKey = rawKey.replaceAll("'", "").replaceAll('"', '').trim();
  // Strip any accidental leading 'y' or invalid prefixes
  if (rawKey.startsWith('yeyJ')) {
    rawKey = rawKey.substring(1);
  }
  if (rawKey.isEmpty || !rawKey.startsWith('eyJ')) {
    rawKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhlcGRrYXJ0d3ZzcGxlYWR3a3h5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM1MDgxODMsImV4cCI6MjA2OTA4NDE4M30.Mv9PZsC5q-u08j2Z1dxFJ36edNrtRZ1F-wwHuXTYVx4';
  }

  // Initialize Supabase safely
  try {
    await Supabase.initialize(
      url: rawUrl,
      anonKey: rawKey,
    );
  } catch (e) {
    debugPrint("Notice: Supabase already initialized or setup note: $e");
  }

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Listen to auth state changes for password reset flow safely
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;

        if (event == AuthChangeEvent.passwordRecovery && mounted) {
          Future.microtask(() {
            rootNavigatorKey.currentState?.pushNamed('/reset-password');
          });
        }
      });
    } catch (e) {
      debugPrint("Auth state listener notice: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'SafeZone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.success,
          error: AppColors.danger,
          surface: AppColors.surface,
        ),
        // Global bold Inter typography
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFill,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        '/dashboard': (context) => const UserDashboard(),
        '/home': (context) => const UserDashboard(),
        '/admin': (context) => const AdminDashboard(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/user-details': (context) => const UserDetailsPage(),
      },
    );
  }
}