import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Admin constants
  static const String adminEmail = "admin@safezone.com";
  static const String adminPassword = "admin123";

  User? get currentUser => _supabase.auth.currentUser;
  String? get currentUserId => _supabase.auth.currentUser?.id;
  String? get currentUserEmail => _supabase.auth.currentUser?.email;

  /// Check if user or admin is currently logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedPref = prefs.getBool('is_logged_in') ?? false;
    final session = _supabase.auth.currentSession;
    final user = _supabase.auth.currentUser;

    if (prefs.getBool('is_admin') == true && isLoggedPref) {
      return true;
    }

    return session != null || (isLoggedPref && user != null);
  }

  /// Check if the logged-in session belongs to Admin
  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_admin') ?? false;
  }

  /// Sign In with Email and Password
  /// Returns a Map: {'success': bool, 'isAdmin': bool, 'message': String}
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    // Check for hardcoded Admin credentials
    if (cleanEmail == adminEmail && cleanPassword == adminPassword) {
      try {
        await _supabase.auth.signInWithPassword(
          email: cleanEmail,
          password: cleanPassword,
        );
      } catch (e) {
        debugPrint("Admin Supabase auth fallback notice: $e");
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_admin', true);
      await prefs.setString('user_email', adminEmail);

      return {
        'success': true,
        'isAdmin': true,
        'message': 'Logged in as Administrator',
      };
    }

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      if (response.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setBool('is_admin', false);
        await prefs.setString('user_id', response.user!.id);
        if (response.user!.email != null) {
          await prefs.setString('user_email', response.user!.email!);
        }

        return {
          'success': true,
          'isAdmin': false,
          'user': response.user,
          'message': 'Login successful',
        };
      } else {
        return {
          'success': false,
          'isAdmin': false,
          'message': 'Invalid login credentials',
        };
      }
    } catch (e) {
      String message = 'Something went wrong. Please try again.';
      final errorString = e.toString();

      if (errorString.contains('Invalid login credentials')) {
        message = 'Incorrect email or password. Please try again.';
      } else if (errorString.contains('Network') || errorString.contains('SocketException')) {
        message = 'Network error. Please check your internet connection.';
      } else if (errorString.contains('Email not confirmed')) {
        message = 'Please confirm your email before signing in.';
      }

      debugPrint('AuthService.signIn error: $e');
      return {'success': false, 'isAdmin': false, 'message': message};
    }
  }

  /// Sign Up with Email and Password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setBool('is_admin', false);
        await prefs.setString('user_id', response.user!.id);
        if (response.user!.email != null) {
          await prefs.setString('user_email', response.user!.email!);
        }

        return {
          'success': true,
          'user': response.user,
          'message': 'Account created successfully!',
        };
      }

      return {
        'success': false,
        'message': 'Signup failed. Please try again.',
      };
    } catch (e) {
      debugPrint('AuthService.signUp error: $e');
      return {
        'success': false,
        'message': 'Signup error: ${e.toString()}',
      };
    }
  }

  /// Reset Password by Email
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'https://safezone.app/reset-callback',
      );
      return {
        'success': true,
        'message': 'Password reset link sent to your email!',
      };
    } catch (e) {
      debugPrint('AuthService.sendPasswordResetEmail error: $e');
      String msg = 'Unable to send reset email. Please try again later.';
      if (e.toString().contains('Invalid email')) {
        msg = 'Please enter a valid email address.';
      }
      return {'success': false, 'message': msg};
    }
  }

  /// Update Password for authenticated user
  Future<Map<String, dynamic>> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword.trim()),
      );

      if (response.user != null) {
        return {
          'success': true,
          'message': 'Password updated successfully!',
        };
      }
      return {
        'success': false,
        'message': 'Failed to update password.',
      };
    } catch (e) {
      debugPrint('AuthService.updatePassword error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Sign Out and Clear Session
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('AuthService.signOut error: $e');
    }
  }
}
