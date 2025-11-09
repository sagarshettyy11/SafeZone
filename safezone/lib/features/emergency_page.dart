import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:another_telephony/telephony.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';

// NEW
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

final telephony = Telephony.instance;
final logger = Logger();

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  bool _isSending = false;

  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  final String policeNumber = "100";
  final String ambulanceNumber = "108";
  final String fireNumber = "101";

  static const String fcmServerKey = "YOUR_FCM_SERVER_KEY_HERE";

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      final back = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      logger.i("Camera initialized");
      setState(() {}); // so UI can react if you add a preview later
    } catch (e) {
      logger.e("Camera init failed: $e");
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.sms,
      Permission.phone,
      Permission.camera,
      Permission.microphone,
      // Storage only needed on some Android versions:
      Permission.storage,
    ].request();
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

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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

    final whatsappUri = Uri.parse(
      "whatsapp://send?phone=$formattedNumber&text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      final webUri = Uri.parse(
        "https://wa.me/$formattedNumber?text=${Uri.encodeFull(message)}",
      );
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        throw "Could not open WhatsApp";
      }
    }
  }

  Future<void> _sendFcmNotification(String targetToken, String message) async {
    logger.i("Sending FCM to $targetToken");

    final body = {
      "to": targetToken,
      "notification": {
        "title": "🚨 Emergency Alert",
        "body": message,
        "sound": "default",
      },
      "data": {"type": "sos_alert", "message": message},
    };

    final response = await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "key=$fcmServerKey",
      },
      body: jsonEncode(body),
    );

    logger.i("FCM Response: ${response.statusCode} ${response.body}");
  }

  /// --- NEW: Record a 15s video, upload to Supabase Storage, insert DB row ---
  Future<void> _recordAndUploadVideo15s({
    required double lat,
    required double lng,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw "Not logged in";

    // Fallback user_name: read from profiles.name if you have it; else email/UID
    String userName = user.email ?? user.id;
    try {
      final prof = await supabase
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();
      if (prof != null && (prof['name'] as String?)?.isNotEmpty == true) {
        userName = prof['name'];
      }
    } catch (_) {}

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _initCamera();
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        throw "Camera not available";
      }
    }

    // Prepare a temp file path
    final tmpDir = await getTemporaryDirectory();
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.mp4";
    final tmpPath = p.join(tmpDir.path, fileName);

    // Start recording
    await _cameraController!.startVideoRecording();
    logger.i("Recording started");

    // Record for ~15 seconds
    await Future.delayed(const Duration(seconds: 15));

    // Stop recording & save file
    final XFile recorded = await _cameraController!.stopVideoRecording();
    logger.i("Recording stopped: ${recorded.path}");

    // Some Android devices save to a content URI path. Copy to tmp if needed.
    final File videoFile = await File(
      recorded.path,
    ).copy(tmpPath); // ensure we have a File

    // Upload to Storage
    final storagePath = 'emergency/${user.id}/$fileName';
    await supabase.storage.from('emergency').upload(storagePath, videoFile);
    logger.i("Uploaded to storage: $storagePath");

    // Insert DB row
    await supabase.from('emergency_details').insert({
      'user_id': user.id,
      'user_name': userName,
      'latitude': lat,
      'longitude': lng,
      'video_path': storagePath, // you renamed from video_link earlier
    });

    logger.i("DB row inserted for emergency_details");
  }

  // Main SOS
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

      // 1) Record + upload + insert row
      await _recordAndUploadVideo15s(
        lat: position.latitude,
        lng: position.longitude,
      );

      // 2) Notify contacts as you already do
      final message =
          "⚠️ I'm in emergency! My location: https://www.google.com/maps?q=${position.latitude},${position.longitude}";

      await _sendSMS(contact, message);
      await _sendWhatsApp(contact, message);

      // Check if contact is a registered user and send FCM
      final userQuery = await Supabase.instance.client
          .from('profiles')
          .select('id, fcm_token')
          .eq('phone', contact)
          .maybeSingle();

      if (userQuery != null) {
        final String targetId = userQuery['id'];
        final String? targetToken = userQuery['fcm_token'];

        await Supabase.instance.client.from('alerts').insert({
          'sender_id': Supabase.instance.client.auth.currentUser?.id,
          'receiver_id': targetId,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
          'seen': false,
        });

        if (targetToken != null && targetToken.isNotEmpty) {
          await _sendFcmNotification(targetToken, message);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Push notification sent!")),
            );
          }
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
