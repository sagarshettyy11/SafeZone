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
        title: const Text("Notifications"),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black,
        child: ListView(
          children: [
            // Show Notifications
            SwitchListTile(
              title: Text(
                "Show notifications",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              ),
              value: showNotifications,
              onChanged: (value) {
                setState(() {
                  showNotifications = value;
                });
              },
              activeColor: Colors.green,
            ),

            const Divider(color: Colors.grey),

            // Reminders
            SwitchListTile(
              title: Text(
                "Reminders",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              ),
              subtitle: Text(
                "Get occasional reminders about messages, calls or status updates you haven’t seen.",
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
              ),
              value: reminders,
              onChanged: (value) {
                setState(() {
                  reminders = value;
                });
              },
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
