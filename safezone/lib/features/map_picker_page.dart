import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
          target: pickedLocation ?? const LatLng(20.5937, 78.9629), // Default India
          zoom: 5,
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
