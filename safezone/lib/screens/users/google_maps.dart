import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:safezone/constants/app_colors.dart';
import 'package:safezone/services/user_services.dart';

class SafetyMapPage extends StatefulWidget {
  const SafetyMapPage({super.key});

  @override
  State<SafetyMapPage> createState() => _SafetyMapPageState();
}

class _SafetyMapPageState extends State<SafetyMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final _userService = UserService();

  Set<Marker> _markers = {};
  bool _isLoading = true;

  static const LatLng _defaultLocation = LatLng(12.9141, 74.8560); // Mangaluru default

  @override
  void initState() {
    super.initState();
    _loadApprovedComplaints();
  }

  Future<void> _loadApprovedComplaints() async {
    setState(() => _isLoading = true);
    final reports = await _userService.fetchApprovedComplaints();

    final Set<Marker> newMarkers = {};
    for (var r in reports) {
      final lat = (r['latitude'] as num?)?.toDouble();
      final lng = (r['longitude'] as num?)?.toDouble();
      final id = r['id']?.toString() ?? UniqueKey().toString();
      final category = (r['category'] ?? 'Hazard').toString();
      final desc = (r['description'] ?? '').toString();

      if (lat != null && lng != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(id),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
            infoWindow: InfoWindow(
              title: "⚠️ $category Incident",
              snippet: desc,
            ),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _markers = newMarkers;
      _isLoading = false;
    });

    if (newMarkers.isNotEmpty) {
      final first = newMarkers.first.position;
      final ctrl = await _controller.future;
      ctrl.animateCamera(CameraUpdate.newLatLngZoom(first, 13));
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      final pos = await _userService.getCurrentLocation();
      final ctrl = await _controller.future;
      ctrl.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location error: $e")),
      );
    }
  }

  Future<void> _searchAddress() async {
    final textController = TextEditingController();
    final address = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Search Location",
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: TextField(
          controller: textController,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: "Enter neighborhood, street, or city",
            hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, textController.text.trim()),
            child: Text("Search", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );

    if (address != null && address.isNotEmpty) {
      try {
        final locations = await geocoding.locationFromAddress(address);
        if (locations.isNotEmpty) {
          final first = locations.first;
          final ctrl = await _controller.future;
          ctrl.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(first.latitude, first.longitude), 14),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Address not found: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultLocation,
              zoom: 12,
            ),
            onMapCreated: (ctrl) => _controller.complete(ctrl),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Search & Filter Floating Card
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _searchAddress,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              "Search safe areas or spots...",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
                      onPressed: _loadApprovedComplaints,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator badge
          if (_isLoading)
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Loading safety spots...",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          // Floating Action Buttons (My Location & Stats)
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'my_loc',
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  elevation: 4,
                  onPressed: _goToMyLocation,
                  child: const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "${_markers.length} Danger Spots",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
