import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safezone/constants/app_colors.dart';
import 'package:safezone/services/auth_services.dart';
import 'package:safezone/widgets/auth_widgets.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isPasswordUpdateMode = false;

  @override
  void initState() {
    super.initState();
    // If user is already in a password recovery session
    if (_authService.currentUser != null) {
      _isPasswordUpdateMode = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authService.sendPasswordResetEmail(email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] as String),
        backgroundColor: result['success'] == true
            ? AppColors.success
            : AppColors.danger,
      ),
    );

    if (result['success'] == true) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleUpdatePassword() async {
    final newPassword = _passwordController.text.trim();
    if (newPassword.isEmpty || newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authService.updatePassword(newPassword);
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] as String),
        backgroundColor: result['success'] == true
            ? AppColors.success
            : AppColors.danger,
      ),
    );

    if (result['success'] == true) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AuthHeader(
                  title: _isPasswordUpdateMode ? "New Password" : "Reset Password",
                  subtitle: _isPasswordUpdateMode
                      ? "Create a new strong password for your account"
                      : "Enter your registered email and we'll send you recovery instructions",
                  icon: Icons.lock_reset_rounded,
                ),
                const SizedBox(height: 36),

                if (!_isPasswordUpdateMode) ...[
                  AuthTextField(
                    controller: _emailController,
                    label: "Email Address",
                    hint: "name@example.com",
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleSendResetLink(),
                  ),
                  const SizedBox(height: 28),
                  AuthButton(
                    text: "Send Reset Link",
                    onPressed: _handleSendResetLink,
                    isLoading: _isLoading,
                  ),
                ] else ...[
                  AuthTextField(
                    controller: _passwordController,
                    label: "New Password",
                    hint: "At least 6 characters",
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleUpdatePassword(),
                  ),
                  const SizedBox(height: 28),
                  AuthButton(
                    text: "Update Password",
                    onPressed: _handleUpdatePassword,
                    isLoading: _isLoading,
                  ),
                ],

                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Back to Sign In",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
