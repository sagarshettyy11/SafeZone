import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safezone/constants/app_colors.dart';
import 'package:safezone/services/auth_services.dart';
import 'package:safezone/services/user_services.dart';
import 'package:safezone/widgets/auth_widgets.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyController = TextEditingController();

  final _userService = UserService();
  final _authService = AuthService();

  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _submitDetails() async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User session not found. Please log in.")),
      );
      return;
    }

    final name = _displayNameController.text.trim();
    final phone = _phoneController.text.trim();
    final emergency = _emergencyController.text.trim();

    if (name.isEmpty || phone.isEmpty || emergency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all mandatory fields (Name, Phone, Emergency Contact).")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_imageBytes != null) {
        imageUrl = await _userService.uploadProfileImage(_imageBytes!, uid);
      }

      final success = await _userService.updateUserProfile(
        userId: uid,
        displayName: name,
        phone: phone,
        emergencyContact: emergency,
        profileImageUrl: imageUrl,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile configured successfully! Welcome to SafeZone."),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to save profile. Please try again."),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          "Complete Profile",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Personal Safety Profile",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Your information ensures rapid emergency response & guardian alerts",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Profile Avatar Picker
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                      child: _imageBytes == null
                          ? const Icon(Icons.person_rounded, size: 50, color: AppColors.primary)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.surface),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              AuthTextField(
                controller: _displayNameController,
                label: "Full Name *",
                hint: "Your full name",
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 18),

              AuthTextField(
                controller: _phoneController,
                label: "Phone Number *",
                hint: "+91 98765 43210",
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),

              AuthTextField(
                controller: _emergencyController,
                label: "Emergency Contact Phone *",
                hint: "+91 98765 43210 (Guardian/Family)",
                prefixIcon: Icons.contact_phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 28),

              AuthButton(
                text: "Complete Setup",
                onPressed: _submitDetails,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
