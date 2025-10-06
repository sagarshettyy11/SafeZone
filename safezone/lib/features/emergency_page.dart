import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:another_telephony/telephony.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

final telephony = Telephony.instance;
final logger = Logger();

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  bool _isSending = false;

  final String policeNumber = "100";
  final String ambulanceNumber = "108";
  final String fireNumber = "101";

  Future<void> _requestPermissions() async {
    await Permission.location.request();
    await Permission.sms.request();
    await Permission.phone.request();
  }

  Future<Position> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw "Location services are disabled";
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw "Location permissions are denied";
      }
    }

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    return await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }

  Future<String?> _getEmergencyContact() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    logger.i("Logged-in user ID: $userId");
    if (userId == null) return null;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('emergency_contact')
        .eq('id', userId)
        .maybeSingle();

    logger.i("Fetched profile: $profile");
    return profile?['emergency_contact'] as String?;
  }

  Future<void> _sendSMS(String number, String message) async {
    await telephony.sendSms(to: number, message: message, isMultipart: true);
    logger.i("SMS sent to $number");
  }

  Future<void> _sendWhatsApp(String number, String message) async {
  String formattedNumber = number.startsWith("+91") ? number : "+91$number";

  // ✅ First, try launching via native WhatsApp scheme
  final whatsappUri = Uri.parse("whatsapp://send?phone=$formattedNumber&text=${Uri.encodeComponent(message)}");

  if (await canLaunchUrl(whatsappUri)) {
    await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  } else {
    // ❌ Native failed — try web fallback
    final webUri = Uri.parse("https://wa.me/$formattedNumber?text=${Uri.encodeFull(message)}");
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not open WhatsApp (neither app nor web)";
    }
  }
}

  Future<void> _handleSOS() async {
    setState(() => _isSending = true);
    try {
      await _requestPermissions();

      final contact = await _getEmergencyContact();
      if (contact == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No emergency contact found!")),
        );
        return;
      }

      final position = await _getCurrentLocation();
      final message =
          "⚠️ I'm in emergency! My location: https://www.google.com/maps?q=${position.latitude},${position.longitude}";

      // Send SMS & WhatsApp
      await _sendSMS(contact, message);
      await _sendWhatsApp(contact, message);

      // ✅ Check if emergency contact is registered
      final targetUser = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('phone_number', contact)
          .maybeSingle();

      if (targetUser != null) {
        final targetId = targetUser['id'];
        logger.i("Emergency contact $contact is registered with ID $targetId");

        // ✅ Insert in-app alert in Supabase
        await Supabase.instance.client.from('alerts').insert({
          'sender_id': Supabase.instance.client.auth.currentUser?.id,
          'receiver_id': targetId,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
          'seen': false,
        });

        // Optional: show immediate popup in-app
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("In-app alert sent to contact!")),
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("SOS sent successfully!")));
    } catch (e) {
      logger.e("SOS failed: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("SOS failed: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _makeCall(String number) async {
    final Uri url = Uri(scheme: "tel", path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw "Could not launch $number";
    }
  }

  Widget _buildActionButton(IconData icon, String label, String number) {
    return Column(
      children: [
        InkWell(
          onTap: () => _makeCall(number),
          child: CircleAvatar(
            radius: 35,
            backgroundColor: const Color.fromRGBO(255, 0, 0, 1),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
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
          Center(
            child: GestureDetector(
              onTap: _isSending ? null : _handleSOS,
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: _isSending
                      ? Colors.grey
                      : const Color.fromRGBO(255, 0, 0, 1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x99FF0000),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: _isSending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
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
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(Icons.local_police, "Police", policeNumber),
              _buildActionButton(
                Icons.local_hospital,
                "Ambulance",
                ambulanceNumber,
              ),
              _buildActionButton(
                Icons.local_fire_department,
                "Fire",
                fireNumber,
              ),
            ],
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            onPressed: () {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Location sharing not implemented yet"),
                ),
              );
            },
            icon: const Icon(Icons.location_on, color: Colors.white),
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
}
