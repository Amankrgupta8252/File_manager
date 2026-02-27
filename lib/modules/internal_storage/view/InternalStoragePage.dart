import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

class InternalStoragePage extends StatefulWidget {
  final String? customPath;
  final String title;

  const InternalStoragePage({super.key, this.customPath, this.title = "Internal Storage"});

  @override
  State<InternalStoragePage> createState() => _InternalStoragePageState();
}

class _InternalStoragePageState extends State<InternalStoragePage> {
  List<FileSystemEntity> files = [];
  Set<FileSystemEntity> selectedEntities = {}; // Selected items store karne ke liye
  bool isLoading = true;
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _getFiles();
  }

  Future<void> _getFiles() async {
    setState(() => isLoading = true);
    try {
      String path = widget.customPath ?? "/storage/emulated/0";
      final directory = Directory(path);
      if (await directory.exists()) {
        final List<FileSystemEntity> dirFiles = directory.listSync();

        dirFiles.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });

        setState(() {
          files = dirFiles;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  // --- DELETE LOGIC (Multiple Files/Folders) ---
  Future<void> _deleteSelectedItems() async {
    if (selectedEntities.isEmpty) return;

    // Confirmation Dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Items?"),
        content: Text("${selectedEntities.length} items permanently delete ho jayenge. Kya aap sure hain?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        for (var entity in selectedEntities) {
          if (await entity.exists()) {
            // recursive: true folders ko unke content ke sath delete karne ke liye
            await entity.delete(recursive: true);
          }
        }

        setState(() {
          files.removeWhere((element) => selectedEntities.contains(element));
          selectedEntities.clear();
          isSelectionMode = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Items deleted successfully")),
          );
        }
      } catch (e) {
        debugPrint("Delete Error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kuch files delete nahi ho payin (Permission Issue)")),
          );
        }
      }
    }
  }

  void _toggleSelection(FileSystemEntity entity) {
    setState(() {
      if (selectedEntities.contains(entity)) {
        selectedEntities.remove(entity);
        if (selectedEntities.isEmpty) isSelectionMode = false;
      } else {
        selectedEntities.add(entity);
        isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
            isSelectionMode ? "${selectedEntities.length} Selected" : widget.title,
            style: const TextStyle(color: Colors.black, fontSize: 18)
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteSelectedItems,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : files.isEmpty
          ? const Center(child: Text("Empty Folder"))
          : ListView.separated(
        itemCount: files.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
        itemBuilder: (context, index) {
          final entity = files[index];
          final String fileName = p.basename(entity.path);
          final bool isDirectory = entity is Directory;
          final isSelected = selectedEntities.contains(entity);

          return ListTile(
            onTap: () {
              if (isSelectionMode) {
                _toggleSelection(entity);
              } else {
                if (isDirectory) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InternalStoragePage(
                        customPath: entity.path,
                        title: fileName,
                      ),
                    ),
                  );
                } else {
                  OpenFile.open(entity.path);
                }
              }
            },
            onLongPress: () => _toggleSelection(entity),
            selected: isSelected,
            selectedTileColor: Colors.blue.withOpacity(0.05),
            leading: Stack(
              children: [
                Icon(
                  isDirectory ? Icons.folder : _getFileIcon(fileName),
                  size: 32,
                  color: isDirectory ? Colors.amber : Colors.blueAccent,
                ),
                if (isSelected)
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(Icons.check_circle, size: 18, color: Colors.blue),
                  ),
              ],
            ),
            title: Text(
              fileName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              isDirectory ? "Folder" : _getFileSize(entity),
            ),
            trailing: isSelectionMode
                ? Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleSelection(entity),
              activeColor: Colors.blue,
            )
                : const Icon(Icons.more_vert, size: 20, color: Colors.grey),
          );
        },
      ),
    );
  }

  // --- ICONS & SIZE HELPERS ---
  IconData _getFileIcon(String fileName) {
    String ext = p.extension(fileName).toLowerCase();
    if (ext == ".pdf") return Icons.picture_as_pdf;
    if (ext == ".apk") return Icons.android;
    if (ext == ".zip" || ext == ".rar") return Icons.archive;
    if (ext == ".jpg" || ext == ".png" || ext == ".jpeg") return Icons.image;
    if (ext == ".mp4" || ext == ".mkv") return Icons.video_collection;
    if (ext == ".mp3" || ext == ".wav") return Icons.music_note;
    return Icons.insert_drive_file;
  }

  String _getFileSize(FileSystemEntity entity) {
    if (entity is File) {
      try {
        int bytes = entity.lengthSync();
        if (bytes < 1024) return "$bytes B";
        if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
        return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
      } catch (e) {
        return "Unknown size";
      }
    }
    return "";
  }
}