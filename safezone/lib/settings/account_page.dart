import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Account",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildTile(context, "Two-step verification", () {}),
                _buildTile(context, "Change Email address", () {
                  _changeEmailDialog();
                }),
                _buildTile(context, "Change Contact number", () {
                  _updateProfileField("phone");
                }),
                _buildTile(context, "Change Emergency Contact", () {
                  _updateProfileField("emergency_contact");
                }),
                const Divider(color: Colors.grey),
                _buildTile(context, "Download Account Information", () {}),
                _buildTile(context, "Delete my account", () {
                  _deleteAccountDialog();
                }),
              ],
            ),
          ),
          // Logout button at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E4DE8),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await supabase.auth.signOut();

                if (!context.mounted) return; // ✅ safe check

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Logged out successfully")),
                );

                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text(
                "Logout",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------------- EMAIL CHANGE ----------------------
  void _changeEmailDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Change Email",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: SizedBox(
          width: 300,
          height: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.2),
            ),
            child: TextField(
              controller: emailController,
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
              decoration: InputDecoration(
                hintText: "Enter new email",
                hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEmail = emailController.text.trim();
              if (newEmail.isEmpty) return;

              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(email: newEmail),
                );

                if (!mounted) return; // ✅ safe check
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Email updated successfully")),
                );
                Navigator.pop(context);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: Text("Save", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// ---------------------- PROFILE FIELD UPDATE ----------------------
  void _updateProfileField(String fieldName) {
    final TextEditingController controller = TextEditingController();
    final userId = Supabase.instance.client.auth.currentUser?.id;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Update ${fieldName.replaceAll("_", " ")}",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: SizedBox(
          width: 300,
          height: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.2),
            ),
            child: TextField(
              controller: controller,
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
              decoration: InputDecoration(
                hintText: "Enter new ${fieldName.replaceAll("_", " ")}",
                hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isEmpty || userId == null) return;

              try {
                await Supabase.instance.client
                    .from("profiles")
                    .update({fieldName: newValue})
                    .eq("id", userId);

                if (!mounted) return; // ✅ safe check
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$fieldName updated successfully")),
                );
                Navigator.pop(context);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// ---------------------- DELETE ACCOUNT ----------------------
  void _deleteAccountDialog() {
    final TextEditingController passwordController = TextEditingController();
    final user = Supabase.instance.client.auth.currentUser;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "⚠ This will delete all your data from Safezone. "
              "If you still want to delete your account, please enter your password below.",
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "Enter your password",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isEmpty || user == null) return;

              try {
                // Re-authenticate user
                final email = user.email!;
                final res = await Supabase.instance.client.auth
                    .signInWithPassword(email: email, password: password);

                if (!mounted) return; // ✅ check after await

                if (res.user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid password")),
                  );
                  return;
                }

                // Delete profile first
                await Supabase.instance.client
                    .from("profiles")
                    .delete()
                    .eq("id", user.id);

                if (!mounted) return; // ✅ check after await

                // Delete user from auth (admin call required in production via edge function)
                await Supabase.instance.client.auth.admin.deleteUser(user.id);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Account deleted successfully")),
                );

                Navigator.pushReplacementNamed(context, '/login');
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error deleting account: $e")),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  /// ---------------------- TILE BUILDER ----------------------
  Widget _buildTile(BuildContext context, String title, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}
