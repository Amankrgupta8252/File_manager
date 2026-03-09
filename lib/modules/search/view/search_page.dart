import 'dart:io';
import 'package:file_manager/models/quick_access_model.dart';
import 'package:file_manager/modules/document/view/folder/folder_doc_page.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../../../utils/data/quick_access_provider.dart';
import '../../../utils/data/storage_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Set<FileSystemEntity> selectedFiles = {};
  bool isSelectionMode = false;

  // --- 1. FILE OPEN FUNCTION ---
  void _openFile(String path) async {
    final result = await OpenFile.open(path);
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open file: ${result.message}")),
      );
    }
  }

  // --- 2. FOLDER OPEN FUNCTION (With History Update) ---
  void _openFolder(String folderPath) {
    final folderName = p.basename(folderPath);
    final folder = QuickAccessFolder(name: folderName, path: folderPath);

    // ✅ History mein add karo
    context.read<QuickAccessProvider>().addToHistory(folder);

    // ✅ Folder Page par navigate karo
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderDocsPage(
          folderName: folderName,
          files: Directory(folderPath).existsSync()
              ? Directory(folderPath).listSync().whereType<File>().toList()
              : [],
        ),
      ),
    );
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
      appBar: AppBar(
        scrolledUnderElevation: 0,
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
                // Delete logic yahan add karein
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
                // ✅ Check: File hai ya Folder
                if (file is File) {
                  _openFile(file.path);
                } else if (file is Directory) {
                  _openFolder(file.path); // 👈 Folder open hoga + history banegi
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