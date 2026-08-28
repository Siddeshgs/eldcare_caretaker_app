import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/medicine.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  List<Medicine> medicines = [];
  final FlutterTts flutterTts = FlutterTts();
  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  Timer? _foregroundReminderTimer;



  @override
  void initState() {
    super.initState();
    _configureLocalTimeZone();
    _initializeNotifications();
    _loadMedicines();
  }
  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    debugPrint("Timezone set to Asia/Kolkata");
  }
  @override
  void dispose() {
    _foregroundReminderTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.payload != null && details.payload!.isNotEmpty) {
          try {
            final med =
            Medicine.fromJson(jsonDecode(details.payload!));
            await _triggerReminder(med, showSnackbar: true);
          } catch (e) {
            debugPrint("Payload error: $e");
          }
        }
      },
    );

    final androidPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    await androidPlugin?.requestExactAlarmsPermission();
  }
  Future<void> _loadMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('medicines') ?? [];

    if (!mounted) return;

    setState(() {
      medicines = data.map((e) {
        final med = Medicine.fromJson(jsonDecode(e));

        // Normalize legacy IDs to fit within 32-bit integer limit
        if (med.id > 2147483647) {
          return Medicine(
            id: med.id.remainder(2147483647),
            name: med.name,
            dosage: med.dosage,
            time: med.time,
          );
        }
        return med;
      }).toList();
    });

    // Save corrected IDs back
    await _saveMedicines();

    for (final med in medicines) {
      await _scheduleNotification(med);
    }

    _scheduleForegroundReminder();
  }

  Future<void> _saveMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final data = medicines.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('medicines', data);
  }

  Future<void> _scheduleNotification(Medicine med) async {
    try {
      if (med.time.isEmpty) {
        debugPrint("Skipped scheduling: time is empty for ${med.name}");
        return;
      }

      final parsedTime = DateFormat("hh:mm a").parse(med.time);

      final now = tz.TZDateTime.now(tz.local);

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      debugPrint("Scheduling ${med.name} at $scheduledDate");

      await notificationsPlugin.zonedSchedule(
        med.id, // MUST use stable id
        'Medicine Reminder',
        'Time to take ${med.name} (${med.dosage})',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_reminders',
            'Medicine Reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

    } catch (e) {
      debugPrint("Scheduling error: $e");
    }
  }

  void _scheduleForegroundReminder() {
    _foregroundReminderTimer?.cancel();
    if (medicines.isEmpty) return;

    tz.TZDateTime? nextReminderTime;
    Medicine? nextMedicine;
    final now = tz.TZDateTime.now(tz.local);

    for (final med in medicines) {
      try {
        final parsedTime = DateFormat("hh:mm a").parse(med.time);

        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          parsedTime.hour,
          parsedTime.minute,
        );

        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        if (nextReminderTime == null ||
            scheduledDate.isBefore(nextReminderTime)) {
          nextReminderTime = scheduledDate;
          nextMedicine = med;
        }
      } catch (_) {}
    }

    if (nextReminderTime != null && nextMedicine != null) {
      final delay = nextReminderTime.difference(now);
      _foregroundReminderTimer = Timer(delay, () {
        if (mounted) {
          _triggerReminder(nextMedicine!, showSnackbar: true);
        }
        _scheduleForegroundReminder(); // reschedule next
      });
    }
  }

  void _addOrEditMedicine({Medicine? existingMed, int? index}) {
    showDialog(
      context: context,
      builder: (_) => _AddOrEditMedicineDialog(
        existingMed: existingMed,
        onSave: (med) async {
          if (!mounted) return;
          setState(() {
            if (existingMed == null) {
              medicines.add(med);
            } else {
              medicines[index!] = med;
            }
          });
          await _saveMedicines();
          await _scheduleNotification(med);
          _scheduleForegroundReminder();
        },
      ),
    );
  }

  void _deleteMedicine(int index) async {
    final med = medicines[index];
    setState(() {
      medicines.removeAt(index);
    });
    await _saveMedicines();
    await notificationsPlugin.cancel(med.id);
    _scheduleForegroundReminder();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Medicine deleted")),
    );
  }

  Future<void> _triggerReminder(Medicine med, {bool showSnackbar = false}) async {
    // Show notification
    await notificationsPlugin.show(
      med.id,
      "Medicine Reminder",
      "You need to take ${med.name}, ${med.dosage}, at ${med.time}.",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminders',
          'Medicine Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(med.toJson()),
    );

    // Speak reminder aloud
    await flutterTts.speak(
      "You need to take ${med.name}, ${med.dosage}, at ${med.time}.",
    );

    if (showSnackbar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Reminder spoken for: ${med.name}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Medicines")),
      body: medicines.isEmpty
          ? const Center(child: Text("No medicines added yet"))
          : ListView.builder(
        itemCount: medicines.length,
        itemBuilder: (context, index) {
          final med = medicines[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.medication, color: Colors.green),
              title: Text("${med.name} - ${med.dosage}"),
              subtitle: Text("Reminder: ${med.time}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () =>
                        _addOrEditMedicine(existingMed: med, index: index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteMedicine(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditMedicine(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddOrEditMedicineDialog extends StatefulWidget {
  final Medicine? existingMed;
  final Function(Medicine) onSave;

  const _AddOrEditMedicineDialog({this.existingMed, required this.onSave});

  @override
  State<_AddOrEditMedicineDialog> createState() =>
      _AddOrEditMedicineDialogState();
}

class _AddOrEditMedicineDialogState extends State<_AddOrEditMedicineDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingMed?.name ?? "");
    _dosageController =
        TextEditingController(text: widget.existingMed?.dosage ?? "");
    _timeController =
        TextEditingController(text: widget.existingMed?.time ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
      Text(widget.existingMed == null ? "Add Medicine" : "Edit Medicine"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: "Dosage"),
            ),
            TextField(
              controller: _timeController,
              readOnly: true,
              decoration: const InputDecoration(labelText: "Select Time"),
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(alwaysUse24HourFormat: false),
                      child: child!,
                    );
                  },
                );

                if (pickedTime != null) {
                  final now = DateTime.now();
                  final dateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  final formatted =
                  DateFormat("hh:mm a").format(dateTime);

                  _timeController.text = formatted;
                }
              },
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
            final med = Medicine(
              id: widget.existingMed?.id ?? DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
              name: _nameController.text.trim(),
              dosage: _dosageController.text.trim(),
              time: _timeController.text.trim(),
            );
            widget.onSave(med);
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

