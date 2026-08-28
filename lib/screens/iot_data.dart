import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class IoTDataScreen extends StatefulWidget {
  const IoTDataScreen({super.key});

  @override
  State<IoTDataScreen> createState() => _IoTDataScreenState();
}

class _IoTDataScreenState extends State<IoTDataScreen> {
  Map<String, dynamic>? latestData;

  @override
  void initState() {
    super.initState();
    listenToSensorData();
  }

  // Listen to Firebase
  void listenToSensorData() {
    DatabaseReference ref = FirebaseDatabase.instance.ref("smartstick");

    ref.onChildAdded.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final parsed = Map<String, dynamic>.from(data as Map);
        setState(() {
          latestData = parsed;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Stick Data")),
      body: latestData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Distance: ${latestData!['distance']} cm"),
            Text("Accel X: ${latestData!['accel_x']}"),
            Text("Accel Y: ${latestData!['accel_y']}"),
            Text("Accel Z: ${latestData!['accel_z']}"),
            Text("IR Value: ${latestData!['ir_value']}"),
            Text("Latitude: ${latestData!['latitude']}"),
            Text("Longitude: ${latestData!['longitude']}"),
            Text("Date: ${latestData!['day']}-${latestData!['month']}-${latestData!['year']}"),
            Text("Time: ${latestData!['hour']}:${latestData!['minute']}:${latestData!['second']}"),
          ],
        ),
      ),
    );
  }
}
