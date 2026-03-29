import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  List<Map<String, dynamic>> prescriptions = [];

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('prescriptions') ?? [];
    setState(() {
      prescriptions = data.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList();
    });
  }

  Future<void> _savePrescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prescriptions.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('prescriptions', data);
  }

  Future<void> _addPrescription() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);

      // Save into app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final projectDir = Directory('${appDir.path}/prescriptions');
      if (!projectDir.existsSync()) {
        projectDir.createSync(recursive: true);
      }

      final savedFile = await file.copy(
        '${projectDir.path}/${file.uri.pathSegments.last}',
      );

      setState(() {
        prescriptions.add({
          "path": savedFile.path,
          "date": DateTime.now().toString().split(" ")[0],
        });
      });

      _savePrescriptions();
    }
  }

  void _viewPrescription(String path) {
    final file = File(path);
    final ext = file.path.split('.').last.toLowerCase();
    if (ext == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PDFViewerScreen(file: file)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ImageViewerScreen(file: file)),
      );
    }
  }

  void _deletePrescription(int index) {
    final path = prescriptions[index]["path"];
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
    setState(() {
      prescriptions.removeAt(index);
    });
    _savePrescriptions();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Prescription deleted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Prescriptions")),
      body: prescriptions.isEmpty
          ? const Center(child: Text("No prescriptions added yet"))
          : ListView.builder(
        itemCount: prescriptions.length,
        itemBuilder: (context, index) {
          final pres = prescriptions[index];
          final path = pres["path"];
          final date = pres["date"];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: Text(path.split('/').last),
              subtitle: Text("Date: $date"),
              onTap: () => _viewPrescription(path),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deletePrescription(index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPrescription,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PDFViewerScreen extends StatelessWidget {
  final File file;
  const PDFViewerScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(file.path.split('/').last)),
      body: PDFView(filePath: file.path),
    );
  }
}

class ImageViewerScreen extends StatelessWidget {
  final File file;
  const ImageViewerScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(file.path.split('/').last)),
      body: Center(child: Image.file(file)),
    );
  }
}
