import 'dart:io';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:file_manager/data/file_storage_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../file_explorer/view/file_action_bar.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileStorageProvider>().fetchDownloadFiles();
    });
  }

  // ---------------- GET SELECTED FILES ----------------

  Future<List<File>> getSelectedFiles() async {

    List<File> files = [];

    for (var entity in selectedFiles) {

      if (entity is File) {
        files.add(entity);
      }

      if (entity is Directory) {

        try {

          final items = entity.listSync(recursive: true);

          for (var item in items) {
            if (item is File) {
              files.add(item);
            }
          }

        } catch (e) {
          debugPrint("Directory read error: $e");
        }
      }
    }

    return files;
  }

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

      final newPath = "$destination/${p.basename(file.path)}";

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

      final newPath = "$destination/${p.basename(file.path)}";

      await file.copy(newPath);
      await file.delete();
    }

    if (mounted) {
      context.read<FileStorageProvider>().fetchDownloadFiles();

      setState(() {
        selectedFiles.clear();
        isSelectionMode = false;
      });
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Files moved successfully")),
      );
    }
  }

  // ---------------- RENAME ----------------

  void _handleRename() {

    if (selectedFiles.length != 1) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select only one item")),
      );

      return;
    }

    final entity = selectedFiles.first;

    final oldName = p.basename(entity.path);

    final controller = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(

        title: const Text("Rename"),

        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Enter new name",
          ),
        ),

        actions: [

          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),

          TextButton(

            onPressed: () async {

              try {

                String dir = p.dirname(entity.path);

                String newPath = p.join(dir, controller.text);

                await entity.rename(newPath);

                if (mounted) {

                  context.read<FileStorageProvider>().fetchDownloadFiles();

                  setState(() {
                    selectedFiles.clear();
                    isSelectionMode = false;
                  });
                }

                Navigator.pop(context);

              } catch (e) {
                debugPrint("Rename error: $e");
              }
            },

            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  // ---------------- DELETE ----------------

  Future<void> _handleDelete() async {

    bool? confirm = await showDialog(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text("Delete"),

        content: Text("${selectedFiles.length} items will be deleted permanently."),

        actions: [

          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),

          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
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
          debugPrint("Delete error: $e");
        }
      }

      if (mounted) {

        context.read<FileStorageProvider>().fetchDownloadFiles();

        setState(() {
          selectedFiles.clear();
          isSelectionMode = false;
        });
      }
    }
  }

  // ---------------- SELECTION ----------------

  void _toggleSelection(FileSystemEntity file) {

    setState(() {

      if (selectedFiles.contains(file)) {

        selectedFiles.remove(file);

        if (selectedFiles.isEmpty) {
          isSelectionMode = false;
        }

      } else {

        selectedFiles.add(file);
        isSelectionMode = true;
      }
    });
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {

    final fileProvider = context.watch<FileStorageProvider>();

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
              selectedFiles.clear();
              isSelectionMode = false;
            });
          },
        )
            : const BackButton(),

        title: Text(
          isSelectionMode
              ? "${selectedFiles.length} Selected"
              : "Downloads",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            // color: Colors.black,
          ),
        ),

        actions: [

          if (!isSelectionMode)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchPage(),
                  ),
                );
              },
            ),

          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert)),
        ],
      ),

      body: fileProvider.downloadFiles.isEmpty
          ? const Center(child: Text("No downloads found"))
          : ListView.separated(

        padding: const EdgeInsets.symmetric(vertical: 8),

        itemCount: fileProvider.downloadFiles.length,

        separatorBuilder: (_, __) =>
        const Divider(height: 1, indent: 70),

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

              } else if (isDir) {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InternalStoragePage(
                      customPath: file.path,
                    ),
                  ),
                );

              } else {

                OpenFile.open(file.path);
              }
            },

            onLongPress: () => _toggleSelection(file),

            leading: Stack(
              children: [

                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDir
                        ? Colors.brown
                        : const Color(0xFF8E5959))
                        .withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDir
                        ? Icons.folder
                        : _getFileIcon(file.path),
                    color: isDir
                        ? Colors.brown
                        : const Color(0xFF8E5959),
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
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            subtitle: Text(_getFileSize(file)),

            trailing: isSelectionMode
                ? Checkbox(
              value: isSelected,
              onChanged: (_) =>
                  _toggleSelection(file),
            )
                : const Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.grey,
            ),
          );
        },
      ),

      bottomNavigationBar: isSelectionMode
          ? FileActionBar(
        selectedCount: selectedFiles.length,
        onShare: _handleShare,
        onCopy: _handleCopy,
        onMove: _handleMove,
        onRename: _handleRename,
        onDelete: _handleDelete,
      )
          : null,
    );
  }

  // ---------------- FILE ICON ----------------

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

  // ---------------- FILE SIZE ----------------

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