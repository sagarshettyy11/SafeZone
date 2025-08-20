import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:http/http.dart' as http;

const String googleApiKey = "YOUR_API_KEY"; // replace with your Google API key

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  static const LatLng _start = LatLng(28.6139, 77.2090); // New Delhi default

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  LatLng? origin;
  LatLng? destination;

  // ----------------------------
  // My location
  // ----------------------------
  Future<void> _goToMyLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Location permission denied",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    final latLng = LatLng(pos.latitude, pos.longitude);
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
    if (!mounted) return;
    setState(() {
      markers.add(
        Marker(
          markerId: const MarkerId("me"),
          position: latLng,
          infoWindow: const InfoWindow(title: "My Location"),
        ),
      );
    });
  }

  // ----------------------------
  // Simple autocomplete search (API call)
  // ----------------------------
  Future<void> _searchPlaceDialog() async {
    final inputController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Search place",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: inputController,
          decoration: InputDecoration(
            hintText: "Enter city or address",
            hintStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, inputController.text),
            child: Text(
              "Search",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _searchPlaces(result);
    }
  }

  Future<void> _searchPlaces(String input) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/textsearch/json?query=$input&key=$googleApiKey",
    );
    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data["results"] != null && data["results"].isNotEmpty) {
      final place = data["results"][0];
      final lat = place["geometry"]["location"]["lat"];
      final lng = place["geometry"]["location"]["lng"];
      final name = place["name"];
      final latLng = LatLng(lat, lng);

      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));

      if (!mounted) return;
      setState(() {
        markers.add(
          Marker(
            markerId: MarkerId(place["place_id"]),
            position: latLng,
            infoWindow: InfoWindow(title: name),
          ),
        );
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No results found",
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }
  }

  // ----------------------------
  // Reverse geocode
  // ----------------------------
  Future<void> _reverseGeocode(LatLng pos) async {
    final placemarks = await geocoding.placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${place.street}, ${place.locality}")),
      );
    }
  }

  // ----------------------------
  // Route via Directions API
  // ----------------------------
  Future<void> _createRoute() async {
    if (origin == null || destination == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Select origin and destination",
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
      return;
    }

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/directions/json?origin=${origin!.latitude},${origin!.longitude}&destination=${destination!.latitude},${destination!.longitude}&mode=driving&key=$googleApiKey",
    );
    final res = await http.get(url);
    final data = json.decode(res.body);

    if (data["routes"].isNotEmpty) {
      final points = data["routes"][0]["overview_polyline"]["points"];
      final line = _decodePolyline(points);
      if (!mounted) return;
      setState(() {
        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            points: line,
            width: 5,
            color: Colors.blue,
          ),
        );
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No route found",
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // ----------------------------
  // Build UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Safety Map",
          style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _searchPlaceDialog,
            icon: Icon(Icons.search, size: 30, color: Colors.black),
          ),
          IconButton(
            onPressed: _goToMyLocation,
            icon: const Icon(Icons.my_location, size: 30, color: Colors.black),
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: (controller) => _controller.complete(controller),
        initialCameraPosition: const CameraPosition(target: _start, zoom: 11),
        markers: markers,
        polylines: polylines,
        onTap: (pos) {
          _addMarker(pos);
          _reverseGeocode(pos);
          if (origin == null) {
            origin = pos;
          } else {
            destination = pos;
            _createRoute();
          }
        },
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
      ),
    );
  }

  Future<void> _addMarker(LatLng position, {String? label}) async {
    if (!mounted) return;
    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(position.toString()),
          position: position,
          infoWindow: InfoWindow(title: label ?? "Dropped Pin"),
        ),
      );
    });
  }
}
