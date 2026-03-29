import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  LatLng? elderLocation;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();

    DatabaseReference ref = FirebaseDatabase.instance.ref("smartstick");

    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final parsed = Map<String, dynamic>.from(data as Map);

        final num latRaw = parsed['latitude'] ?? 0;
        final num lngRaw = parsed['longitude'] ?? 0;

        final newLocation = LatLng(latRaw.toDouble(), lngRaw.toDouble());

        setState(() {
          elderLocation = newLocation;
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(newLocation),
          );
        }

        print("Updated location: ${newLocation.latitude}, ${newLocation.longitude}");
      }
    });
  }

  Future<void> _openInGoogleMaps() async {
    if (elderLocation != null) {
      final url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${elderLocation!.latitude},${elderLocation!.longitude}",
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Google Maps")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Elderly Location")),
      body: elderLocation == null
          ? const Center(child: Text("Waiting for location data..."))
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: elderLocation!,
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId("elder"),
                position: elderLocation!,
                infoWindow: const InfoWindow(title: "Elder's Location"),
              ),
            },
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _openInGoogleMaps,
              child: const Icon(Icons.map),
            ),
          ),
        ],
      ),
    );
  }
}
