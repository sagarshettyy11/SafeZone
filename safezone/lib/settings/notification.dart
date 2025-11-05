import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState(); // ✅ return type fixed
}

class _NotificationPageState extends State<NotificationPage> {
  bool showNotifications = true;
  bool reminders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            // Show Notifications
            SwitchListTile(
              title: Text(
                "Show notifications",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              value: showNotifications,
              onChanged: (value) {
                setState(() {
                  showNotifications = value;
                });
              },
              activeThumbColor: Colors.green,
            ),

            const Divider(color: Colors.grey),

            // Reminders
            SwitchListTile(
              title: Text(
                "Reminders",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                "Get occasional reminders about messages, calls or status updates you haven’t seen.",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              value: reminders,
              onChanged: (value) {
                setState(() {
                  reminders = value;
                });
              },
              activeThumbColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
