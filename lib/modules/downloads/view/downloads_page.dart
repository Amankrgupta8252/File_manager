import 'dart:io';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:file_manager/data/file_storage_provider.dart';
import 'package:path/path.dart' as p;

import '../../internal_storage/view/InternalStoragePage.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  Set<FileSystemEntity> selectedFiles = {};
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    // Page load hote hi downloads fetch karein
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileStorageProvider>().fetchDownloadFiles();
    });
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

  // --- DELETE LOGIC ---
  Future<void> _deleteSelectedFiles() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete?"),
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
      for (var file in selectedFiles) {
        try {
          if (await file.exists()) {
            await file.delete(recursive: true);
          }
        } catch (e) {
          debugPrint("Error deleting: $e");
        }
      }
      // UI refresh karein
      if (mounted) {
        context.read<FileStorageProvider>().fetchDownloadFiles();
        setState(() {
          selectedFiles.clear();
          isSelectionMode = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileProvider = context.watch<FileStorageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          isSelectionMode ? "${selectedFiles.length} Selected" : "Downloads",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.black),
              onPressed: _deleteSelectedFiles,
            )
          else ...[
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              ),
              icon: const Icon(Icons.search),
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
          ],
        ],
      ),
      body: fileProvider.downloadFiles.isEmpty
          ? const Center(child: Text("No downloads found"))
          : ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: fileProvider.downloadFiles.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 0.5,
          color: Colors.grey.withOpacity(0.3),
          indent: 70,
        ),
        itemBuilder: (context, index) {
          final file = fileProvider.downloadFiles[index];
          final isDir = file is Directory;
          final isSelected = selectedFiles.contains(file);
          final fileName = p.basename(file.path);

          return ListTile(
            selected: isSelected,
            selectedTileColor: Colors.blue.withOpacity(0.05),
            onTap: () {
              if (isSelectionMode) {
                _toggleSelection(file);
              } else {
                if (isDir) {
                  // FOLDER OPEN LOGIC: Naye page par navigate karein
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InternalStoragePage(
                        customPath: file.path,
                      ),
                    ),
                  );
                } else {
                  OpenFile.open(file.path);
                }
              }
            },
            onLongPress: () => _toggleSelection(file),
            leading: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDir ? Colors.brown : Color(0xf58e5959)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDir ? Icons.folder : _getFileIcon(file.path),
                    color: (isDir ? Colors.brown : Color(0xf58e5959)),
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
            title: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(_getFileSize(file), style: const TextStyle(fontSize: 12)),
            trailing: isSelectionMode
                ? Checkbox(
              value: isSelected,
              onChanged: (v) => _toggleSelection(file),
              activeColor: Colors.blue,
            )
                : const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          );
        },
      ),
    );
  }

  // --- HELPER FUNCTIONS ---

  IconData _getFileIcon(String path) {
    String ext = path.toLowerCase();
    if (ext.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (ext.endsWith('.apk')) return Icons.android;
    if (ext.endsWith('.zip') || ext.endsWith('.rar')) return Icons.archive;
    if (ext.endsWith('.jpg') || ext.endsWith('.png') || ext.endsWith('.jpeg')) return Icons.image;
    if (ext.endsWith('.mp4') || ext.endsWith('.mkv')) return Icons.video_library;
    if (ext.endsWith('.mp3') || ext.endsWith('.wav')) return Icons.audiotrack;
    return Icons.insert_drive_file;
  }

  String _getFileSize(FileSystemEntity file) {
    if (file is Directory) return "Folder";
    try {
      int bytes = (file as File).lengthSync();
      if (bytes < 1024) return "$bytes B";
      if (bytes < 1048576) return "${(bytes / 1024).toStringAsFixed(1)} KB";
      return "${(bytes / 1048576).toStringAsFixed(1)} MB";
    } catch (e) {
      return "File";
    }
  }
}