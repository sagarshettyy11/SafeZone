import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InviteFriendPage extends StatelessWidget {
  const InviteFriendPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Invite a Friend",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(children: [_buildItem(context, "Invite via Link")]),
          ),
        ],
      ),
    );
  }
}

Widget _buildItem(BuildContext context, String title) {
  return ListTile(
    title: Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
    onTap: () {},
  );
}
