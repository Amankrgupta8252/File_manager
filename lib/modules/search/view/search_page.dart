import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:file_manager/data/storage_provider.dart';
import 'package:path/path.dart' as p;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Set<FileSystemEntity> selectedFiles = {};
  bool isSelectionMode = false;

  // --- FILE OPEN FUNCTION ---
  void _openFile(String path) async {
    final result = await OpenFile.open(path);

    // Agar koi error aaye (jaise app nahi mili open karne ke liye)
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open file: ${result.message}")),
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
    final provider = Provider.of<StorageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: isSelectionMode
            ? Text("${selectedFiles.length} Selected")
            : TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (value) => provider.searchFiles(value),
          decoration: const InputDecoration(
            hintText: "Search files...",
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Delete logic yahan aayega (jo pichle message mein diya tha)
              },
            )
        ],
      ),
      body: provider.filteredFiles.isEmpty
          ? const Center(child: Text("No files found"))
          : ListView.builder(
        itemCount: provider.filteredFiles.length,
        itemBuilder: (context, index) {
          final file = provider.filteredFiles[index];
          final name = p.basename(file.path);
          final isSelected = selectedFiles.contains(file);

          return ListTile(
            selected: isSelected,
            onTap: () {
              if (isSelectionMode) {
                _toggleSelection(file);
              } else {
                if (file is File) {
                  _openFile(file.path); // 👈 File open hogi
                } else {
                  // Agar folder hai toh aap apne InternalStoragePage par navigate kar sakte hain
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Opening folders from search coming soon")),
                  );
                }
              }
            },
            onLongPress: () => _toggleSelection(file),
            leading: Icon(
              file is Directory ? Icons.folder : Icons.insert_drive_file,
              color: file is Directory ? Colors.amber : Colors.blue,
            ),
            title: Text(name),
            subtitle: Text(file.path, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
        },
      ),
    );
  }
}