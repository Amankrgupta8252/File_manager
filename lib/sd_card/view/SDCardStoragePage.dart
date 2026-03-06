import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_manager/data/storage_provider.dart';
import '../../modules/search/view/search_page.dart';
import '../../modules/file_explorer/view/file_action_bar.dart';

class SDCardStoragePage extends StatefulWidget {
  final String? customPath;
  final String title;

  const SDCardStoragePage({
    super.key,
    this.customPath,
    this.title = "SD Card",
  });

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
    _checkPermission();
  }

  // ---------------- PERMISSION ----------------

  Future<void> _checkPermission() async {
    if (await Permission.manageExternalStorage.request().isGranted) {
      _loadFiles();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = "Storage permission denied.";
      });
    }
  }

  // ---------------- LOAD FILES ----------------

  Future<void> _loadFiles() async {
    setState(() => isLoading = true);

    try {
      String? path =
          widget.customPath ?? context.read<StorageProvider>().sdCardPath;

      if (path == null || path.isEmpty) {
        setState(() {
          errorMessage = "SD Card not detected.";
          isLoading = false;
        });
        return;
      }

      final dir = Directory(path);

      if (await dir.exists()) {
        final data = await dir.list().toList();

        data.sort((a, b) {
          if (a is Directory && b is! Directory) return -1;
          if (a is! Directory && b is Directory) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });

        setState(() {
          files = data;
          isLoading = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Unable to access SD Card";
        isLoading = false;
      });
    }
  }

  // ---------------- SELECTION ----------------

  void _toggleSelection(FileSystemEntity file) {
    setState(() {
      if (selectedFiles.contains(file)) {
        selectedFiles.remove(file);
      } else {
        selectedFiles.add(file);
      }

      isSelectionMode = selectedFiles.isNotEmpty;
    });
  }

  // ---------------- GET FILES ----------------

  Future<List<File>> getSelectedFiles() async {
    List<File> files = [];

    for (var entity in selectedFiles) {
      if (entity is File) {
        files.add(entity);
      }

      if (entity is Directory) {
        final dir = Directory(entity.path);

        try {
          final items = dir.listSync(recursive: true);

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

  Future<void> _shareFiles() async {
    List<XFile> shareFiles = [];

    for (var f in selectedFiles) {
      if (f is File) {
        shareFiles.add(XFile(f.path));
      }
    }

    if (shareFiles.isNotEmpty) {
      await Share.shareXFiles(shareFiles);
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

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Files copied")));
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

    _loadFiles();

    setState(() {
      selectedFiles.clear();
      isSelectionMode = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Files moved")));
  }

  // ---------------- RENAME ----------------

  void _handleRename() {
    if (selectedFiles.length != 1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Select one item")));
      return;
    }

    final entity = selectedFiles.first;
    final controller = TextEditingController(text: p.basename(entity.path));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename"),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              String dir = p.dirname(entity.path);
              String newPath = p.join(dir, controller.text);

              await entity.rename(newPath);

              Navigator.pop(context);

              selectedFiles.clear();
              isSelectionMode = false;

              _loadFiles();
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  // ---------------- DELETE ----------------

  Future<void> _deleteFiles() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Items?"),
        content: Text("${selectedFiles.length} items will be deleted."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
              const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      for (var file in selectedFiles) {
        await file.delete(recursive: true);
      }

      selectedFiles.clear();
      isSelectionMode = false;

      _loadFiles();
    }
  }

  // ---------------- UI ----------------

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
              selectedFiles.clear();
              isSelectionMode = false;
            });
          },
        )
            : const BackButton(),
        title: Text(
          isSelectionMode
              ? "${selectedFiles.length} Selected"
              : widget.title,
          style:
          const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!isSelectionMode)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SearchPage()));
              },
            ),
          const SizedBox(width: 10)
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : RefreshIndicator(
        onRefresh: _loadFiles,
        child: ListView.separated(
          itemCount: files.length,
          separatorBuilder: (_, __) =>
          const Divider(indent: 70),
          itemBuilder: (context, index) {
            final entity = files[index];
            final name = p.basename(entity.path);

            bool isDir = entity is Directory;
            bool isSelected =
            selectedFiles.contains(entity);

            return ListTile(
              selected: isSelected,
              selectedTileColor:
              Colors.blue.withOpacity(0.1),
              leading: Stack(
                children: [
                  Icon(
                    isDir
                        ? Icons.folder
                        : Icons.insert_drive_file,
                    size: 32,
                    color: isDir
                        ? Colors.orange
                        : Colors.blue,
                  ),
                  if (isSelected)
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: Icon(Icons.check_circle,
                          size: 18, color: Colors.blue),
                    )
                ],
              ),
              title: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              subtitle:
              Text(isDir ? "Folder" : _fileSize(entity)),
              onTap: () {
                if (isSelectionMode) {
                  _toggleSelection(entity);
                } else if (isDir) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              SDCardStoragePage(
                                customPath: entity.path,
                                title: name,
                              )));
                } else {
                  OpenFile.open(entity.path);
                }
              },
              onLongPress: () => _toggleSelection(entity),
              trailing: isSelectionMode
                  ? Checkbox(
                  value: isSelected,
                  onChanged: (_) =>
                      _toggleSelection(entity))
                  : const Icon(Icons.chevron_right),
            );
          },
        ),
      ),

      bottomNavigationBar: isSelectionMode
          ? FileActionBar(
        selectedCount: selectedFiles.length,
        onShare: _shareFiles,
        onCopy: _handleCopy,
        onMove: _handleMove,
        onRename: _handleRename,
        onDelete: _deleteFiles,
      )
          : null,
    );
  }

  // ---------------- FILE SIZE ----------------

  String _fileSize(FileSystemEntity entity) {
    if (entity is File) {
      try {
        int bytes = entity.lengthSync();

        if (bytes < 1024) return "$bytes B";
        if (bytes < 1024 * 1024) {
          return "${(bytes / 1024).toStringAsFixed(1)} KB";
        }

        return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
      } catch (e) {
        return "File";
      }
    }

    return "";
  }
}