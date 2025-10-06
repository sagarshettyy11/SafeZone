import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:developer' as developer;

// Map Picker Page
class MapPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerPage({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? pickedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      pickedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Location"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: pickedLocation == null
                ? null
                : () {
                    Navigator.of(context).pop(pickedLocation);
                  },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: pickedLocation ?? const LatLng(20.5937, 78.9629),
          zoom: pickedLocation != null ? 15 : 5,
        ),
        onTap: (latLng) {
          setState(() {
            pickedLocation = latLng;
          });
        },
        markers: pickedLocation == null
            ? {}
            : {
                Marker(
                  markerId: const MarkerId('picked'),
                  position: pickedLocation!,
                )
              },
      ),
    );
  }
}

// Complaint Page
class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  ComplaintPageState createState() => ComplaintPageState();
}

class ComplaintPageState extends State<ComplaintPage> {
  String selectedCategory = "";
  double urgency = 2;
  TextEditingController descriptionController = TextEditingController();
  TextEditingController proofLinkController = TextEditingController();

  double? latitude;
  double? longitude;
  String? mediaPath;

  final List<Map<String, dynamic>> categories = [
    {"icon": Icons.warning, "label": "Crime"},
    {"icon": Icons.directions_car, "label": "Accident"},
    {"icon": Icons.fireplace, "label": "Fire"},
    {"icon": Icons.medical_services, "label": "Medical"},
    {"icon": Icons.cloud, "label": "Hazard"},
    {"icon": Icons.more_horiz, "label": "Other"},
  ];

  bool _loading = false;

  // Pick media from gallery
  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (!mounted) return;

    if (pickedFile != null) {
      setState(() {
        mediaPath = pickedFile.path;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Media selected successfully")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No media selected")),
        );
      }
    }
  }

  // Upload image to Supabase Storage (complaint_media bucket)
  Future<String?> _uploadImageToSupabase(String filePath) async {
    try {
      final file = File(filePath);
      final fileName =
          'complaints/${DateTime.now().millisecondsSinceEpoch}_${file.path.split("/").last}';

      await Supabase.instance.client.storage
          .from('complaint_media') // updated bucket name
          .uploadBinary(fileName, await file.readAsBytes());

      final publicUrl = Supabase.instance.client.storage
          .from('complaint_media')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error uploading image: $e")),
        );
      }
      return null;
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled.")),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied.")),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Location permissions are permanently denied.")),
        );
      }
      return;
    }

    try {
      final locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
      );

      final position =
          await Geolocator.getCurrentPosition(locationSettings: locationSettings);

      if (!mounted) return;

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Using current location")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to get location: $e")),
        );
      }
    }
  }

  // Pick location from map
  Future<void> _pickLocationOnMap() async {
    if (!mounted) return;

    final selected = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialLat: latitude,
          initialLng: longitude,
        ),
      ),
    );

    if (!mounted) return;

    if (selected != null) {
      setState(() {
        latitude = selected.latitude;
        longitude = selected.longitude;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location selected from map")),
        );
      }
    }
  }

  // Submit complaint
  Future<void> _submitComplaint() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to submit.")),
      );
      return;
    }

    if (selectedCategory.isEmpty || descriptionController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields.")),
      );
      return;
    }

    if (latitude == null || longitude == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String? uploadedUrl;
      if (mediaPath != null) {
        uploadedUrl = await _uploadImageToSupabase(mediaPath!);
      }

      final response = await Supabase.instance.client.from('complaints').insert({
        'user_id': user.id,
        'category': selectedCategory,
        'description': descriptionController.text,
        'urgency': urgency.toInt(),
        'latitude': latitude,
        'longitude': longitude,
        'media_url': uploadedUrl,
        'proof_link': proofLinkController.text,
        'status': 'pending',
      });

      developer.log("Insert response: $response");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complaint submitted successfully!")),
      );

      setState(() {
        selectedCategory = "";
        urgency = 2;
        descriptionController.clear();
        proofLinkController.clear();
        mediaPath = null;
        latitude = null;
        longitude = null;
      });
    } catch (e, st) {
      developer.log("Error inserting complaint", error: e, stackTrace: st);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit complaint: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Report a Complaint",
          style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Help keep your community safe by reporting issues.",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),

            // Category selection
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category["label"];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category["label"];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.red : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(category["icon"], size: 30, color: Colors.black),
                        const SizedBox(height: 8),
                        Text(
                          category["label"],
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Location section
            Text(
              "Location",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text("Current location"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _pickLocationOnMap,
                  icon: const Icon(Icons.map),
                  label: const Text("Pick location"),
                ),
              ],
            ),
            if (latitude != null && longitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Selected Location: ($latitude, $longitude)",
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            const SizedBox(height: 20),

            // Description
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: "Describe what happened..",
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            // Media upload
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Add photo/video (optional)",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                ElevatedButton(onPressed: _pickMedia, child: const Text("Add")),
              ],
            ),
            if (mediaPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Selected: $mediaPath",
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            const SizedBox(height: 10),

            // Proof link
            TextField(
              controller: proofLinkController,
              decoration: const InputDecoration(
                  labelText: "Proof Link (optional)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            // Urgency slider
            Text(
              "Urgency",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: urgency,
              min: 1,
              max: 3,
              divisions: 2,
              label: urgency == 1
                  ? "Low"
                  : urgency == 2
                      ? "Medium"
                      : "High",
              onChanged: (val) => setState(() => urgency = val),
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4DE8), // Change to your desired color
                  foregroundColor: Colors.white, // Text color
                  padding: const EdgeInsets.symmetric(vertical: 16), // Optional
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Color(0xFF1E4DE8))
                    : Text("Submit Complaint"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
