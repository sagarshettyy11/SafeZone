import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:another_telephony/telephony.dart';
import 'package:http/http.dart' as http;

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String fcmServerKey = "YOUR_FCM_SERVER_KEY_HERE";

  /// ----------------------------------------
  /// User Profile Methods
  /// ----------------------------------------

  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, display_name, phone, emergency_contact, profile_image_url')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      final imagePath = response['profile_image_url'] as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        if (imagePath.startsWith('http')) {
          response['profile_url'] = imagePath;
        } else {
          final imageUrl = _supabase.storage
              .from('profile-images')
              .getPublicUrl(imagePath);
          response['profile_url'] = imageUrl;
        }
      } else {
        response['profile_url'] = null;
      }

      return response;
    } catch (e) {
      debugPrint('UserService.fetchUserProfile error: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile({
    required String userId,
    required String displayName,
    required String phone,
    required String emergencyContact,
    String? profileImageUrl,
  }) async {
    try {
      final data = <String, dynamic>{
        'id': userId,
        'display_name': displayName.trim(),
        'phone': phone.trim(),
        'emergency_contact': emergencyContact.trim(),
      };
      if (profileImageUrl != null) data['profile_image_url'] = profileImageUrl;

      await _supabase.from('profiles').upsert(data);
      return true;
    } catch (e) {
      debugPrint('UserService.updateUserProfile error: $e');
      return false;
    }
  }

  Future<String?> uploadProfileImage(Uint8List bytes, String userId) async {
    try {
      final fileName = "${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg";

      await _supabase.storage.from('profile-images').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      return _supabase.storage.from('profile-images').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('UserService.uploadProfileImage error: $e');
      return null;
    }
  }

  Future<void> saveFCMToken(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', userId);
      }
    } catch (e) {
      debugPrint('UserService.saveFCMToken error: $e');
    }
  }

  /// ----------------------------------------
  /// Complaints & Incident Reporting
  /// ----------------------------------------

  Future<String?> uploadComplaintMedia(XFile file) async {
    try {
      final fileName =
          'complaints/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final bytes = await file.readAsBytes();

      await _supabase.storage
          .from('complaint_media')
          .uploadBinary(fileName, bytes);

      return _supabase.storage.from('complaint_media').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('UserService.uploadComplaintMedia error: $e');
      return null;
    }
  }

  Future<bool> submitComplaint({
    required String userId,
    required String category,
    required String description,
    required int urgency,
    required double latitude,
    required double longitude,
    String? proofLink,
    XFile? mediaFile,
  }) async {
    try {
      String? mediaUrl;
      if (mediaFile != null) {
        mediaUrl = await uploadComplaintMedia(mediaFile);
      }

      await _supabase.from('complaints').insert({
        'user_id': userId,
        'category': category,
        'description': description.trim(),
        'urgency': urgency,
        'latitude': latitude,
        'longitude': longitude,
        'media_url': mediaUrl,
        'proof_link': proofLink?.trim() ?? '',
        'status': 'pending',
      });

      return true;
    } catch (e) {
      debugPrint('UserService.submitComplaint error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserComplaints(String userId) async {
    try {
      final response = await _supabase
          .from('complaints')
          .select()
          .eq('user_id', userId)
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('UserService.fetchUserComplaints error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchApprovedComplaints() async {
    try {
      final response = await _supabase
          .from('complaints')
          .select()
          .eq('status', 'approved')
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('UserService.fetchApprovedComplaints error: $e');
      return [];
    }
  }

  /// ----------------------------------------
  /// Emergency & SOS Flow
  /// ----------------------------------------

  Future<Position> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw "Location services are disabled on this device.";
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw "Location permission was denied.";
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw "Location permissions are permanently denied. Please enable them in settings.";
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<String?> fetchEmergencyContact(String userId) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('emergency_contact')
          .eq('id', userId)
          .maybeSingle();

      return profile?['emergency_contact'] as String?;
    } catch (e) {
      debugPrint('UserService.fetchEmergencyContact error: $e');
      return null;
    }
  }

  Future<void> sendSMS(String number, String message) async {
    if (kIsWeb) {
      final smsUri = Uri.parse("sms:$number?body=${Uri.encodeComponent(message)}");
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
      return;
    }

    try {
      await Telephony.instance.sendSms(
        to: number,
        message: message,
        isMultipart: true,
      );
    } catch (e) {
      debugPrint("UserService.sendSMS error: $e");
    }
  }

  Future<void> sendWhatsApp(String number, String message) async {
    final formattedNumber = number.startsWith("+91") ? number : "+91$number";
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
      }
    }
  }

  Future<void> sendFcmNotification(String targetToken, String message) async {
    try {
      final body = {
        "to": targetToken,
        "notification": {
          "title": "🚨 SafeZone Emergency Alert",
          "body": message,
          "sound": "default",
        },
        "data": {"type": "sos_alert", "message": message},
      };

      await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "key=$fcmServerKey",
        },
        body: jsonEncode(body),
      );
    } catch (e) {
      debugPrint("UserService.sendFcmNotification error: $e");
    }
  }

  Future<void> recordAndUploadVideo15s({
    required CameraController cameraController,
    required double lat,
    required double lng,
  }) async {
    if (kIsWeb) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    String userName = user.email ?? user.id;
    try {
      final prof = await _supabase
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();
      if (prof != null && (prof['display_name'] as String?)?.isNotEmpty == true) {
        userName = prof['display_name'];
      }
    } catch (_) {}

    final tmpDir = await getTemporaryDirectory();
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.mp4";
    final tmpPath = p.join(tmpDir.path, fileName);

    await cameraController.startVideoRecording();
    await Future.delayed(const Duration(seconds: 15));
    final XFile recorded = await cameraController.stopVideoRecording();

    final File videoFile = await File(recorded.path).copy(tmpPath);
    final storagePath = 'emergency/${user.id}/$fileName';

    await _supabase.storage.from('emergency').upload(storagePath, videoFile);

    await _supabase.from('emergency_details').insert({
      'user_id': user.id,
      'user_name': userName,
      'latitude': lat,
      'longitude': lng,
      'video_path': storagePath,
    });
  }

  Future<void> logAlertRecord({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    try {
      await _supabase.from('alerts').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'seen': false,
      });
    } catch (e) {
      debugPrint("UserService.logAlertRecord error: $e");
    }
  }
}
