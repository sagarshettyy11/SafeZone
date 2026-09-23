import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safezone/constants/app_colors.dart';
import 'package:safezone/services/auth_services.dart';
import 'package:safezone/services/user_services.dart';
import 'package:safezone/widgets/auth_widgets.dart';
import 'package:safezone/widgets/user_widgets.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final _userService = UserService();
  final _authService = AuthService();

  final _descriptionController = TextEditingController();
  final _proofLinkController = TextEditingController();

  String _selectedCategory = "Crime";
  double _urgency = 2; // 1 to 4

  double? _latitude;
  double? _longitude;
  XFile? _selectedMedia;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {"icon": Icons.gavel_rounded, "label": "Crime"},
    {"icon": Icons.car_crash_rounded, "label": "Accident"},
    {"icon": Icons.local_fire_department_rounded, "label": "Fire"},
    {"icon": Icons.medical_services_rounded, "label": "Medical"},
    {"icon": Icons.warning_rounded, "label": "Hazard"},
    {"icon": Icons.more_horiz_rounded, "label": "Other"},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _proofLinkController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await _userService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("GPS location acquired successfully!"),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Location error: $e"),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _pickLocationOnMap() async {
    final LatLng? picked = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerModal(
          initialLat: _latitude,
          initialLng: _longitude,
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _latitude = picked.latitude;
        _longitude = picked.longitude;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null && mounted) {
      setState(() => _selectedMedia = file);
    }
  }

  Future<void> _handleSubmit() async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to file a complaint.")),
      );
      return;
    }

    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a description of the incident.")),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please set a location using GPS or the map picker.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _userService.submitComplaint(
      userId: uid,
      category: _selectedCategory,
      description: desc,
      urgency: _urgency.toInt(),
      latitude: _latitude!,
      longitude: _longitude!,
      proofLink: _proofLinkController.text.trim(),
      mediaFile: _selectedMedia,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _descriptionController.clear();
      _proofLinkController.clear();
      setState(() {
        _selectedMedia = null;
        _latitude = null;
        _longitude = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incident reported successfully! It is pending review."),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to submit report. Please try again."),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "File Incident Report",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Report safety hazards, crimes, or emergencies for immediate review",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Category Picker
          Text(
            "Category",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          CategoryChipSelector(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onSelect: (cat) => setState(() => _selectedCategory = cat),
          ),

          const SizedBox(height: 24),

          // Urgency Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Urgency Level",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _urgency >= 3 ? AppColors.dangerLight : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _urgency == 1
                      ? "Low"
                      : _urgency == 2
                          ? "Medium"
                          : _urgency == 3
                              ? "High"
                              : "Critical",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _urgency >= 3 ? AppColors.danger : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _urgency,
            min: 1,
            max: 4,
            divisions: 3,
            activeColor: _urgency >= 3 ? AppColors.danger : AppColors.primary,
            onChanged: (val) => setState(() => _urgency = val),
          ),

          const SizedBox(height: 16),

          // Location Selector
          Text(
            "Location",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _latitude != null ? Icons.check_circle_rounded : Icons.location_off_rounded,
                      color: _latitude != null ? AppColors.success : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _latitude != null
                            ? "Lat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}"
                            : "No location attached",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.my_location_rounded, size: 16),
                        label: Text(
                          "GPS Location",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        onPressed: _getCurrentLocation,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderDark),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.map_rounded, size: 16),
                        label: Text(
                          "Pick on Map",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        onPressed: _pickLocationOnMap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Incident Description
          Text(
            "Incident Description",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: "Describe what happened, any persons or vehicles involved, and exact landmark details...",
              hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Photo/Media Attachment
          Text(
            "Media Attachment",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (_selectedMedia == null)
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderDark, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.add_photo_alternate_rounded, size: 36, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text(
                      "Upload Photo or Video Evidence",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "JPG, PNG, MP4 up to 25MB",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedMedia!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    onPressed: () => setState(() => _selectedMedia = null),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Submit Button
          AuthButton(
            text: "Submit Incident Report",
            onPressed: _handleSubmit,
            isLoading: _isLoading,
            icon: Icons.send_rounded,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Map Picker Screen modal
class MapPickerModal extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerModal({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerModal> createState() => _MapPickerModalState();
}

class _MapPickerModalState extends State<MapPickerModal> {
  LatLng? _pickedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _pickedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pin Incident Location",
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _pickedLocation == null
                ? null
                : () => Navigator.pop(context, _pickedLocation),
            child: Text(
              "Confirm",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: _pickedLocation != null ? AppColors.primary : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _pickedLocation ?? const LatLng(12.9141, 74.8560), // Mangaluru / default
          zoom: _pickedLocation != null ? 15 : 12,
        ),
        onTap: (pos) => setState(() => _pickedLocation = pos),
        markers: _pickedLocation == null
            ? {}
            : {
                Marker(
                  markerId: const MarkerId('incident_pin'),
                  position: _pickedLocation!,
                ),
              },
      ),
    );
  }
}
