import 'dart:io';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/modules/document/view/folder/folder_doc_page.dart';
import 'package:share_plus/share_plus.dart';
import '../../file_explorer/view/file_action_bar.dart';

class DocFoldersPage extends StatefulWidget {
  const DocFoldersPage({super.key});

  @override
  State<DocFoldersPage> createState() => _DocFoldersPageState();
}

class _DocFoldersPageState extends State<DocFoldersPage> {

  bool isSelectionMode = false;
  Set<String> selectedFolderPaths = {};
  Map<String, List<File>> folderMap = {};

  // ---------------- SHARE ----------------

  Future<void> _handleShare() async {
    final files = await getSelectedFiles();

    if (files.isNotEmpty) {
      await Share.shareXFiles(
        files.map((f) => XFile(f.path)).toList(),
      );
    }
  }

  // ---------------- COPY ----------------

  Future<void> _handleCopy() async {

    final files = await getSelectedFiles();

    if (files.isEmpty) return;

    String? destination = await FilePicker.platform.getDirectoryPath();

    if (destination == null) return;

    for (var file in files) {
      final newPath = "$destination/${file.uri.pathSegments.last}";
      await file.copy(newPath);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Files copied successfully")),
      );
    }
  }

  // ---------------- MOVE ----------------

  Future<void> _handleMove() async {

    final files = await getSelectedFiles();

    if (files.isEmpty) return;

    String? destination = await FilePicker.platform.getDirectoryPath();

    if (destination == null) return;

    for (var file in files) {
      final newPath = "$destination/${file.uri.pathSegments.last}";
      await file.rename(newPath);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Files moved successfully")),
      );
    }
  }

  // ---------------- RENAME ----------------

  void _handleRename() {

    if (selectedFolderPaths.length != 1) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select one folder")),
      );

      return;
    }

    final path = selectedFolderPaths.first;
    final folder = Directory(path);

    final name = folder.path.split('/').last;

    final controller = TextEditingController(text: name);

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(
          title: const Text("Rename Folder"),

          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter new name",
            ),
          ),

          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            TextButton(
              onPressed: () async {

                final newName = controller.text;

                final newPath =
                    "${folder.parent.path}/$newName";

                await folder.rename(newPath);

                if (context.mounted) {
                  Navigator.pop(context);
                }

                setState(() {
                  selectedFolderPaths.clear();
                  isSelectionMode = false;
                });

              },
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );
  }

  // ---------------- DELETE ----------------

  Future<void> _handleDelete() async {

    final files = await getSelectedFiles();

    if (files.isEmpty) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Files"),
        content: Text("${files.length} files will be deleted."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {

      for (var file in files) {
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        selectedFolderPaths.clear();
        isSelectionMode = false;
      });
    }
  }

  // ---------------- GET SELECTED FILES ----------------

    Future<List<File>> getSelectedFiles() async {

      List<File> files = [];

      for (var path in selectedFolderPaths) {
        files.addAll(folderMap[path] ?? []);
      }

      return files;
    }

  // ---------------- DOCUMENT SCANNER ----------------

  static Map<String, List<File>> _scanForDocs(dynamic _) {

    Map<String, List<File>> docFolders = {};

    final extensions = {
      '.pdf',
      '.doc',
      '.docx',
      '.txt',
      '.xlsx',
      '.pptx'
    };

    final List<String> targetFolders = [

      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents',
    ];

    for (String path in targetFolders) {

      final dir = Directory(path);

      if (dir.existsSync()) {

        try {

          final entities = dir.listSync(recursive: true);

          for (var entity in entities) {

            if (entity is File) {

              String filePath = entity.path.toLowerCase();

              if (extensions.any((ext) => filePath.endsWith(ext))) {

                String parentPath = entity.parent.path;

                docFolders.putIfAbsent(parentPath, () => []).add(entity);
              }
            }
          }

        } catch (e) {
          debugPrint("Skip: $path");
        }
      }
    }

    return docFolders;
  }

  // ---------------- SELECTION ----------------

  void _toggleSelection(String path) {

    setState(() {

      if (selectedFolderPaths.contains(path)) {

        selectedFolderPaths.remove(path);

        if (selectedFolderPaths.isEmpty) {
          isSelectionMode = false;
        }

      } else {

        selectedFolderPaths.add(path);
        isSelectionMode = true;
      }
    });
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      // backgroundColor: const Color(0xFFF8F9FA),

      appBar: AppBar(
        // backgroundColor: Colors.white,
        scrolledUnderElevation: 0,

        leading: isSelectionMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              selectedFolderPaths.clear();
              isSelectionMode = false;
            });
          },
        )
            : const BackButton(),

        title: Text(
          isSelectionMode
              ? "${selectedFolderPaths.length} Selected"
              : "Documents",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [

          if (!isSelectionMode)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SearchPage()),
                );
              },
            ),

          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),

      body: FutureBuilder<Map<String, List<File>>>(

        future: compute(_scanForDocs, null),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {

            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 15),
                  Text("Scanning Documents..."),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Documents Found"));
          }

          folderMap = snapshot.data!;

          final folderPaths = folderMap.keys.toList();

          return ListView.separated(

            padding: const EdgeInsets.symmetric(vertical: 10),

            itemCount: folderPaths.length,

            separatorBuilder: (c, i) =>
            const Divider(indent: 75, height: 1),

            itemBuilder: (context, index) {

              String path = folderPaths[index];

              bool isSelected =
              selectedFolderPaths.contains(path);

              return ListTile(

                selected: isSelected,

                selectedTileColor:
                Colors.green.withOpacity(0.05),

                leading: Stack(
                  children: [

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.folder,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),

                    if (isSelected)
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Colors.blue,
                        ),
                      ),
                  ],
                ),

                title: Text(
                  path.split('/').last,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600),
                ),

                subtitle:
                Text("${folderMap[path]!.length} files"),

                trailing: isSelectionMode
                    ? Checkbox(
                  value: isSelected,
                  onChanged: (_) =>
                      _toggleSelection(path),
                )
                    : const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),

                onTap: () {

                  if (isSelectionMode) {

                    _toggleSelection(path);

                  } else {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => FolderDocsPage(
                          folderName:
                          path.split('/').last,
                          files: folderMap[path]!,
                        ),
                      ),
                    );
                  }
                },

                onLongPress: () => _toggleSelection(path),
              );
            },
          );
        },
      ),

      bottomNavigationBar: isSelectionMode
          ? FileActionBar(
        selectedCount: selectedFolderPaths.length,
        onShare: _handleShare,
        onCopy: _handleCopy,
        onMove: _handleMove,
        onRename: _handleRename,
        onDelete: _handleDelete,
      )
          : null,
    );
  }
}