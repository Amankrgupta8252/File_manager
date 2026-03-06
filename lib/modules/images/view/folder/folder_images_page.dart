import 'dart:io';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../../../file_explorer/view/file_action_bar.dart';

class FolderImagesPage extends StatefulWidget {
  final AssetPathEntity folder;

  const FolderImagesPage({super.key, required this.folder});

  @override
  State<FolderImagesPage> createState() => _FolderImagesPageState();
}

class _FolderImagesPageState extends State<FolderImagesPage> {
  List<AssetEntity> assets = [];
  Set<AssetEntity> selectedAssets = {};

  bool isLoading = true;
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    setState(() => isLoading = true);

    try {
      final list = await widget.folder.getAssetListPaged(page: 0, size: 200);

      setState(() {
        assets = list;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching images: $e");
      setState(() => isLoading = false);
    }
  }

  // ---------------- SHARE ----------------

  Future<void> _handleShare() async {
    final files = await getSelectedFiles();

    if (files.isNotEmpty) {
      await Share.shareXFiles(files.map((f) => XFile(f.path)).toList());
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Files moved successfully")));
    }
  }

  // ---------------- RENAME ----------------

  void _handleRename() {
    if (selectedAssets.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select only one image")),
      );
      return;
    }

    final AssetEntity asset = selectedAssets.first;

    final controller = TextEditingController(text: asset.title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rename Image"),

          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter new name"),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            TextButton(
              onPressed: () {
                debugPrint("New name: ${controller.text}");

                Navigator.pop(context);
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
    if (selectedAssets.isEmpty) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Images"),

          content: Text(
            "${selectedAssets.length} images permanently delete ho jayengi",
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final ids = selectedAssets.map((e) => e.id).toList();

        final result = await PhotoManager.editor.deleteWithIds(ids);

        if (result.isNotEmpty) {
          setState(() {
            assets.removeWhere((element) => selectedAssets.contains(element));

            selectedAssets.clear();

            isSelectionMode = false;
          });
        }
      } catch (e) {
        debugPrint("Delete Error: $e");
      }
    }
  }

  // ---------------- SELECTION ----------------

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (selectedAssets.contains(asset)) {
        selectedAssets.remove(asset);

        if (selectedAssets.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        selectedAssets.add(asset);

        isSelectionMode = true;
      }
    });
  }

  // ---------------- GET FILES ----------------

  Future<List<File>> getSelectedFiles() async {
    List<File> files = [];

    for (var asset in selectedAssets) {
      final File? f = await asset.originFile;

      if (f != null) files.add(f);
    }

    return files;
  }

  // ---------------- OPEN IMAGE ----------------

  Future<void> _openImageFile(AssetEntity asset) async {
    final file = await asset.file;

    if (file != null) {
      OpenFile.open(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,

      appBar: AppBar(
        scrolledUnderElevation: 0,

        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    isSelectionMode = false;
                    selectedAssets.clear();
                  });
                },
              )
            : const BackButton(),

        title: Text(
          isSelectionMode
              ? "${selectedAssets.length} Selected"
              : widget.folder.name,
          style: const TextStyle(fontSize: 18),
        ),

        // backgroundColor: Colors.white,
        elevation: 0.5,
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

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8),

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,

                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),

              itemCount: assets.length,

              itemBuilder: (context, index) {
                final asset = assets[index];

                final isSelected = selectedAssets.contains(asset);

                return GestureDetector(
                  onTap: () {
                    if (isSelectionMode) {
                      _toggleSelection(asset);
                    } else {
                      _openImageFile(asset);
                    }
                  },

                  onLongPress: () => _toggleSelection(asset),

                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),

                          child: Container(
                            decoration: BoxDecoration(
                              border: isSelected
                                  ? Border.all(color: Colors.blue, width: 3)
                                  : null,
                            ),

                            child: AssetEntityImage(
                              asset,

                              isOriginal: false,

                              thumbnailSize: const ThumbnailSize.square(250),

                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      if (isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                        ),

                      if (isSelected)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.blue[700],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

      // ---------------- ACTION BAR ----------------
      bottomNavigationBar: isSelectionMode
          ? FileActionBar(
              selectedCount: selectedAssets.length,
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
