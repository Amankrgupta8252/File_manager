import 'dart:io';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:file_manager/data/storage_provider.dart';

class SDCardStoragePage extends StatefulWidget {
  final String? customPath;
  final String title;

  const SDCardStoragePage({super.key, this.customPath, this.title = "SD Card"});

  @override
  State<SDCardStoragePage> createState() => _SDCardStoragePageState();
}

class _SDCardStoragePageState extends State<SDCardStoragePage> {
  List<FileSystemEntity> files = [];
  Set<FileSystemEntity> selectedFiles = {};
  bool isSelectionMode = false;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    if (await Permission.manageExternalStorage.request().isGranted) {
      _fetchFiles();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = "Permission Denied! 'All Files Access' enable karein.";
      });
    }
  }

  Future<void> _fetchFiles() async {
    setState(() => isLoading = true);
    try {
      String? path = widget.customPath ?? context.read<StorageProvider>().sdCardPath;

      if (path == null || path.isEmpty) {
        setState(() {
          errorMessage = "SD Card not detected.";
          isLoading = false;
        });
        return;
      }

      final directory = Directory(path);
      if (await directory.exists()) {
        final List<FileSystemEntity> dirFiles = await directory.list().toList();
        dirFiles.sort((a, b) {
          if (a is Directory && b is! Directory) return -1;
          if (a is! Directory && b is Directory) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });

        setState(() {
          files = dirFiles;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Access Denied: SD Card restricted ho sakta hai.";
        isLoading = false;
      });
    }
  }

  // --- DELETE LOGIC ---
  Future<void> _confirmDelete() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Items?"),
        content: Text("${selectedFiles.length} items permanently delete ho jayenge."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      for (var file in selectedFiles) {
        try {
          if (file is Directory) {
            await file.delete(recursive: true);
          } else {
            await file.delete();
          }
        } catch (e) {
          debugPrint("Delete Error: $e");
        }
      }

      // Refresh list
      selectedFiles.clear();
      isSelectionMode = false;
      await _fetchFiles();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selected items deleted")),
      );
    }
  }

  void _toggleSelection(FileSystemEntity file) {
    setState(() {
      if (selectedFiles.contains(file)) {
        selectedFiles.remove(file);
        if (selectedFiles.isEmpty) isSelectionMode = false;
      } else {
        selectedFiles.add(file);
        isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          isSelectionMode ? "${selectedFiles.length} Selected" : widget.title,
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              onPressed: _confirmDelete,
            ),
          IconButton(onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          }, icon: const Icon(Icons.search, )),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, )),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildErrorUI()
          : files.isEmpty
          ? const Center(child: Text("Folder is empty"))
          : RefreshIndicator(
        onRefresh: _fetchFiles,
        child: ListView.separated(
          itemCount: files.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
          itemBuilder: (context, index) {
            final entity = files[index];
            final String fileName = p.basename(entity.path);
            final bool isDir = entity is Directory;
            final bool isSelected = selectedFiles.contains(entity);

            return ListTile(
              selected: isSelected,
              selectedTileColor: Colors.blue.withOpacity(0.05),
              leading: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDir ? Colors.orange : Colors.blue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDir ? Icons.folder : _getFileIcon(fileName),
                      color: isDir ? Colors.orange : Colors.blue,
                    ),
                  ),
                  if (isSelected)
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: Icon(Icons.check_circle, size: 18, color: Colors.blue),
                    ),
                ],
              ),
              title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(isDir ? "Folder" : _getFileSize(entity as File)),
              onTap: () {
                if (isSelectionMode) {
                  _toggleSelection(entity);
                } else {
                  if (isDir) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SDCardStoragePage(
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
              trailing: isSelectionMode
                  ? Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(entity)
              )
                  : const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  // --- HELPERS (Baki code same) ---
  IconData _getFileIcon(String name) {
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (name.endsWith('.apk')) return Icons.android;
    if (name.endsWith('.zip')) return Icons.archive;
    return Icons.insert_drive_file;
  }

  String _getFileSize(File file) {
    try {
      int bytes = file.lengthSync();
      if (bytes < 1024) return "$bytes B";
      if (bytes < 1048576) return "${(bytes / 1024).toStringAsFixed(1)} KB";
      return "${(bytes / 1048576).toStringAsFixed(1)} MB";
    } catch (e) { return "File"; }
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sd_card_alert, size: 60, color: Colors.redAccent),
          const SizedBox(height: 10),
          Text(errorMessage!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => openAppSettings(), child: const Text("Settings")),
        ],
      ),
    );
  }
}