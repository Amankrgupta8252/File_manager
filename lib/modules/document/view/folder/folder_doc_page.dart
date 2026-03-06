import 'dart:io';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import '../../../file_explorer/view/file_action_bar.dart';

class FolderDocsPage extends StatefulWidget {
  final String folderName;
  final List<File> files;

  const FolderDocsPage({super.key, required this.folderName, required this.files});

  @override
  State<FolderDocsPage> createState() => _FolderDocsPageState();
}

class _FolderDocsPageState extends State<FolderDocsPage> {
  late List<File> currentFiles;
  Set<File> selectedFiles = {};
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    currentFiles = List.from(widget.files);
  }

  // --- ACTION BAR FUNCTIONS ---

  void _handleShare() {
    debugPrint("Sharing ${selectedFiles.length} documents");
    // Share functionality yahan add karein
  }

  void _handleRename() {
    if (selectedFiles.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select only one file to rename")),
      );
      return;
    }

    final File file = selectedFiles.first;
    final String oldName = p.basename(file.path);
    final TextEditingController renameController = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Document"),
        content: TextField(
          controller: renameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              try {
                String dir = p.dirname(file.path);
                String newPath = p.join(dir, renameController.text);
                await file.rename(newPath);

                setState(() {
                  int index = currentFiles.indexOf(file);
                  currentFiles[index] = File(newPath);
                  selectedFiles.clear();
                  isSelectionMode = false;
                });
                Navigator.pop(context);
              } catch (e) {
                debugPrint("Rename failed: $e");
              }
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Documents?"),
        content: Text("${selectedFiles.length} files permanently delete ho jayengi."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (var file in selectedFiles) {
        try {
          if (await file.exists()) {
            await file.delete();
            currentFiles.remove(file);
          }
        } catch (e) {
          debugPrint("Delete Error: $e");
        }
      }
      setState(() {
        selectedFiles.clear();
        isSelectionMode = false;
      });
    }
  }

  void _toggleSelection(File file) {
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
      // backgroundColor: Colors.white,
      appBar: AppBar(
        // backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0.5,
        // iconTheme: const IconThemeData(color: Colors.black),
        leading: isSelectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: () {
          setState(() {
            isSelectionMode = false;
            selectedFiles.clear();
          });
        })
            : const BackButton(),
        title: Text(
          isSelectionMode ? "${selectedFiles.length} Selected" : widget.folderName,
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          if (!isSelectionMode)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchPage())),
            ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: currentFiles.isEmpty
          ? const Center(child: Text("No documents found"))
          : ListView.separated(
        itemCount: currentFiles.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        separatorBuilder: (context, index) => const Divider(indent: 70, height: 1),
        itemBuilder: (context, index) {
          final file = currentFiles[index];
          final fileName = p.basename(file.path);
          final isSelected = selectedFiles.contains(file);

          return ListTile(
            selected: isSelected,
            selectedTileColor: Colors.green.withOpacity(0.05),
            onTap: () => isSelectionMode ? _toggleSelection(file) : OpenFile.open(file.path),
            onLongPress: () => _toggleSelection(file),
            leading: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getFileColor(fileName).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getFileIcon(fileName), color: _getFileColor(fileName), size: 24),
                ),
                if (isSelected)
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(Icons.check_circle, size: 16, color: Colors.blue),
                  ),
              ],
            ),
            title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text(_getFileSize(file), style: const TextStyle(fontSize: 12)),
            trailing: isSelectionMode
                ? Checkbox(value: isSelected, onChanged: (_) => _toggleSelection(file), activeColor: Colors.green)
                : const Icon(Icons.more_vert, size: 18, color: Colors.grey),
          );
        },
      ),

      // --- INTEGRATING UNIVERSAL ACTION BAR ---
      bottomNavigationBar: isSelectionMode
          ? FileActionBar(
        selectedCount: selectedFiles.length,
        onShare: _handleShare,
        onCopy: () => debugPrint("Copy Doc"),
        onMove: () => debugPrint("Move Doc"),
        onRename: _handleRename,
        onDelete: _handleDelete,
      )
          : null,
    );
  }

  // --- HELPERS ---
  IconData _getFileIcon(String name) {
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (name.endsWith('.docx') || name.endsWith('.doc')) return Icons.description;
    if (name.endsWith('.xlsx') || name.endsWith('.xls')) return Icons.table_chart;
    if (name.endsWith('.txt')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String name) {
    if (name.endsWith('.pdf')) return Colors.red;
    if (name.endsWith('.docx') || name.endsWith('.doc')) return Colors.blue;
    if (name.endsWith('.xlsx') || name.endsWith('.xls')) return Colors.green;
    return Colors.grey;
  }

  String _getFileSize(File file) {
    try {
      int bytes = file.lengthSync();
      if (bytes < 1024) return "$bytes B";
      if (bytes < 1048576) return "${(bytes / 1024).toStringAsFixed(1)} KB";
      return "${(bytes / 1048576).toStringAsFixed(1)} MB";
    } catch (e) {
      return "Size unknown";
    }
  }
}