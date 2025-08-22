import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safezone/settings/account_page.dart';
import 'package:safezone/settings/help_page.dart';
import 'package:safezone/settings/invite_friend.dart';
import 'package:safezone/settings/notification.dart';
import 'package:safezone/settings/privacy_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
      body: ListView(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          // User profile
          ListTile(
            leading: const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.black, size: 30),
            ),
            title: Text(
              "sagarshetty",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              "Real Eyes, Realize, Real Lies",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
            ),
          ),

          const Divider(color: Colors.grey),

          // Account item -> navigates to AccountPage
          buildSettingsItem(
            icon: Icons.key,
            text: "Account",
            context: context,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountPage()),
              );
            },
          ),

          // Other items
          buildSettingsItem(
            icon: Icons.lock_outline,
            text: "Privacy",
            context: context,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPage()),
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
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey,
        size: 16,
      ),
      onTap: onTap, // ✅ FIX: use the passed callback
    );
  }
}
