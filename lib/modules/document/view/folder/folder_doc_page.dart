import 'dart:io';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

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

  // --- DELETE FUNCTION ---
  Future<void> _deleteSelectedFiles() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Documents?"),
        content: Text("${selectedFiles.length} files permanently delete ho jayengi."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
          debugPrint("Error: $e");
        }
      }
      setState(() {
        selectedFiles.clear();
        isSelectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Files deleted successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          isSelectionMode ? "${selectedFiles.length} Selected" : widget.folderName,
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              onPressed: _deleteSelectedFiles,
            ),

            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Sorting ya settings ka logic yahan add karein
              },
            ),
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
            selectedTileColor: Colors.blue.withOpacity(0.05),
            onTap: () {
              if (isSelectionMode) {
                _toggleSelection(file);
              } else {
                OpenFile.open(file.path);
              }
            },
            onLongPress: () => _toggleSelection(file),
            leading: Stack(
              children: [
                Icon(
                  fileName.endsWith('.pdf') ? Icons.picture_as_pdf : Icons.description,
                  color: fileName.endsWith('.pdf') ? Colors.red : Colors.blue,
                  size: 30,
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
            subtitle: Text("${(file.lengthSync() / 1024).toStringAsFixed(1)} KB"),
            trailing: isSelectionMode
                ? Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleSelection(file),
            )
                : null,
          );
        },
      ),
    );
  }
}