import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'welcome_page.dart';
import 'login_page.dart';
import 'create_account.dart';
import 'reset_password.dart';
import 'features/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: "flutter.env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Listen to auth state changes for password reset flow
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      if (event == AuthChangeEvent.passwordRecovery && mounted) {
        Future.microtask(() {
          if (!mounted) return;
          Navigator.pushNamed(context, '/reset-password');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Zone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(), // ✅ Global Poppins Font
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/welcome': (context) => const WelcomeScreen(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const CreateAccountPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
      },
    );
  }
}

/// ✅ AuthGate to check SharedPreferences and Supabase session on app startup
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedPref = prefs.getBool('is_logged_in') ?? false;
    final session = Supabase.instance.client.auth.currentSession;
    final user = Supabase.instance.client.auth.currentUser;

    if (mounted) {
      setState(() {
        _isAuthenticated = (session != null || (isLoggedPref && user != null));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isAuthenticated) {
      return const HomePage();
    }

    return const WelcomeScreen();
  }
}