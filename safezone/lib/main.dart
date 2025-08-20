import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'welcome_page.dart';
import 'login_page.dart';
import 'create_account.dart';
import 'reset_password.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: "flutter.env"); // Ensure file is named .env

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
    // If session exists, start at dashboard, else welcome screen

    return MaterialApp(
      title: 'Safe Zone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const CreateAccountPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
      },
    );
  }
}
