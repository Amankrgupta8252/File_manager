import 'dart:io';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../file_explorer/view/file_action_bar.dart';

class InternalStoragePage extends StatefulWidget {
  final String? customPath;
  final String title;

  const InternalStoragePage({
    super.key,
    this.customPath,
    this.title = "Internal Storage",
  });

  @override
  State<InternalStoragePage> createState() => _InternalStoragePageState();
}

class _InternalStoragePageState extends State<InternalStoragePage> {

  List<FileSystemEntity> files = [];
  Set<FileSystemEntity> selectedEntities = {};

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

          return a.path
              .toLowerCase()
              .compareTo(b.path.toLowerCase());
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

  // GET SELECTED FILES

  Future<List<File>> getSelectedFiles() async {

    List<File> files = [];

    for (var entity in selectedEntities) {

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

  // SHARE

  Future<void> _handleShare() async {

    final files = await getSelectedFiles();

    if (files.isNotEmpty) {

      await Share.shareXFiles(
        files.map((f) => XFile(f.path)).toList(),
      );
    }
  }

  // COPY

  Future<void> _handleCopy() async {

    final files = await getSelectedFiles();

    if (files.isEmpty) return;

    String? destination =
    await FilePicker.platform.getDirectoryPath();

    if (destination == null) return;

    for (var file in files) {

      final newPath =
          "$destination/${p.basename(file.path)}";

      await file.copy(newPath);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Files copied")),
    );
  }

  // MOVE

  Future<void> _handleMove() async {

    final files = await getSelectedFiles();

    if (files.isEmpty) return;

    String? destination =
    await FilePicker.platform.getDirectoryPath();

    if (destination == null) return;

    for (var file in files) {

      final newPath =
          "$destination/${p.basename(file.path)}";

      await file.copy(newPath);
      await file.delete();
    }

    _getFiles();

    setState(() {
      selectedEntities.clear();
      isSelectionMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Files moved")),
    );
  }

  // RENAME

  void _handleRename() {

    if (selectedEntities.length != 1) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Select one item")),
      );

      return;
    }

    final entity = selectedEntities.first;

    final oldName = p.basename(entity.path);

    final controller =
    TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(

        title: const Text("Rename"),

        content: TextField(
          controller: controller,
          autofocus: true,
        ),

        actions: [

          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),

          TextButton(
            onPressed: () async {

              String dir = p.dirname(entity.path);

              String newPath =
              p.join(dir, controller.text);

              await entity.rename(newPath);

              Navigator.pop(context);

              _getFiles();

              setState(() {
                selectedEntities.clear();
                isSelectionMode = false;
              });
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  // DELETE

  Future<void> _handleDelete() async {

    if (selectedEntities.isEmpty) return;

    bool? confirm = await showDialog(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text("Delete"),

        content: Text(
            "${selectedEntities.length} items will be deleted."),

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

      for (var entity in selectedEntities) {

        try {

          if (await entity.exists()) {
            await entity.delete(recursive: true);
          }

        } catch (e) {
          debugPrint("Delete error $e");
        }
      }

      _getFiles();

      setState(() {
        selectedEntities.clear();
        isSelectionMode = false;
      });
    }
  }

  void _toggleSelection(FileSystemEntity entity) {

    setState(() {

      if (selectedEntities.contains(entity)) {

        selectedEntities.remove(entity);

        if (selectedEntities.isEmpty) {
          isSelectionMode = false;
        }

      } else {

        selectedEntities.add(entity);
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

        leading: isSelectionMode
            ? IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                isSelectionMode = false;
                selectedEntities.clear();
              });
            })
            : const BackButton(),

        title: Text(
          isSelectionMode
              ? "${selectedEntities.length} Selected"
              : widget.title,
          style: const TextStyle(
              fontWeight: FontWeight.bold),
        ),

        actions: [

          if (!isSelectionMode)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const SearchPage(),
                  ),
                );
              },
            ),

          const SizedBox(width: 10),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : files.isEmpty
          ? const Center(child: Text("Empty Folder"))
          : ListView.separated(

        itemCount: files.length,

        separatorBuilder: (context, index) => const Divider(
          height: 1,
          thickness: 0.6,
          indent: 70,
        ),

        itemBuilder: (context, index) {

          final entity = files[index];
          final name = p.basename(entity.path);

          final isDir = entity is Directory;
          final isSelected = selectedEntities.contains(entity);

          return ListTile(

            selected: isSelected,
            selectedTileColor: Colors.blue.withOpacity(0.05),

            onTap: () {

              if (isSelectionMode) {
                _toggleSelection(entity);
              }

              else if (isDir) {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InternalStoragePage(
                      customPath: entity.path,
                      title: name,
                    ),
                  ),
                );
              }

              else {
                OpenFile.open(entity.path);
              }
            },

            onLongPress: () => _toggleSelection(entity),

            leading: Stack(
              children: [

                Icon(
                  isDir
                      ? Icons.folder
                      : _getFileIcon(name),
                  size: 34,
                  color: isDir
                      ? Colors.amber
                      : Colors.blue,
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
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            subtitle: Text(
              isDir
                  ? "Folder"
                  : _getFileSize(entity),
            ),

            trailing: isSelectionMode
                ? Checkbox(
              value: isSelected,
              onChanged: (_) =>
                  _toggleSelection(entity),
            )
                : const Icon(Icons.chevron_right),
          );
        },
      ),

      bottomNavigationBar: isSelectionMode
          ? FileActionBar(
        selectedCount: selectedEntities.length,
        onShare: _handleShare,
        onCopy: _handleCopy,
        onMove: _handleMove,
        onRename: _handleRename,
        onDelete: _handleDelete,
      )
          : null,
    );
  }

  IconData _getFileIcon(String fileName) {

    String ext = p.extension(fileName).toLowerCase();

    if (ext == ".pdf") return Icons.picture_as_pdf;
    if (ext == ".apk") return Icons.android;
    if (ext == ".zip") return Icons.archive;
    if (ext == ".jpg" || ext == ".png") return Icons.image;
    if (ext == ".mp4") return Icons.video_collection;
    if (ext == ".mp3") return Icons.music_note;

    return Icons.insert_drive_file;
  }

  String _getFileSize(FileSystemEntity entity) {

    if (entity is File) {

      try {

        int bytes = entity.lengthSync();

        if (bytes < 1024) return "$bytes B";

        if (bytes < 1024 * 1024) {
          return "${(bytes / 1024).toStringAsFixed(1)} KB";
        }

        return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";

      } catch (e) {
        return "Unknown";
      }
    }

    return "";
  }
}