import 'dart:io';
import 'package:file_manager/modules/audio/view/folder/audio_list_page.dart';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../../../utils/data/file_storage_provider.dart';
import '../../file_explorer/view/file_action_bar.dart';

class AudioFoldersPage extends StatefulWidget {
  const AudioFoldersPage({super.key});

  @override
  State<AudioFoldersPage> createState() => _AudioFoldersPageState();
}

class _AudioFoldersPageState extends State<AudioFoldersPage> {
  bool isSelectionMode = false;
  Set<AssetPathEntity> selectedFolders = {};

  // ---------------- SHARE ----------------

  Future<void> _handleShare() async {
    final files = await getSelectedFiles();

    if (files.isEmpty) return;

    await Share.shareXFiles(files.map((f) => XFile(f.path)).toList());
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Files moved successfully")));
    }
  }

  // ---------------- RENAME ----------------

  Future<void> _handleRename() async {

    final files = await getSelectedFiles();

    if (files.isEmpty) return;

    if (files.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rename supports only one file")),
      );
      return;
    }

    final file = files.first;

    String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        TextEditingController controller =
        TextEditingController(text: file.uri.pathSegments.last);

        return AlertDialog(
          title: const Text("Rename File"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter new file name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty) return;

    final dir = file.parent.path;

    final newPath = "$dir/$newName";

    await file.rename(newPath);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File renamed successfully")),
      );
    }

    setState(() {});
  }

  // ---------------- DELETE ----------------

  Future<void> _handleDelete() async {
    final files = await getSelectedFiles();

    for (var file in files) {
      if (await file.exists()) {
        await file.delete();
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Files deleted")));
    }
  }

  // ---------------- SELECTION ----------------

  void _toggleSelection(AssetPathEntity folder) {
    setState(() {
      if (selectedFolders.contains(folder)) {
        selectedFolders.remove(folder);

        if (selectedFolders.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        selectedFolders.add(folder);
        isSelectionMode = true;
      }
    });
  }

  // ---------------- GET FILES ----------------

  Future<List<File>> getSelectedFiles() async {
    List<File> files = [];

    for (var folder in selectedFolders) {
      final assets = await folder.getAssetListPaged(page: 0, size: 1000);

      for (var asset in assets) {
        final File? file = await asset.originFile;

        if (file != null) {
          files.add(file);
        }
      }
    }

    return files;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FileStorageProvider>();

    return Scaffold(
      // backgroundColor: const Color(0xFFF8F9FA),

      appBar: AppBar(
        scrolledUnderElevation: 0,

        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  isSelectionMode = false;
                  selectedFolders.clear();
                }),
              )
            : const BackButton(),

        title: Text(
          isSelectionMode ? "${selectedFolders.length} Selected" : "Music",
          style: const TextStyle(
            // color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        // backgroundColor: Colors.white,
        elevation: 0,

        // iconTheme: const IconThemeData(color: Colors.black),

        actions: [
          if (!isSelectionMode)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
              icon: const Icon(Icons.search),
            ),

          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),

      body: FutureBuilder<List<AssetPathEntity>>(
        future: provider.getAudioFolders(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No audio folders found"));
          }

          final folders = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: folders.length,

            separatorBuilder: (context, index) {
              return const Divider(
                thickness: 0.5,
                height: 1,
              );
            },

            itemBuilder: (context, index) {
              final folder = folders[index];

              final isSelected = selectedFolders.contains(folder);

              return FutureBuilder<int>(
                future: folder.assetCountAsync,

                builder: (context, countSnapshot) {
                  final count = countSnapshot.data ?? 0;

                  return ListTile(
                    selected: isSelected,

                    selectedTileColor: Colors.orange.withOpacity(0.05),

                    leading: const Icon(Icons.music_note, color: Colors.orange),

                    title: Text(
                      folder.name == "Recent" ? "All Music" : folder.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),

                    subtitle: Text("$count songs"),

                    trailing: isSelectionMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(folder),
                          )
                        : const Icon(Icons.arrow_forward_ios, size: 16),

                    onTap: () {
                      if (isSelectionMode) {
                        _toggleSelection(folder);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AudioListPage(folder: folder),
                          ),
                        );
                      }
                    },

                    onLongPress: () => _toggleSelection(folder),
                  );
                },
              );
            },
          );
        },
      ),

      bottomNavigationBar: isSelectionMode
          ? FileActionBar(
              selectedCount: selectedFolders.length,

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
