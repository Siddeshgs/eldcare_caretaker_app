import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> alerts = [];

  @override
  void initState() {
    super.initState();

    // Listen to smartstick node in Firebase
    DatabaseReference ref = FirebaseDatabase.instance.ref("smartstick");

    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final parsed = Map<String, dynamic>.from(data as Map);

        final double accelZ = (parsed['accel_z'] ?? 0).toDouble();
        final double distance = (parsed['distance'] ?? 100).toDouble();
        final double lat = (parsed['latitude'] ?? 0).toDouble();
        final double lng = (parsed['longitude'] ?? 0).toDouble();

        // Fall detection: accel_z below threshold
        if (accelZ < -5) {
          alerts.add({
            "type": "Fall Detected",
            "time": DateTime.now().toString(),
            "location": "$lat, $lng",
            "maps_link": "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
          });
        }

        // Object detection: distance below threshold
        if (distance < 20) {
          alerts.add({
            "type": "Object Detected",
            "time": DateTime.now().toString(),
            "location": "$lat, $lng",
            "maps_link": "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
          });
        }

        setState(() {
          alerts = List.from(alerts); // trigger rebuild
        });

        print("Alerts updated: $alerts");
      }
    });
  }

  Future<void> _openInGoogleMaps(String link) async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Maps")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alerts")),
      body: alerts.isEmpty
          ? const Center(child: Text("No alerts yet"))
          : ListView.builder(
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: Text(alert['type'] ?? "Unknown Alert"),
              subtitle: Text(
                "Time: ${alert['time'] ?? ''}\n"
                    "Location: ${alert['location'] ?? ''}",
              ),
              trailing: IconButton(
                icon: const Icon(Icons.map, color: Colors.blue),
                onPressed: () {
                  final link = alert['maps_link'];
                  if (link != null) {
                    _openInGoogleMaps(link);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
