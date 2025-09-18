import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SafeDangerMapPage extends StatefulWidget {
  const SafeDangerMapPage({super.key});

  @override
  State<SafeDangerMapPage> createState() => _SafeDangerMapPageState();
}

class _SafeDangerMapPageState extends State<SafeDangerMapPage> {
  late GoogleMapController _mapController;

  final Set<Polygon> _polygons = {
    // ✅ Safe Zone Polygon
    Polygon(
      polygonId: const PolygonId('safe-zone'),
      points: [
        const LatLng(12.9716, 77.5946),
        const LatLng(12.9720, 77.5960),
        const LatLng(12.9730, 77.5955),
        const LatLng(12.9725, 77.5935),
      ],
      fillColor: Colors.green.withOpacity(0.3),
      strokeColor: Colors.green,
      strokeWidth: 2,
    ),

    // ✅ Danger Zone Polygon
    Polygon(
      polygonId: const PolygonId('danger-zone'),
      points: [
        const LatLng(12.9745, 77.5970),
        const LatLng(12.9750, 77.5980),
        const LatLng(12.9760, 77.5975),
        const LatLng(12.9755, 77.5965),
      ],
      fillColor: Colors.red.withOpacity(0.3),
      strokeColor: Colors.red,
      strokeWidth: 2,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safe & Danger Areas')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(12.9716, 77.5946),
          zoom: 15,
        ),
        polygons: _polygons,
        onMapCreated: (controller) => _mapController = controller,
      ),
    );
  }
}
