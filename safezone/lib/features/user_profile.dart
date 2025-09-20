import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safezone/settings/account_page.dart';
import 'package:safezone/settings/help_page.dart';
import 'package:safezone/settings/invite_friend.dart';
import 'package:safezone/settings/notification.dart';
import 'package:safezone/settings/privacy_page.dart';
import 'package:safezone/settings/edit_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<Map<String, dynamic>?> getUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return null;

    // Query the profiles table for logged-in user
    final response = await supabase
        .from('profiles')
        .select('username, user_bio, profile_image_url')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;

    final imagePath = response['profile_image_url'] as String?;

    if (imagePath != null && imagePath.isNotEmpty) {
      // ✅ Handle both full URL and storage path cases
      if (imagePath.startsWith('http')) {
        response['profile_url'] = imagePath;
      } else {
        final imageUrl = supabase.storage
            .from('profile-images')
            .getPublicUrl(imagePath);
        response['profile_url'] = imageUrl;
      }
    } else {
      response['profile_url'] = null;
    }

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data;
          final username = data?['username'] ?? "Unknown User";
          final bio = data?['user_bio'] ?? "No bio added";
          final String? profileUrl = data?['profile_url'];

          return ListView(
            children: [
              // 🔍 Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search",
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.all(0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.poppins(color: Colors.black),
                ),
              ),

              // 👤 User profile tile
              ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profileUrl != null
                      ? NetworkImage(profileUrl)
                      : null,
                  onBackgroundImageError: profileUrl != null
                      ? (_, _) {
                          debugPrint(
                            "❌ Failed to load profile image: $profileUrl",
                          );
                        }
                      : null,
                  child: profileUrl == null
                      ? const Icon(Icons.person, color: Colors.black, size: 30)
                      : null,
                ),

                title: Text(
                  username,
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  bio,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  );
                },
              ),

              const Divider(color: Colors.grey),

              // ⚙️ Settings items
              buildSettingsItem(
                icon: Icons.key,
                text: "Account",
                context: context,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountPage(),
                    ),
                  );
                },
              ),
              buildSettingsItem(
                icon: Icons.lock_outline,
                text: "Privacy",
                context: context,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPage(),
                    ),
                  );
                },
              ),
              buildSettingsItem(
                icon: Icons.notifications_none,
                text: "Notifications",
                context: context,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  );
                },
              ),
              buildSettingsItem(
                icon: Icons.help_outline,
                text: "Help",
                context: context,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpPage()),
                  );
                },
              ),
              buildSettingsItem(
                icon: Icons.group_add,
                text: "Invite a Friend",
                context: context,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InviteFriendPage(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildSettingsItem({
    required IconData icon,
    required String text,
    required BuildContext context,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
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
