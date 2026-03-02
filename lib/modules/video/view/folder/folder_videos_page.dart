import 'dart:io';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:open_file/open_file.dart';

class FolderVideosPage extends StatefulWidget {
  final AssetPathEntity folder;
  const FolderVideosPage({super.key, required this.folder});

  @override
  State<FolderVideosPage> createState() => _FolderVideosPageState();
}

class _FolderVideosPageState extends State<FolderVideosPage> {
  List<AssetEntity> videoAssets = [];
  Set<AssetEntity> selectedVideos = {}; // Selected videos store karne ke liye
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

  // --- DELETE SELECTED VIDEOS LOGIC ---
  Future<void> _deleteSelectedVideos() async {
    if (selectedVideos.isEmpty) return;

    try {
      final ids = selectedVideos.map((e) => e.id).toList();
      // Android 11+ mein system popup aayega
      final List<String> result = await PhotoManager.editor.deleteWithIds(ids);

      if (result.isNotEmpty) {
        setState(() {
          videoAssets.removeWhere((element) => selectedVideos.contains(element));
          selectedVideos.clear();
          isSelectionMode = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Selected videos deleted successfully")),
          );
        }
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          isSelectionMode ? "${selectedVideos.length} Selected" : widget.folder.name,
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              onPressed: _deleteSelectedVideos, // Right side delete option
            ),

          IconButton(onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          }, icon: const Icon(Icons.search, )),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, )),
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
            onTap: () {
              if (isSelectionMode) {
                _toggleSelection(video);
              } else {
                _playVideo(video);
              }
            },
            onLongPress: () => _toggleSelection(video),
            child: Stack(
              children: [
                // Thumbnail
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
                        video,
                        isOriginal: false,
                        thumbnailSize: const ThumbnailSize.square(250),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Overlay & Play Icon
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? Colors.black26 : Colors.black12,
                    ),
                    child: const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                    ),
                  ),
                ),
                // Duration Badge
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatDuration(video.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Checkmark for selection
                if (isSelected)
                  const Positioned(
                    top: 5,
                    right: 5,
                    child: Icon(Icons.check_circle, color: Colors.blue),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}