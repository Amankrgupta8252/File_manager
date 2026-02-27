import 'dart:io';
import 'package:flutter/material.dart';
import 'package:external_path/external_path.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart'; // Provider import karein
// Aapka StorageProvider import karein

class SDCardStoragePage extends StatefulWidget {
  final String? customPath;
  final String title;

  const SDCardStoragePage({super.key, this.customPath, this.title = "SD Card"});

  @override
  State<SDCardStoragePage> createState() => _SDCardStoragePageState();
}

class _SDCardStoragePageState extends State<SDCardStoragePage> {
  List<FileSystemEntity> files = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initStorage();
  }

  Future<void> _initStorage() async {
    // 1. Pehle permission check karein
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    if (status.isGranted) {
      _getFiles();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = "Permission Denied! Please enable 'All Files Access' in Settings.";
      });
    }
  }

  Future<void> _getFiles() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String path = "";

      // 2. Path nikalne ka sahi logic
      if (widget.customPath != null) {
        path = widget.customPath!;
      } else {
        // Aapka MethodChannel wala StorageProvider yahan kaam aayega
        // Kyunki external_path package Android 11+ pe kabhi kabhi null deta hai
        try {
          List<String>? paths = await ExternalPath.getExternalStorageDirectories();
          if (paths!.length > 1) {
            path = paths[1];
          } else {

          }
        } catch (e) {
          errorMessage = "SD Card detection failed.";
        }
      }

      if (path.isEmpty) {
        setState(() {
          errorMessage = "SD Card not found or path is empty!";
          isLoading = false;
        });
        return;
      }

      final directory = Directory(path);

      // 3. Check access safely
      if (await directory.exists()) {
        // Android 11+ mein listSync() crash kar sakta hai agar permission delay ho
        // Isliye list().toList() use karna behtar hai
        final List<FileSystemEntity> dirFiles = await directory.list().toList();

        dirFiles.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });

        setState(() {
          files = dirFiles;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Access Denied. Folder does not exist or restricted.";
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("SD Card Error: $e");
      setState(() {
        errorMessage = "Access Denied. System restricted this folder.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build logic same rahega... (Listview and ErrorUI)
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildErrorUI()
          : files.isEmpty
          ? const Center(child: Text("Folder is empty"))
          : ListView.separated(
        itemCount: files.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
        itemBuilder: (context, index) {
          final entity = files[index];
          final String fileName = p.basename(entity.path);
          final bool isDirectory = entity is Directory;
          return ListTile(
            leading: Icon(
              isDirectory ? Icons.folder : Icons.insert_drive_file,
              color: isDirectory ? Colors.deepPurpleAccent : Colors.blueAccent,
            ),
            title: Text(fileName),
            onTap: () {
              if (isDirectory) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SDCardStoragePage(customPath: entity.path, title: fileName)));
              } else {
                OpenFile.open(entity.path);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_person, size: 60, color: Colors.redAccent),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(errorMessage!, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            child: const Text("Open App Settings"),
          )
        ],
      ),
    );
  }
}