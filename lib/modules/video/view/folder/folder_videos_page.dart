import 'dart:io';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../../../file_explorer/view/file_action_bar.dart';

class FolderVideosPage extends StatefulWidget {
  final AssetPathEntity folder;
  const FolderVideosPage({super.key, required this.folder});

  @override
  State<FolderVideosPage> createState() => _FolderVideosPageState();
}

class _FolderVideosPageState extends State<FolderVideosPage> {
  List<AssetEntity> videoAssets = [];
  Set<AssetEntity> selectedVideos = {};
  bool isLoading = true;
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() => isLoading = true);
    try {
      final list = await widget.folder.getAssetListPaged(page: 0, size: 100);
      setState(() {
        videoAssets = list;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching videos: $e");
      setState(() => isLoading = false);
    }
  }

  // --- ACTION BAR FUNCTIONS ---

  Future<void> _handleShare() async {
    final files = await getSelectedFiles();

    if (files.isNotEmpty) {
      await Share.shareXFiles(files.map((f) => XFile(f.path)).toList());
    }
  }

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
    if (selectedVideos.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select only one image")),
      );
      return;
    }

    final AssetEntity asset = selectedVideos.first;

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


  Future<void> _handleDelete() async {
    if (selectedVideos.isEmpty) return;

    // Confirm Dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Videos?"),
        content: Text("${selectedVideos.length} videos permanently delete ho jayenge."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final ids = selectedVideos.map((e) => e.id).toList();
        final List<String> result = await PhotoManager.editor.deleteWithIds(ids);

        if (result.isNotEmpty) {
          setState(() {
            videoAssets.removeWhere((element) => selectedVideos.contains(element));
            selectedVideos.clear();
            isSelectionMode = false;
          });
        }
      } catch (e) {
        debugPrint("Delete Error: $e");
      }
    }
  }

  void _toggleSelection(AssetEntity video) {
    setState(() {
      if (selectedVideos.contains(video)) {
        selectedVideos.remove(video);
        if (selectedVideos.isEmpty) isSelectionMode = false;
      } else {
        selectedVideos.add(video);
        isSelectionMode = true;
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  Future<void> _playVideo(AssetEntity video) async {
    final File? file = await video.file;
    if (file != null) {
      OpenFile.open(file.path);
    }
  }

  Future<List<File>> getSelectedFiles() async {
    List<File> files = [];

    for (var asset in selectedVideos) {
      final File? f = await asset.originFile;

      if (f != null) files.add(f);
    }

    return files;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: isSelectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() {
          isSelectionMode = false;
          selectedVideos.clear();
        }))
            : const BackButton(),
        title: Text(
          isSelectionMode ? "${selectedVideos.length} Selected" : widget.folder.name,
          style: const TextStyle(fontSize: 18),
        ),
        // backgroundColor: Colors.white,
        elevation: 0.5,
        // iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (!isSelectionMode)
            IconButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchPage()));
            }, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : videoAssets.isEmpty
          ? const Center(child: Text("No videos found"))
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: videoAssets.length,
        itemBuilder: (context, index) {
          final video = videoAssets[index];
          final isSelected = selectedVideos.contains(video);

          return GestureDetector(
            onTap: () => isSelectionMode ? _toggleSelection(video) : _playVideo(video),
            onLongPress: () => _toggleSelection(video),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: isSelected ? Border.all(color: Colors.blue, width: 3) : null,
                      ),
                      child: AssetEntityImage(
                        video,
                        isOriginal: false,
                        thumbnailSize: const ThumbnailSize.square(250),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.black12,
                    ),
                    child: isSelectionMode
                        ? null
                        : const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40)),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                    child: Text(_formatDuration(video.duration), style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
                if (isSelected)
                  const Positioned(top: 5, right: 5, child: Icon(Icons.check_circle, color: Colors.blue)),
              ],
            ),
          );
        },
      ),

      // --- INTEGRATING COMMON ACTION BAR ---
      bottomNavigationBar: isSelectionMode
          ? FileActionBar(
        selectedCount: selectedVideos.length,
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