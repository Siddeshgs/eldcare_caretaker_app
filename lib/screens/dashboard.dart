import 'package:flutter/material.dart';
import 'medicines.dart';
import 'prescriptions.dart';
import 'location.dart';
import 'iot_data.dart';
import 'alerts.dart';
import 'appointments.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const DashboardScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Caretaker Dashboard"),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(context, "Medicines", Icons.medication, const MedicinesScreen()),
            _buildCard(context, "Prescriptions", Icons.description, const PrescriptionsScreen()),
            _buildCard(context, "IoT Data", Icons.sensors, const IoTDataScreen()),
            _buildCard(context, "Appointments", Icons.calendar_today, const AppointmentsScreen()),
            _buildCard(context, "Location", Icons.location_on, const LocationScreen()),
            _buildCard(context, "Alerts", Icons.warning, const AlertsScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Widget screen) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      ),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
