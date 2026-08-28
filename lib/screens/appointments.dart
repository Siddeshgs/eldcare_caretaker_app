import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/appointment.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Appointment> appointments = [];
  final FlutterTts flutterTts = FlutterTts();
  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadAppointments();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await notificationsPlugin.initialize(initSettings);

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  }

  String formatTo12Hour(String date, String time) {
    final dateTime = DateTime.parse("$date $time");
    return DateFormat("hh:mm a").format(dateTime);
  }

  Future<void> _loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('appointments') ?? [];

    if (!mounted) return;

    final loadedAppointments =
    data.map((e) => Appointment.fromJson(jsonDecode(e))).toList();

    setState(() {
      appointments = loadedAppointments;
    });

    for (final appt in appointments) {
      await _scheduleReminder(appt);
    }
  }

  Future<void> _saveAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final data = appointments.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('appointments', data);
  }

  Future<void> _scheduleReminder(Appointment appt) async {
    debugPrint("Scheduling appointment for ${appt.doctor}");

    if (appt.date.isEmpty || appt.time.isEmpty) return;

    final appointmentDate = DateTime.parse("${appt.date} ${appt.time}");
    final now = DateTime.now();

    DateTime reminderDate =
    appointmentDate.subtract(const Duration(days: 1));

    if (reminderDate.isBefore(now)) {
      reminderDate =
          appointmentDate.subtract(const Duration(hours: 1));
    }

    if (reminderDate.isBefore(now)) {
      reminderDate =
          appointmentDate.subtract(const Duration(minutes: 10));
    }

    if (reminderDate.isBefore(now)) {
      reminderDate = now.add(const Duration(minutes: 1));
    }

    debugPrint("Final reminder time: $reminderDate");

    await notificationsPlugin.zonedSchedule(
      appt.id,
      "Appointment Reminder",
      "You have an appointment with Dr. ${appt.doctor} at ${formatTo12Hour(appt.date, appt.time)}",
      tz.TZDateTime.from(reminderDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'appt_channel',
          'Appointment Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint("Scheduled successfully");
  }
  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty
          ? DateTime.parse(controller.text)
          : DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    TimeOfDay initialTime = TimeOfDay.now();

    if (controller.text.isNotEmpty) {
      final parts = controller.text.split(":");
      initialTime = TimeOfDay(
          hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final dateTime = DateTime(
          now.year, now.month, now.day, picked.hour, picked.minute);

      controller.text = DateFormat('HH:mm').format(dateTime);
    }
  }

  void _addOrEditAppointment({Appointment? existing, int? index}) {
    final doctorController =
    TextEditingController(text: existing?.doctor ?? "");
    final dateController =
    TextEditingController(text: existing?.date ?? "");
    final timeController =
    TextEditingController(text: existing?.time ?? "");
    final notesController =
    TextEditingController(text: existing?.notes ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
        Text(existing == null ? "Add Appointment" : "Edit Appointment"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: doctorController,
                decoration:
                const InputDecoration(labelText: "Doctor"),
              ),
              TextField(
                controller: dateController,
                readOnly: true,
                onTap: () => _pickDate(dateController),
                decoration:
                const InputDecoration(labelText: "Select Date"),
              ),
              TextField(
                controller: timeController,
                readOnly: true,
                onTap: () => _pickTime(timeController),
                decoration:
                const InputDecoration(labelText: "Select Time"),
              ),
              TextField(
                controller: notesController,
                decoration:
                const InputDecoration(labelText: "Notes"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (doctorController.text.isEmpty ||
                  dateController.text.isEmpty ||
                  timeController.text.isEmpty) return;

              final appt = Appointment(
                id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
                doctor: doctorController.text.trim(),
                date: dateController.text.trim(),
                time: timeController.text.trim(),
                notes: notesController.text.trim(),
              );

              if (!mounted) return;

              setState(() {
                if (existing == null) {
                  appointments.add(appt);
                } else if (index != null) {
                  appointments[index] = appt;
                }
              });

              _saveAppointments();
              _scheduleReminder(appt);

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteAppointment(int index) async {
    final appt = appointments[index];

    setState(() {
      appointments.removeAt(index);
    });

    _saveAppointments();
    await notificationsPlugin.cancel(appt.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appointments")),
      body: appointments.isEmpty
          ? const Center(child: Text("No appointments added yet"))
          : ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appt = appointments[index];

          return Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today,
                  color: Colors.blue),
              title: Text(
                "${appt.doctor} - ${appt.date} ${formatTo12Hour(appt.date, appt.time)}",
              ),
              subtitle: Text(appt.notes),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit,
                        color: Colors.orange),
                    onPressed: () =>
                        _addOrEditAppointment(
                            existing: appt, index: index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        color: Colors.red),
                    onPressed: () =>
                        _deleteAppointment(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditAppointment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}