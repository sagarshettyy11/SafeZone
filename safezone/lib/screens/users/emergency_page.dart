import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safezone/constants/app_colors.dart';
import 'package:safezone/services/auth_services.dart';
import 'package:safezone/services/user_services.dart';
import 'package:safezone/widgets/user_widgets.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final _userService = UserService();
  final _authService = AuthService();

  CameraController? _cameraController;

  bool _isSending = false;
  String? _emergencyContact;
  String _statusMessage = "Press the SOS button to alert guardians and emergency services";

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyContact() async {
    final uid = _authService.currentUserId;
    if (uid != null) {
      final contact = await _userService.fetchEmergencyContact(uid);
      if (mounted) {
        setState(() => _emergencyContact = contact);
      }
    }
  }

  Future<void> _triggerSOS() async {
    if (_isSending) return;

    if (_emergencyContact == null || _emergencyContact!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please configure an emergency contact in your profile first!"),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _statusMessage = "Accessing GPS location and preparing alert...";
    });

    try {
      // 1. Permissions
      if (!kIsWeb) {
        await [
          Permission.location,
          Permission.sms,
          Permission.phone,
          Permission.camera,
          Permission.microphone,
        ].request();
      }

      // 2. Location
      final position = await _userService.getCurrentLocation();
      final lat = position.latitude;
      final lng = position.longitude;

      setState(() {
        _statusMessage = "Capturing video evidence (15s) & notifying contact...";
      });

      // 3. Record video on-demand if camera available
      if (!kIsWeb) {
        try {
          final cameras = await availableCameras();
          if (cameras.isNotEmpty) {
            final back = cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => cameras.first,
            );
            _cameraController = CameraController(
              back,
              ResolutionPreset.medium,
              enableAudio: true,
            );
            await _cameraController!.initialize();
            await _userService.recordAndUploadVideo15s(
              cameraController: _cameraController!,
              lat: lat,
              lng: lng,
            );
            await _cameraController?.dispose();
            _cameraController = null;
          }
        } catch (e) {
          debugPrint("Video recording/upload note: $e");
        }
      }

      // 4. Send SMS & WhatsApp with location link
      final alertMsg =
          "EMERGENCY ALERT: I need immediate help! My live location: https://www.google.com/maps?q=$lat,$lng";

      await _userService.sendSMS(_emergencyContact!, alertMsg);
      await _userService.sendWhatsApp(_emergencyContact!, alertMsg);

      // 5. Log alert record
      final uid = _authService.currentUserId;
      if (uid != null) {
        await _userService.logAlertRecord(
          senderId: uid,
          receiverId: _emergencyContact!,
          message: alertMsg,
        );
      }

      if (!mounted) return;
      setState(() {
        _statusMessage = "SOS alert broadcast successfully!";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Emergency alerts sent to contacts and authorities!"),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = "Alert failed: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("SOS error: $e"),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Text(
            "Emergency SOS Center",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "One-tap rapid response for severe danger or distress",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 36),

          // Central SOS Pulse Button
          SOSPulseButton(
            onTap: _triggerSOS,
            isTriggering: _isSending,
          ),

          const SizedBox(height: 32),

          // Live Status Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _isSending
                  ? AppColors.dangerLight
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSending
                    ? AppColors.dangerBorder
                    : AppColors.primaryBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isSending ? Icons.sync_rounded : Icons.info_outline_rounded,
                  color: _isSending ? AppColors.danger : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _isSending ? AppColors.dangerDark : AppColors.primaryDark,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Primary Emergency Contact Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emergency_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Designated Contact",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _emergencyContact ?? "Not configured",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 20),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Direct Dial Helplines
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Immediate Helplines",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const EmergencyDialRow(),
        ],
      ),
    );
  }
}
