import 'dart:io';
import 'package:flutter/material.dart';
import '../../../utils/trash_scanner.dart';

class SystemBinPage extends StatefulWidget {
  const SystemBinPage({super.key});

  @override
  State<SystemBinPage> createState() => _SystemBinPageState();
}

class _SystemBinPageState extends State<SystemBinPage> {

  List<FileSystemEntity> files = [];
  bool loading = true;
  double trashSize = 0;

  @override
  void initState() {
    super.initState();
    loadTrash();
  }

  Future<void> loadTrash() async {

    setState(() => loading = true);

    final scanned = await TrashScanner.scanTrash();
    final size = await TrashScanner.getTrashSize();

    setState(() {
      files = scanned;
      trashSize = size;
      loading = false;
    });
  }

  Future<void> clearTrash() async {

    await TrashScanner.clearTrash();

    loadTrash();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Trash cleaned")),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("System Trash"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: clearTrash,
          )
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : files.isEmpty
          ? const Center(child: Text("No files in Trash"))
          : Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              "Trash Size: ${trashSize.toStringAsFixed(2)} GB",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {

                File file = files[index] as File;

                return ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(file.path.split('/').last),
                  subtitle: Text(file.path),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}