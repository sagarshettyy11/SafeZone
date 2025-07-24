import 'package:flutter/material.dart';

class CreateAccountPage extends StatelessWidget {
  const CreateAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((0.18 * 255).round()),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Create an account so you can explore all the existing jobs",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 32),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {}, // Add sign up logic
                    child: const Text(
                      "Sign up",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/login'),
                  child: const Text(
                    "Already have an account",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Or continue with",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialIcon(Icons.g_mobiledata_outlined),
                    const SizedBox(width: 16),
                    _socialIcon(Icons.facebook),
                    const SizedBox(width: 16),
                    _socialIcon(Icons.apple),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _socialIcon(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 28, color: Colors.black87),
    );
  }
}
