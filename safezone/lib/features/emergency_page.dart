import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  final String policeNumber = "100";
  final String ambulanceNumber = "108";
  final String fireNumber = "101";

  void _makeCall(String number) async {
    final Uri url = Uri(scheme: "tel", path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw "Could not launch $number";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Emergency Help",
          style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big SOS button
          Center(
            child: GestureDetector(
              onTap: () {
                _makeCall(ambulanceNumber); // default action
              },
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.6),
                      blurRadius: 0,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "SOS",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 40),

          // Quick Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DefaultTextStyle(
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                child: _buildActionButton(
                  Icons.local_police,
                  "Police",
                  policeNumber,
                ),
              ),
              DefaultTextStyle(
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                child: _buildActionButton(
                  Icons.local_hospital,
                  "Ambulance",
                  ambulanceNumber,
                ),
              ),
              DefaultTextStyle(
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                child: _buildActionButton(
                  Icons.local_fire_department,
                  "Fire",
                  fireNumber,
                ),
              ),
            ],
          ),

          SizedBox(height: 40),

          // Share location button (placeholder)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Location sharing not implemented yet")),
              );
            },
            icon: Icon(Icons.location_on, color: Colors.white),
            label: Text(
              "Share My Location",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, String number) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            _makeCall(number);
          },
          child: CircleAvatar(
            radius: 35,
            backgroundColor: Colors.red,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
