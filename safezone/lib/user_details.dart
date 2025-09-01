import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safezone/features/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final displayNameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final emergencyController = TextEditingController();
  final addressController = TextEditingController();
  final bioController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  // Pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _submitDetails() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // Upload image to Supabase Storage
      if (_selectedImage != null) {
        final fileName =
            "${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg";

        // Upload file
        await Supabase.instance.client.storage
            .from('profile-images')
            .upload(fileName, _selectedImage!);

        // Get public URL (direct String in supabase_flutter v2.x)
        imageUrl = Supabase.instance.client.storage
            .from('profile-images')
            .getPublicUrl(fileName);
      }

      // Save details into profiles table
      final response = await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'display_name': displayNameController.text.trim(),
        'username': usernameController.text.trim(),
        'phone': phoneController.text.trim(),
        'emergency_contact': emergencyController.text.trim(),
        'address': addressController.text.trim(),
        'user_bio': bioController.text.trim(),
        if (imageUrl != null) 'profile_image_url': imageUrl,
      }).select();

      debugPrint("Supabase response: $response");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Details saved successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (error) {
      debugPrint("Supabase error: $error");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving details: $error")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((0.18 * 255).round()),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Personal Details",
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E4DE8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please enter your information to ensure your safety",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Image Picker
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE8EAFA),
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : null,
                    child: _selectedImage == null
                        ? const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                _buildTextField("Display Name", displayNameController),
                const SizedBox(height: 18),
                _buildTextField("Username", usernameController),
                const SizedBox(height: 18),
                _buildTextField(
                  "Phone Number",
                  phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 18),
                _buildTextField(
                  "Emergency Contact",
                  emergencyController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 18),
                _buildTextField("Address", addressController, maxLines: 2),
                const SizedBox(height: 18),
                _buildTextField("Bio", bioController, maxLines: 3),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E4DE8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isLoading ? null : _submitDetails,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Continue",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
        filled: true,
        fillColor: const Color(0xFFE8EAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }
}
